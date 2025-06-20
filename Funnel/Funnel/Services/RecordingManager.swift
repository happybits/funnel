import Foundation
import SwiftData
import SwiftUI

@MainActor
class RecordingManager: ObservableObject {
    @Published var isProcessing = false
    @Published var processingStatus = ""
    @Published var processingError: Error?
    @Published var presentedRecording: Recording?

    private let apiService = FunnelAPIService.shared

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
}
