
import Foundation

class FunnelAPIService {
    static let shared = FunnelAPIService()
    private let apiClient = APIClient.shared

    private init() {}

    // MARK: - New Recording

    /// Process audio file through the new-recording endpoint
    func processAudio(fileURL: URL) async throws -> ProcessedRecording {
        return try await apiClient.uploadMultipart(
            "/api/new-recording",
            fileURL: fileURL,
            fieldName: "audio"
        )
    }
    
    /// Process audio file with pre-transcribed text (from live transcription)
    func processAudioWithTranscript(fileURL: URL, transcript: String, duration: TimeInterval) async throws -> ProcessedRecording {
        return try await apiClient.uploadMultipart(
            "/api/new-recording",
            fileURL: fileURL,
            fieldName: "audio",
            additionalFields: [
                "transcript": transcript,
                "duration": String(duration)
            ]
        )
    }
}
