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
    private var recordingCompletion: ((Result<ProcessedRecording, Error>) -> Void)?

    // Live streaming properties
    private var audioEngine = AVAudioEngine()
    private let deepgramClient = DeepgramClient(serverBaseURL: APIClient.shared.baseURL)
    private(set) var recordingId: String?
    private(set) var isLiveStreaming = false
    private var audioDataContinuation: AsyncStream<Data?>.Continuation?

    // Audio file writing properties
    private var audioFile: AVAudioFile?
    private(set) var audioFileURL: URL?

    // Dependency injection for testing
    private let audioSource: AudioSourceProtocol

    init(audioSource: AudioSourceProtocol? = nil) {
        self.audioSource = audioSource ?? MicrophoneAudioSource()
        super.init()

        // Skip audio session setup in test environment
        let isTestEnvironment = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
        if !isTestEnvironment {
            setupAudioSession()
        }
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

    func startRecording(completion: @escaping (Result<ProcessedRecording, Error>) -> Void) {
        print("AudioRecorderManager: startRecording called")
        
        recordingCompletion = completion
        startLiveStreaming()
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

    func startLiveStreaming() {
        print("AudioRecorderManager: Starting live streaming")

        isLiveStreaming = true
        
        // Create audio file for fallback
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        audioFileURL = documentsPath.appendingPathComponent("recording-\(UUID().uuidString).m4a")
        currentRecordingURL = audioFileURL // Store for compatibility

        // Setup DeepgramClient callbacks
        deepgramClient.onAudioLevel = { [weak self] level in
            DispatchQueue.main.async {
                self?.audioLevel = level
            }
        }
        
        deepgramClient.onStatusUpdate = { [weak self] status in
            print("AudioRecorderManager: DeepgramClient status: \(status)")
        }
        
        deepgramClient.onError = { [weak self] error in
            self?.recordingCompletion?(.failure(error))
            self?.recordingCompletion = nil
        }

        // Start audio engine
        startAudioEngine()
    }


    private func startAudioEngine() {
        // Create audio data stream
        let (stream, continuation) = AsyncStream.makeStream(of: Data?.self)
        audioDataContinuation = continuation
        
        // Start streaming with DeepgramClient
        Task {
            do {
                var isFirstChunk = true
                let processedRecording = try await deepgramClient.streamRecording {
                    // Update recordingId only once after DeepgramClient creates it
                    if isFirstChunk {
                        await MainActor.run {
                            self.recordingId = self.deepgramClient.currentRecordingId
                            print("AudioRecorderManager: Recording ID set to: \(self.recordingId ?? "nil")")
                        }
                        isFirstChunk = false
                    }
                    
                    // This will be called repeatedly to get audio chunks
                    for await data in stream {
                        return data
                    }
                    return nil
                }
                
                // Recording completed successfully
                await MainActor.run {
                    self.recordingCompletion?(.success(processedRecording))
                    self.recordingCompletion = nil
                }
            } catch {
                await MainActor.run {
                    self.recordingCompletion?(.failure(error))
                    self.recordingCompletion = nil
                }
            }
        }
        
        do {
            // Get the audio source node
            let sourceNode = try audioSource.attachToEngine(audioEngine)
            let inputFormat = audioSource.outputFormat

            // Create output format - PCM 16-bit as recommended by Deepgram
            guard let outputFormat = AVAudioFormat(
                commonFormat: .pcmFormatInt16,
                sampleRate: inputFormat.sampleRate, // Use device's native sample rate
                channels: 1,
                interleaved: true
            ) else {
                throw FunnelError.recordingFailed(reason: "Failed to create audio format")
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
                sourceNode.installTap(onBus: 0, bufferSize: 1024, format: inputFormat) { [weak self] buffer, _ in
                    self?.writeAudioBufferToFile(buffer)
                }
            }

            // Connect nodes
            audioEngine.connect(sourceNode, to: converterNode, format: inputFormat)
            audioEngine.connect(converterNode, to: sinkNode, format: outputFormat)

            // Prepare and start engine
            audioEngine.prepare()

            try AVAudioSession.sharedInstance().setCategory(.record)
            try audioEngine.start()

            // Start the audio source (e.g., start file playback)
            try audioSource.startPlayback()

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
        } catch {
            print("AudioRecorderManager: Failed to start audio engine: \(error)")
            recordingCompletion?(.failure(error))
            recordingCompletion = nil
        }
    }

    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        // Convert buffer to Data
        let data = toData(buffer: buffer)
        
        // Send data through the continuation
        if let data = data {
            audioDataContinuation?.yield(data)
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

        // Signal end of audio stream
        audioDataContinuation?.finish()
        audioDataContinuation = nil

        // Stop audio source
        audioSource.stopPlayback()

        // Stop audio engine
        audioEngine.stop()
        // Remove tap from all attached nodes
        for node in audioEngine.attachedNodes {
            node.removeTap(onBus: 0)
        }

        // Stop timers
        timer?.invalidate()
        levelTimer?.invalidate()

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
    }
}


extension AudioRecorderManager: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_: AVAudioRecorder, successfully flag: Bool) {
        if flag {
            print("AudioRecorderManager: Recording finished successfully")
            // For non-streaming recordings, we would need to upload the file
            // This delegate is not used in streaming mode
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
