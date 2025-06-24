import Foundation
import SwiftData
import SwiftUI
import Combine

@MainActor
class RecordingManager: ObservableObject {
    @Published var isProcessing = false
    @Published var processingStatus = ""
    @Published var processingError: Error?
    @Published var presentedRecording: Recording?
    @Published var liveTranscript = ""
    @Published var isLiveTranscribing = false

    private let apiService = FunnelAPIService.shared
    private let liveTranscriptionService = LiveTranscriptionService()

    func processRecording(audioURL: URL, duration: TimeInterval, modelContext: ModelContext) async {
        isProcessing = true
        processingError = nil

        let recording = Recording(
            audioFileName: audioURL.lastPathComponent,
            duration: duration
        )

        modelContext.insert(recording)

        do {
            try modelContext.save()
            await processRecordingSteps(recording: recording, modelContext: modelContext)
        } catch {
            processingError = error
            isProcessing = false
        }
    }
    
    func processRecordingWithTranscript(audioURL: URL, duration: TimeInterval, transcript: String, modelContext: ModelContext) async {
        isProcessing = true
        processingError = nil

        let recording = Recording(
            audioFileName: audioURL.lastPathComponent,
            duration: duration
        )
        
        // Pre-populate the transcript
        recording.transcript = transcript

        modelContext.insert(recording)

        do {
            try modelContext.save()
            await processRecordingStepsWithTranscript(recording: recording, transcript: transcript, modelContext: modelContext)
        } catch {
            processingError = error
            isProcessing = false
        }
    }

    private func processRecordingSteps(recording: Recording, modelContext: ModelContext) async {
        do {
            recording.processingStatus = .uploading
            processingStatus = "Uploading audio..."
            try? modelContext.save()

            recording.processingStatus = .transcribing
            processingStatus = "Processing audio..."
            try? modelContext.save()

            let processedData = try await apiService.processAudio(fileURL: recording.audioFileURL)

            recording.transcript = processedData.transcript
            recording.duration = processedData.duration
            recording.bulletSummary = processedData.bulletSummary
            recording.diagramTitle = processedData.diagram.title
            recording.diagramDescription = processedData.diagram.description
            recording.diagramContent = processedData.diagram.content

            recording.processingStatus = .completed
            processingStatus = "Processing complete!"

            if let firstBullet = recording.bulletSummary?.first {
                recording.title = String(firstBullet.prefix(50))
            }

            try modelContext.save()

            isProcessing = false
            presentedRecording = recording

        } catch {
            recording.processingStatus = .failed
            recording.errorMessage = error.localizedDescription
            processingError = error
            processingStatus = "Processing failed"
            isProcessing = false

            try? modelContext.save()
        }
    }
    
    private func processRecordingStepsWithTranscript(recording: Recording, transcript: String, modelContext: ModelContext) async {
        do {
            recording.processingStatus = .uploading
            processingStatus = "Processing audio..."
            try? modelContext.save()

            // Skip transcription since we already have it
            recording.processingStatus = .summarizing
            processingStatus = "Generating summary..."
            try? modelContext.save()

            let processedData = try await apiService.processAudioWithTranscript(
                fileURL: recording.audioFileURL,
                transcript: transcript,
                duration: recording.duration
            )

            recording.transcript = processedData.transcript
            recording.duration = processedData.duration
            recording.bulletSummary = processedData.bulletSummary
            recording.diagramTitle = processedData.diagram.title
            recording.diagramDescription = processedData.diagram.description
            recording.diagramContent = processedData.diagram.content

            recording.processingStatus = .completed
            processingStatus = "Processing complete!"

            if let firstBullet = recording.bulletSummary?.first {
                recording.title = String(firstBullet.prefix(50))
            }

            try modelContext.save()

            isProcessing = false
            presentedRecording = recording

        } catch {
            recording.processingStatus = .failed
            recording.errorMessage = error.localizedDescription
            processingError = error
            processingStatus = "Processing failed"
            isProcessing = false

            try? modelContext.save()
        }
    }

    func retryProcessing(recording: Recording, modelContext: ModelContext) async {
        guard recording.processingStatus == .failed else { return }

        recording.processingStatus = .unprocessed
        recording.errorMessage = nil
        try? modelContext.save()

        isProcessing = true
        await processRecordingSteps(recording: recording, modelContext: modelContext)
    }

    func dismissError() {
        processingError = nil
        isProcessing = false
    }
    
    // MARK: - Live Transcription
    
    func startLiveTranscription(audioRecorder: AudioRecorderManager) {
        isLiveTranscribing = true
        liveTranscript = ""
        
        // Reset the full transcript
        liveTranscriptionService.fullTranscript = ""
        
        // Connect to WebSocket
        liveTranscriptionService.connect()
        
        // Set up audio streaming
        audioRecorder.audioDataCallback = { [weak self] audioData in
            self?.liveTranscriptionService.sendAudioData(audioData)
        }
        
        // Observe transcript changes
        setupTranscriptionObservers()
    }
    
    func getFullTranscript() -> String {
        return liveTranscriptionService.fullTranscript
    }
    
    func stopLiveTranscription() {
        isLiveTranscribing = false
        liveTranscriptionService.disconnect()
    }
    
    private func setupTranscriptionObservers() {
        // Observe current transcript updates
        liveTranscriptionService.$currentTranscript
            .receive(on: DispatchQueue.main)
            .sink { [weak self] transcript in
                if !transcript.isEmpty {
                    self?.liveTranscript = transcript
                }
            }
            .store(in: &cancellables)
        
        // Observe full transcript for final recording
        liveTranscriptionService.$fullTranscript
            .receive(on: DispatchQueue.main)
            .sink { [weak self] fullTranscript in
                // This will contain the complete transcription
                // Can be used to pre-populate the recording transcript
            }
            .store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
}
