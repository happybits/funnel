
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
    
    // MARK: - Live Streaming
    
    /// Finalize a live-streamed recording
    func finalizeRecording(recordingId: String) async throws -> ProcessedRecording {
        print("FunnelAPIService: Finalizing recording with ID: \(recordingId)")
        let result: ProcessedRecording = try await apiClient.request(
            "/api/recordings/\(recordingId)/done",
            method: "POST"
        )
        print("FunnelAPIService: Finalize endpoint returned successfully")
        return result
    }
}
