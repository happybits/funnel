import AVFoundation
import Combine
import Foundation
import SwiftData
import SwiftUI

enum NavigationState: Equatable {
    case recording
    case processing
    case viewing(Recording)
    case cards(Recording)
}

@MainActor
class AppState: ObservableObject {
    // MARK: - Navigation State

    @Published var navigationState: NavigationState = .recording

    // MARK: - Recording State

    @Published var isRecording = false
    @Published var recordingTime: TimeInterval = 0
    @Published var audioLevel: Float = 0
    @Published var waveformValues: [CGFloat] = []

    // MARK: - Processing State

    @Published var isProcessing = false
    @Published var processingStatus: String = ""
    @Published var processingError: Error?

    // MARK: - Dependencies

    private let audioRecorder = AudioRecorderManager()
    private let apiService = FunnelAPIService.shared
    var modelContext: ModelContext

    // MARK: - Private State

    private var recordingTimer: Timer?
    private var levelTimer: Timer?
    private var recordingCompletion: ((Result<URL, Error>) -> Void)?

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Recording Methods

    func startRecording() {
        print("AppState: startRecording called")

        audioRecorder.requestMicrophonePermission { [weak self] granted in
            print("AppState: Microphone permission granted: \(granted)")
            guard let self = self, granted else {
                self?.processingError = NSError(
                    domain: "AudioRecorder",
                    code: -2,
                    userInfo: [NSLocalizedDescriptionKey: "Microphone permission denied"]
                )
                return
            }

            self.audioRecorder.startRecording { result in
                print("AppState: Recording result: \(result)")
                switch result {
                case .success:
                    DispatchQueue.main.async {
                        self.isRecording = true
                        self.recordingTime = 0
                        self.waveformValues = []
                        self.startTimers()
                        print("AppState: Recording state updated, isRecording: \(self.isRecording)")
                    }
                case let .failure(error):
                    print("AppState: Recording failed: \(error)")
                    self.processingError = error
                }
            }
        }
    }

    func stopRecording() {
        print("AppState: stopRecording called")

        let recordingDuration = recordingTime

        // Ensure minimum recording duration
        guard recordingDuration >= 0.5 else {
            print("AppState: Recording too short (\(recordingDuration)s), minimum is 0.5s")
            processingError = NSError(
                domain: "Recording",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Recording too short. Please record for at least 0.5 seconds."]
            )
            return
        }

        audioRecorder.stopRecording()
        recordingTimer?.invalidate()
        levelTimer?.invalidate()
        isRecording = false
        audioLevel = 0

        // Process the recording
        if let audioURL = audioRecorder.currentRecordingURL {
            navigationState = .processing
            Task {
                await processRecording(audioURL: audioURL, duration: recordingDuration)
            }
        }
    }

    // MARK: - Processing Methods

    private func processRecording(audioURL: URL, duration: TimeInterval) async {
        isProcessing = true
        processingError = nil

        // Create and save the recording
        let recording = Recording(
            audioFileName: audioURL.lastPathComponent,
            duration: duration
        )

        modelContext.insert(recording)

        do {
            try modelContext.save()
            await processRecordingSteps(recording: recording)
        } catch {
            processingError = error
            isProcessing = false
        }
    }

    private func processRecordingSteps(recording: Recording) async {
        do {
            // Update status: Uploading
            recording.processingStatus = .uploading
            processingStatus = "Uploading audio..."
            try? modelContext.save()

            print("AppState: Starting upload to API")

            // Process audio through combined endpoint
            recording.processingStatus = .transcribing
            processingStatus = "Processing audio..."
            try? modelContext.save()

            let processedData = try await apiService.processAudio(fileURL: recording.audioFileURL)
            print("AppState: API processing complete")

            // Update recording with all data from combined response
            recording.transcript = processedData.transcript
            recording.duration = processedData.duration
            recording.bulletSummary = processedData.bulletSummary
            recording.diagramTitle = processedData.diagram.title
            recording.diagramDescription = processedData.diagram.description
            recording.diagramContent = processedData.diagram.content

            // Mark as completed
            recording.processingStatus = .completed
            processingStatus = "Processing complete!"

            // Update title based on summary
            if let firstBullet = recording.bulletSummary?.first {
                recording.title = String(firstBullet.prefix(50))
            }

            try modelContext.save()

            // Navigate to cards view
            navigationState = .cards(recording)

        } catch {
            // Handle error
            print("AppState: Processing failed with error: \(error)")
            recording.processingStatus = .failed
            recording.errorMessage = error.localizedDescription
            processingError = error
            processingStatus = "Processing failed"

            try? modelContext.save()
        }

        print("AppState: Setting isProcessing to false")
        isProcessing = false
    }

    // MARK: - Navigation Methods

    func resetToRecording() {
        navigationState = .recording
        processingError = nil
        processingStatus = ""
        
        // Reset recording state to ensure clean state for next recording
        isRecording = false
        recordingTime = 0
        audioLevel = 0
        waveformValues = []
        
        // Clean up any active timers
        recordingTimer?.invalidate()
        recordingTimer = nil
        levelTimer?.invalidate()
        levelTimer = nil
    }

    // MARK: - Retry Methods

    func retryProcessing(recording: Recording) async {
        guard recording.processingStatus == .failed else { return }

        recording.processingStatus = .unprocessed
        recording.errorMessage = nil
        try? modelContext.save()

        navigationState = .processing
        await processRecordingSteps(recording: recording)
    }

    // MARK: - Private Helper Methods

    private func startTimers() {
        // Timer for recording duration
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.recordingTime = self?.audioRecorder.recordingTime ?? 0
            }
        }

        // Timer for waveform animation
        levelTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self = self else { return }

            DispatchQueue.main.async {
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
}
