//
//  Recording.swift
//  Funnel
//
//  Created by Claude on 6/17/25.
//

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
    var bulletSummary: [String]?
    var diagramTitle: String?
    var diagramDescription: String?
    var diagramContent: String?

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
