//
//  CurrentRecordingProvider.swift
//  Funnel
//
//  Created by Claude on 6/17/25.
//

import AVFoundation
import Combine
import Foundation
import SwiftUI

class CurrentRecordingProvider: ObservableObject {
    @Published var isRecording = false
    @Published var audioRecorder = AudioRecorderManager()
    @Published var recordingTime: TimeInterval = 0
    @Published var audioLevel: Float = 0
    @Published var waveformValues: [CGFloat] = []
    
    private var timer: Timer?
    private var levelTimer: Timer?
    private var recordingCompletion: ((Result<URL, Error>) -> Void)?
    
    func startRecording(completion: @escaping (Result<URL, Error>) -> Void) {
        print("CurrentRecordingProvider: startRecording called")
        recordingCompletion = completion
        
        audioRecorder.requestMicrophonePermission { [weak self] granted in
            print("CurrentRecordingProvider: Microphone permission granted: \(granted)")
            guard let self = self, granted else {
                completion(.failure(NSError(domain: "AudioRecorder", code: -2, userInfo: [NSLocalizedDescriptionKey: "Microphone permission denied"])))
                return
            }
            
            self.audioRecorder.startRecording { result in
                print("CurrentRecordingProvider: Recording result: \(result)")
                switch result {
                case .success:
                    // Recording started successfully
                    DispatchQueue.main.async {
                        self.isRecording = true
                        self.recordingTime = 0
                        self.waveformValues = []
                        self.startTimers()
                        print("CurrentRecordingProvider: Recording state updated, isRecording: \(self.isRecording)")
                    }
                case let .failure(error):
                    print("CurrentRecordingProvider: Recording failed: \(error)")
                    completion(.failure(error))
                }
            }
        }
    }
    
    func stopRecording() {
        audioRecorder.stopRecording()
        timer?.invalidate()
        levelTimer?.invalidate()
        isRecording = false
        audioLevel = 0
        
        // Note: The actual completion is handled in the view after stop is called
        // This ensures the audio file is properly finalized
    }
    
    private func startTimers() {
        // Timer for recording duration
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.recordingTime = self?.audioRecorder.recordingTime ?? 0
        }
        
        // Timer for waveform animation
        levelTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            withAnimation(.linear(duration: 0.05)) {
                let normalizedLevel = CGFloat(self.audioRecorder.audioLevel)
                let visualLevel = max(0.05, normalizedLevel)
                self.waveformValues.append(visualLevel)
                
                if self.waveformValues.count > 50 {
                    self.waveformValues.removeFirst()
                }
            }
        }
    }
}