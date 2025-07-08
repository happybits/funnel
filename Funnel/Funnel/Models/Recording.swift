
import Foundation
import SwiftData

enum ProcessingStatus: String, Codable {
    case unprocessed
    case uploading
    case transcribing
    case summarizing
    case completed
    case failed
}

@Model
final class Recording {
    var id: UUID
    var timestamp: Date
    var duration: TimeInterval
    var title: String

    // Audio file stored locally
    var audioFileName: String

    // Processing status
    var processingStatus: ProcessingStatus
    var errorMessage: String?

    // Processed content
    var transcript: String?
    var lightlyEditedTranscript: String?
    var bulletSummary: [String]?
    var diagramTitle: String?
    var diagramDescription: String?
    var diagramContent: String?

    // Computed property for diagram
    var diagram: Diagram? {
        guard let title = diagramTitle,
              let description = diagramDescription,
              let content = diagramContent
        else {
            return nil
        }
        return Diagram(title: title, description: description, content: content)
    }

    struct Diagram {
        let title: String
        let description: String
        let content: String
    }

    init(audioFileName: String, duration: TimeInterval) {
        id = UUID()
        timestamp = Date()
        self.duration = duration
        title = "Voice Recording"
        self.audioFileName = audioFileName
        processingStatus = .unprocessed
    }

    var audioFileURL: URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent(audioFileName)
    }
}
