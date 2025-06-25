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

    // Test mode support
    static var isTestMode: Bool {
        ProcessInfo.processInfo.arguments.contains("--ui-testing")
    }

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

        // Test mode - use pre-recorded file
        if Self.isTestMode {
            startTestRecording(audioFilename: audioFilename, completion: completion)
            return
        }

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

    func stopRecording() {
        if Self.isTestMode {
            // In test mode, just stop the timers and call completion
            timer?.invalidate()
            levelTimer?.invalidate()
            isRecording = false
            audioLevel = 0

            // Simulate successful recording completion
            if let url = currentRecordingURL {
                print("AudioRecorderManager: Test recording finished, file at: \(url.path)")
                recordingCompletion?(.success(url))
            }
            recordingCompletion = nil
            currentRecordingURL = nil
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

    // MARK: - Test Mode Support

    private func startTestRecording(audioFilename: URL, completion: @escaping (Result<URL, Error>) -> Void) {
        print("AudioRecorderManager: Starting test mode recording")

        // Copy test audio file to the recording location
        if let testAudioURL = Bundle.main.url(forResource: "sample-audio-recording", withExtension: "m4a") {
            do {
                try FileManager.default.copyItem(at: testAudioURL, to: audioFilename)
                print("AudioRecorderManager: Test audio file copied to: \(audioFilename.path)")

                // Simulate recording
                isRecording = true
                recordingTime = 0

                // Simulate recording duration (test audio is about 5 seconds)
                timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                    guard let self = self else { return }
                    self.recordingTime += 0.1

                    // Simulate varying audio levels
                    let baseLevel: Float = 0.3
                    let variation: Float = 0.2
                    let randomVariation = Float.random(in: -variation ... variation)
                    self.audioLevel = max(0, min(1, baseLevel + randomVariation))
                }

                completion(.success(audioFilename))
            } catch {
                print("AudioRecorderManager: Failed to copy test audio file: \(error)")
                completion(.failure(error))
                recordingCompletion = nil
            }
        } else {
            completion(.failure(FunnelError.recordingFailed(reason: "Test audio file not found")))
            recordingCompletion = nil
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
