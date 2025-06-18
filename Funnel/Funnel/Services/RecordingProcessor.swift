
import Foundation
import SwiftData

@MainActor
class RecordingProcessor: ObservableObject {
    @Published var isProcessing = false
    @Published var processingStatus: String = ""
    @Published var processingError: Error?

    private let apiService = FunnelAPIService.shared
    var modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func processRecording(audioURL: URL, duration: TimeInterval) async {
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
        } catch {
            processingError = error
            isProcessing = false
            return
        }

        // Process the recording
        await processRecordingSteps(recording: recording)
    }

    private func processRecordingSteps(recording: Recording) async {
        do {
            // Update status: Uploading
            recording.processingStatus = .uploading
            processingStatus = "Uploading audio..."
            try? modelContext.save()

            print("RecordingProcessor: Starting upload to API")

            // Process audio through combined endpoint
            recording.processingStatus = .transcribing
            processingStatus = "Processing audio..."
            try? modelContext.save()

            let processedData = try await apiService.processAudio(fileURL: recording.audioFileURL)
            print("RecordingProcessor: API processing complete")

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
                // Use first bullet point as title, truncated if necessary
                recording.title = String(firstBullet.prefix(50))
            }

            try modelContext.save()

        } catch {
            // Handle error
            print("RecordingProcessor: Processing failed with error: \(error)")
            recording.processingStatus = .failed
            recording.errorMessage = error.localizedDescription
            processingError = error
            processingStatus = "Processing failed"

            try? modelContext.save()
        }

        print("RecordingProcessor: Setting isProcessing to false")
        isProcessing = false
    }

    // MARK: - Retry Failed Recording

    func retryProcessing(recording: Recording) async {
        guard recording.processingStatus == .failed else { return }

        recording.processingStatus = .unprocessed
        recording.errorMessage = nil
        try? modelContext.save()

        await processRecordingSteps(recording: recording)
    }
}
