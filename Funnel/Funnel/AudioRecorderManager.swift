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

    func stopRecording() {
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
