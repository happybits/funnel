
import Foundation

// MARK: - Response Models

struct ErrorResponse: Codable {
    let error: String
    let details: String?
}

// MARK: - Combined Response Model

struct ProcessedRecording: Codable {
    let transcript: String
    let lightlyEditedTranscript: String
    let duration: Double
    let bulletSummary: [String]
    let diagram: DiagramData

    struct DiagramData: Codable {
        let title: String
        let description: String
        let content: String
    }
}

// MARK: - API Error

enum APIError: LocalizedError {
    case invalidURL
    case noData
    case decodingError(String)
    case serverError(String, details: String?)
    case networkError(String)
    case uploadFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .noData:
            return "No data received from server"
        case let .decodingError(message):
            return "Failed to decode response: \(message)"
        case let .serverError(error, details):
            if let details = details {
                return "\(error): \(details)"
            }
            return error
        case let .networkError(message):
            return "Network error: \(message)"
        case let .uploadFailed(message):
            return "Upload failed: \(message)"
        }
    }
}
