//
//  FunnelAPIService.swift
//  Funnel
//
//  Created by Claude on 6/17/25.
//

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
}
