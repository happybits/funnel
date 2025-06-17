//
//  AudioRecorderManager.swift
//  Funnel
//
//  Created by Claude on 6/16/25.
//

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
            try audioSession.setCategory(.playAndRecord, mode: .default)
            try audioSession.setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
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
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.record()

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
        } catch {
            print("Could not start recording: \(error)")
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
            print("Recording finished successfully")
            if let url = currentRecordingURL {
                recordingCompletion?(.success(url))
            }
        } else {
            recordingCompletion?(.failure(NSError(domain: "AudioRecorder", code: -1, userInfo: [NSLocalizedDescriptionKey: "Recording failed"])))
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
