import Foundation
import SwiftData
import SwiftUI

@MainActor
class NewRecordingViewModel: ObservableObject {
    @Published var isProcessing = false
    @Published var processingStatus = ""
    @Published var processingError: Error?
    @Published var presentedRecording: Recording?

    private let apiClient = APIClient.shared

    func processRecording(processedData: ProcessedRecording, modelContext: ModelContext) async {
        isProcessing = true
        processingError = nil
        processingStatus = "Saving recording..."

        // Create a unique filename for the recording
        let audioFileName = "recording-\(UUID().uuidString).m4a"

        let recording = Recording(
            audioFileName: audioFileName,
            duration: processedData.duration
        )

        modelContext.insert(recording)

        do {
            // Save the processed data to the recording
            recording.transcript = processedData.transcript
            recording.lightlyEditedTranscript = processedData.lightlyEditedTranscript
            recording.duration = processedData.duration
            recording.bulletSummary = processedData.bulletSummary
            recording.diagramTitle = processedData.diagram.title
            recording.diagramDescription = processedData.diagram.description
            recording.diagramContent = processedData.diagram.content
            recording.processingStatus = .completed

            if let firstBullet = recording.bulletSummary?.first {
                recording.title = String(firstBullet.prefix(50))
            }

            try modelContext.save()

            processingStatus = "Recording saved!"
            isProcessing = false
            presentedRecording = recording

        } catch {
            recording.processingStatus = .failed
            recording.errorMessage = error.localizedDescription
            processingError = error
            processingStatus = "Save failed"
            isProcessing = false

            try? modelContext.save()
        }
    }

    // Legacy method for file upload flow
    func processRecordingFromFile(audioURL: URL, duration: TimeInterval, modelContext: ModelContext) async {
        isProcessing = true
        processingError = nil

        let recording = Recording(
            audioFileName: audioURL.lastPathComponent,
            duration: duration
        )

        modelContext.insert(recording)

        do {
            try modelContext.save()
            await processRecordingSteps(recording: recording, modelContext: modelContext, recordingId: nil, isLiveStreaming: false)
        } catch {
            processingError = error
            isProcessing = false
        }
    }

    private func processRecordingSteps(recording: Recording, modelContext: ModelContext, recordingId _: String? = nil, isLiveStreaming _: Bool = false) async {
        do {
            // Traditional file upload flow
            recording.processingStatus = .uploading
            processingStatus = "Uploading audio..."
            try? modelContext.save()

            recording.processingStatus = .transcribing
            processingStatus = "Processing audio..."
            try? modelContext.save()

            let processedData = try await apiClient.processAudio(fileURL: recording.audioFileURL)

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
