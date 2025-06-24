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
    
    // Audio streaming properties
    private var audioEngine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?
    var audioDataCallback: ((Data) -> Void)?

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

        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioFilename = documentsPath.appendingPathComponent("\(Date().timeIntervalSince1970).m4a")

        currentRecordingURL = audioFilename
        recordingCompletion = completion

        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
        ]

        do {
            // Ensure audio session is active
            try AVAudioSession.sharedInstance().setActive(true)

            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.prepareToRecord()

            let recordingStarted = audioRecorder?.record() ?? false
            print("AudioRecorderManager: Recording started: \(recordingStarted)")
            print("AudioRecorderManager: Recording to file: \(audioFilename.path)")

            if recordingStarted {
                isRecording = true
                recordingTime = 0

                // Timer for recording duration
                timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                    self.recordingTime += 0.1
                }

                // Timer for audio level monitoring
                levelTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
                    self.updateAudioLevel()
                }

                completion(.success(audioFilename))
            } else {
                print("AudioRecorderManager: Failed to start recording")
                completion(.failure(FunnelError.recordingFailed(reason: "Failed to start recording")))
                recordingCompletion = nil
            }
        } catch {
            print("AudioRecorderManager: Could not start recording: \(error)")
            recordingCompletion?(.failure(error))
            recordingCompletion = nil
        }
    }

    func startRecordingWithStreaming(completion: @escaping (Result<URL, Error>) -> Void) {
        print("AudioRecorderManager: startRecordingWithStreaming called")
        
        // First start regular recording for file storage
        startRecording { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let url):
                // Now set up audio streaming
                self.setupAudioStreaming()
                completion(.success(url))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func setupAudioStreaming() {
        audioEngine = AVAudioEngine()
        guard let audioEngine = audioEngine else { return }
        
        inputNode = audioEngine.inputNode
        guard let inputNode = inputNode else { return }
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        // Install tap on input node to capture audio
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.processAudioBuffer(buffer)
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
            print("AudioRecorderManager: Audio engine started for streaming")
        } catch {
            print("AudioRecorderManager: Failed to start audio engine: \(error)")
        }
    }
    
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData else { return }
        
        let channelDataValue = channelData.pointee
        let channelDataValueArray = Array(UnsafeBufferPointer(start: channelDataValue, count: Int(buffer.frameLength)))
        
        // Convert float audio data to 16-bit PCM
        var pcmData = Data()
        for sample in channelDataValueArray {
            // Convert float (-1.0 to 1.0) to Int16
            let intSample = Int16(max(-32768, min(32767, sample * 32767)))
            withUnsafeBytes(of: intSample) { bytes in
                pcmData.append(contentsOf: bytes)
            }
        }
        
        // Call the callback with audio data
        audioDataCallback?(pcmData)
    }

    func stopRecording() {
        // Stop audio engine if running
        audioEngine?.stop()
        inputNode?.removeTap(onBus: 0)
        audioEngine = nil
        inputNode = nil
        
        // Stop regular recording
        audioRecorder?.stop()
        timer?.invalidate()
        levelTimer?.invalidate()
        isRecording = false
        audioLevel = 0
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
