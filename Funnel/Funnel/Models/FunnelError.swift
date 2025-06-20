import Foundation

enum FunnelError: LocalizedError {
    case microphonePermissionDenied
    case recordingTooShort(minimumDuration: TimeInterval)
    case recordingFailed(reason: String)
    case processingFailed(reason: String)
    case networkError(underlyingError: Error)
    case audioFileNotFound

    var errorDescription: String? {
        switch self {
        case .microphonePermissionDenied:
            return "Microphone permission denied"
        case let .recordingTooShort(minimumDuration):
            return "Recording too short. Please record for at least \(String(format: "%.1f", minimumDuration)) seconds."
        case let .recordingFailed(reason):
            return "Recording failed: \(reason)"
        case let .processingFailed(reason):
            return "Processing failed: \(reason)"
        case let .networkError(error):
            return "Network error: \(error.localizedDescription)"
        case .audioFileNotFound:
            return "Audio file not found"
        }
    }

    var failureReason: String? {
        switch self {
        case .microphonePermissionDenied:
            return "The app needs access to your microphone to record audio."
        case .recordingTooShort:
            return "The recording was too brief to process."
        case .recordingFailed, .processingFailed:
            return nil
        case .networkError:
            return "Please check your internet connection and try again."
        case .audioFileNotFound:
            return "The audio file could not be located."
        }
    }
}
