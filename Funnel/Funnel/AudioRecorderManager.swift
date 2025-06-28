import AVFoundation
import Combine
import Foundation

class AudioRecorderManager: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var recordingTime: TimeInterval = 0
    @Published var audioLevel: Float = 0

    private var audioRecorder: AVAudioRecorder?
    private var timer: Timer?
    private var levelTimer: Timer?
    private(set) var currentRecordingURL: URL?
    private var recordingCompletion: ((Result<URL, Error>) -> Void)?

    // Live streaming properties
    private var audioEngine = AVAudioEngine()
    private var webSocket: URLSessionWebSocketTask?
    private var urlSession: URLSession?
    private(set) var recordingId: String?
    private(set) var isLiveStreaming = false

    // Audio file writing properties
    private var audioFile: AVAudioFile?
    private(set) var audioFileURL: URL?

    override init() {
        super.init()
        setupAudioSession()
    }

    private func setupAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true)
            print("AudioRecorderManager: Audio session setup completed")
        } catch {
            print("AudioRecorderManager: Failed to set up audio session: \(error)")
        }
    }

    func requestMicrophonePermission(completion: @escaping (Bool) -> Void) {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }

    func startRecording(completion: @escaping (Result<URL, Error>) -> Void) {
        print("AudioRecorderManager: startRecording called")

        startLiveStreaming { result in
            switch result {
            case .success:
                // Create a dummy URL for compatibility
                let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let dummyURL = documentsPath.appendingPathComponent("live-stream-\(self.recordingId ?? "unknown").m4a")
                completion(.success(dummyURL))
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    func stopRecording() {
        if isLiveStreaming {
            stopLiveStreaming()
        } else {
            audioRecorder?.stop()
            timer?.invalidate()
            levelTimer?.invalidate()
            isRecording = false
            audioLevel = 0
        }
    }

    private func updateAudioLevel() {
        guard let recorder = audioRecorder, recorder.isRecording else { return }

        recorder.updateMeters()

        // Get the average power for channel 0 (in dB, ranging from -160 to 0)
        let averagePower = recorder.averagePower(forChannel: 0)

        // Adjust sensitivity - lower values = more sensitive
        let minDb: Float = -50
        let maxDb: Float = -10 // Typical speaking voice peaks around -10 to -20 dB

        // Normalize to 0-1 range
        let normalizedLevel = (averagePower - minDb) / (maxDb - minDb)
        let clampedLevel = max(0, min(1, normalizedLevel))

        // Apply power curve for better visual response
        // Higher power = more dramatic difference between quiet and loud
        let curvedLevel = pow(clampedLevel, 2.5)

        DispatchQueue.main.async {
            self.audioLevel = curvedLevel
        }
    }

    // MARK: - Live Streaming Methods

    func startLiveStreaming(completion: @escaping (Result<Void, Error>) -> Void) {
        print("AudioRecorderManager: Starting live streaming")

        recordingId = UUID().uuidString
        isLiveStreaming = true
        print("AudioRecorderManager: Generated recording ID: \(recordingId!)")

        // Create audio file for fallback
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        audioFileURL = documentsPath.appendingPathComponent("recording-\(recordingId!).m4a")
        currentRecordingURL = audioFileURL // Store for compatibility

        // Setup WebSocket connection
        setupWebSocket { [weak self] result in
            switch result {
            case .success:
                self?.startAudioEngine(completion: completion)
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    private func setupWebSocket(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let recordingId = recordingId else {
            completion(.failure(FunnelError.recordingFailed(reason: "No recording ID")))
            return
        }

        // Create URLSession for WebSocket
        let config = URLSessionConfiguration.default
        urlSession = URLSession(configuration: config, delegate: self, delegateQueue: OperationQueue())

        // Use APIClient to construct WebSocket URL
        guard let url = APIClient.shared.webSocketURL(for: "/api/recordings/\(recordingId)/stream") else {
            completion(.failure(FunnelError.recordingFailed(reason: "Invalid WebSocket URL")))
            return
        }

        webSocket = urlSession?.webSocketTask(with: url)
        webSocket?.resume()

        // Listen for messages
        receiveWebSocketMessage()

        // Send audio format configuration after connection
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            guard let self = self else { return }

            // Send configuration message to indicate PCM format
            let config: [String: Any] = [
                "type": "config",
                "format": "pcm16",
                "sampleRate": Int(AVAudioSession.sharedInstance().sampleRate), // Send actual device sample rate
                "channels": 1,
            ]

            if let jsonData = try? JSONSerialization.data(withJSONObject: config),
               let jsonString = String(data: jsonData, encoding: .utf8)
            {
                self.webSocket?.send(.string(jsonString)) { error in
                    if let error = error {
                        print("Failed to send config: \(error)")
                    }
                }
            }

            completion(.success(()))
        }
    }

    private func receiveWebSocketMessage() {
        webSocket?.receive { [weak self] result in
            switch result {
            case let .success(message):
                switch message {
                case let .string(text):
                    print("WebSocket received text: \(text)")
                // Handle transcript responses here if needed
                case let .data(data):
                    print("WebSocket received data: \(data.count) bytes")
                @unknown default:
                    break
                }
                // Continue listening
                self?.receiveWebSocketMessage()
            case let .failure(error):
                print("WebSocket receive error: \(error)")
            }
        }
    }

    private func startAudioEngine(completion: @escaping (Result<Void, Error>) -> Void) {
        let inputNode = audioEngine.inputNode
        let inputFormat = inputNode.inputFormat(forBus: 0)

        // Create output format - PCM 16-bit as recommended by Deepgram
        guard let outputFormat = AVAudioFormat(
            commonFormat: .pcmFormatInt16,
            sampleRate: inputFormat.sampleRate, // Use device's native sample rate
            channels: 1,
            interleaved: true
        ) else {
            completion(.failure(FunnelError.recordingFailed(reason: "Failed to create audio format")))
            return
        }

        // Create audio file for writing
        if let audioFileURL = audioFileURL {
            do {
                // Create AAC format for the file (compressed m4a)
                let settings: [String: Any] = [
                    AVFormatIDKey: kAudioFormatMPEG4AAC,
                    AVSampleRateKey: inputFormat.sampleRate,
                    AVNumberOfChannelsKey: 1,
                    AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
                ]

                audioFile = try AVAudioFile(forWriting: audioFileURL, settings: settings, commonFormat: .pcmFormatFloat32, interleaved: true)
                print("AudioRecorderManager: Created audio file at \(audioFileURL.path)")
            } catch {
                print("AudioRecorderManager: Failed to create audio file: \(error)")
                // Continue without file writing - streaming still works
            }
        }

        // Create converter node
        let converterNode = AVAudioMixerNode()
        let sinkNode = AVAudioMixerNode()

        audioEngine.attach(converterNode)
        audioEngine.attach(sinkNode)

        // Install tap to capture audio for streaming (PCM16)
        converterNode.installTap(onBus: 0, bufferSize: 1024, format: converterNode.outputFormat(forBus: 0)) { [weak self] buffer, _ in
            self?.processAudioBuffer(buffer)
        }

        // Install tap for file writing (use input format for best quality)
        if audioFile != nil {
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: inputFormat) { [weak self] buffer, _ in
                self?.writeAudioBufferToFile(buffer)
            }
        }

        // Connect nodes
        audioEngine.connect(inputNode, to: converterNode, format: inputFormat)
        audioEngine.connect(converterNode, to: sinkNode, format: outputFormat)

        // Prepare and start engine
        audioEngine.prepare()

        do {
            try AVAudioSession.sharedInstance().setCategory(.record)
            try audioEngine.start()

            isRecording = true
            recordingTime = 0

            // Start timers
            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                self.recordingTime += 0.1
            }

            // For live streaming, we'll calculate audio levels from the buffer
            levelTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
                // Audio level will be updated in processAudioBuffer
            }

            print("AudioRecorderManager: Audio engine started successfully")
            completion(.success(()))
        } catch {
            print("AudioRecorderManager: Failed to start audio engine: \(error)")
            completion(.failure(error))
        }
    }

    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.int16ChannelData else { return }

        let channelDataValue = channelData.pointee
        let channelDataValueArray = stride(from: 0, to: Int(buffer.frameLength), by: buffer.stride)
            .map { channelDataValue[$0] }

        // Calculate audio level for visualization
        let rms = sqrt(channelDataValueArray
            .map { Double($0) * Double($0) }
            .reduce(0, +) / Double(channelDataValueArray.count))

        let avgPower = 20 * log10(rms / 32768.0) // Convert to dB
        let minDb: Float = -50
        let maxDb: Float = -10
        let normalizedLevel = Float((avgPower - Double(minDb)) / Double(maxDb - minDb))
        let clampedLevel = max(0, min(1, normalizedLevel))
        let curvedLevel = pow(clampedLevel, 2.5)

        DispatchQueue.main.async { [weak self] in
            self?.audioLevel = curvedLevel
        }

        // Convert buffer to Data for WebSocket
        let data = toData(buffer: buffer)

        // Send data through WebSocket
        if let data = data {
            webSocket?.send(.data(data)) { error in
                if let error = error {
                    print("WebSocket send error: \(error)")
                }
            }
        }
    }

    private func toData(buffer: AVAudioPCMBuffer) -> Data? {
        let audioBuffer = buffer.audioBufferList.pointee.mBuffers
        return Data(bytes: audioBuffer.mData!, count: Int(audioBuffer.mDataByteSize))
    }

    private func writeAudioBufferToFile(_ buffer: AVAudioPCMBuffer) {
        guard let audioFile = audioFile else { return }

        do {
            try audioFile.write(from: buffer)
        } catch {
            print("AudioRecorderManager: Failed to write buffer to file: \(error)")
        }
    }

    private func stopLiveStreaming() {
        print("AudioRecorderManager: Stopping live streaming")
        print("AudioRecorderManager: Recording ID at stop: \(recordingId ?? "nil")")

        // Stop audio engine
        audioEngine.stop()
        // Remove tap from all attached nodes
        for node in audioEngine.attachedNodes {
            node.removeTap(onBus: 0)
        }

        // Stop timers
        timer?.invalidate()
        levelTimer?.invalidate()

        // Close WebSocket
        webSocket?.cancel(with: .goingAway, reason: nil)

        // Close audio file
        audioFile = nil
        if let audioFileURL = audioFileURL {
            print("AudioRecorderManager: Audio file saved at \(audioFileURL.path)")
        }

        // Reset state
        isRecording = false
        isLiveStreaming = false
        audioLevel = 0
        recordingId = nil
        webSocket = nil
        urlSession = nil
    }
}

extension AudioRecorderManager: URLSessionWebSocketDelegate {
    func urlSession(_: URLSession, webSocketTask _: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print("WebSocket connected with protocol: \(String(describing: `protocol`))")
    }

    func urlSession(_: URLSession, webSocketTask _: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason _: Data?) {
        print("WebSocket closed with code: \(closeCode)")
    }
}

extension AudioRecorderManager: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_: AVAudioRecorder, successfully flag: Bool) {
        if flag {
            print("AudioRecorderManager: Recording finished successfully")
            if let url = currentRecordingURL {
                print("AudioRecorderManager: Saved recording to: \(url.path)")
                recordingCompletion?(.success(url))
            }
        } else {
            recordingCompletion?(.failure(FunnelError.recordingFailed(reason: "Recording was interrupted")))
        }
        recordingCompletion = nil
        currentRecordingURL = nil
    }

    func audioRecorderEncodeErrorDidOccur(_: AVAudioRecorder, error: Error?) {
        if let error = error {
            recordingCompletion?(.failure(error))
        }
        recordingCompletion = nil
        currentRecordingURL = nil
    }
}
