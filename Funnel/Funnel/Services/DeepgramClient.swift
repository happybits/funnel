import AVFoundation
import Foundation

/// Client for streaming audio to the server and receiving processed transcripts
class DeepgramClient {
    private let serverBaseURL: String
    private var webSocketTask: URLSessionWebSocketTask?
    private var recordingId: String?
    private var metadataReceived = false
    
    enum DeepgramError: LocalizedError {
        case invalidServerURL
        case noRecordingId
        case webSocketError(String)
        case streamingError(String)
        case finalizeError(String)
        
        var errorDescription: String? {
            switch self {
            case .invalidServerURL:
                return "Invalid server URL"
            case .noRecordingId:
                return "No recording ID available"
            case let .webSocketError(message):
                return "WebSocket error: \(message)"
            case let .streamingError(message):
                return "Streaming error: \(message)"
            case let .finalizeError(message):
                return "Finalize error: \(message)"
            }
        }
    }
    
    init(serverBaseURL: String = "http://localhost:8000") {
        self.serverBaseURL = serverBaseURL
    }
    
    /// Start a new recording session and stream audio data
    /// - Parameters:
    ///   - audioDataProvider: Async closure that provides audio chunks
    /// - Returns: The processed recording with transcript, summary, and diagram
    func streamRecording(audioDataProvider: @escaping () async throws -> Data?) async throws -> ProcessedRecording {
        // Generate new recording ID
        recordingId = UUID().uuidString
        guard let recordingId = recordingId else {
            throw DeepgramError.noRecordingId
        }
        
        // Create WebSocket URL
        let wsURLString = serverBaseURL.replacingOccurrences(of: "http://", with: "ws://")
            .replacingOccurrences(of: "https://", with: "wss://")
        guard let wsURL = URL(string: "\(wsURLString)/api/recordings/\(recordingId)/stream") else {
            throw DeepgramError.invalidServerURL
        }
        
        // Create WebSocket task
        let session = URLSession(configuration: .default)
        webSocketTask = session.webSocketTask(with: wsURL)
        
        // Start receiving messages
        Task {
            await receiveMessages()
        }
        
        // Connect WebSocket
        webSocketTask?.resume()
        
        // Wait a bit for connection
        try await Task.sleep(for: .milliseconds(100))
        
        // Send configuration
        let config: [String: Any] = [
            "type": "config",
            "format": "pcm16",
            "sampleRate": 16000,
            "channels": 1,
        ]
        let configData = try JSONSerialization.data(withJSONObject: config)
        let configString = String(data: configData, encoding: .utf8)!
        
        try await webSocketTask?.send(.string(configString))
        
        try await Task.sleep(for: .milliseconds(100))
        
        // Stream audio data
        while let chunk = try await audioDataProvider() {
            guard !chunk.isEmpty else { break }
            try await webSocketTask?.send(.data(chunk))
            try await Task.sleep(for: .milliseconds(100))
        }
        
        // Finalize recording
        let processedRecording = try await finalizeRecording(recordingId: recordingId)
        
        // Wait for metadata confirmation
        let maxWaitTime = 30000 // 30 seconds
        var waitedTime = 0
        
        while !metadataReceived && waitedTime < maxWaitTime {
            try await Task.sleep(for: .milliseconds(100))
            waitedTime += 100
        }
        
        // Close WebSocket
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil
        
        return processedRecording
    }
    
    /// Stream audio from a file for testing
    func streamAudioFile(at url: URL) async throws -> ProcessedRecording {
        // Load and convert audio to PCM
        let audioFile = try AVAudioFile(forReading: url)
        let pcmData = try audioFile.convertToPCM()
        
        let chunkSize = 16000 // 1 second at 16kHz mono 16-bit
        var offset = 0
        
        return try await streamRecording { [pcmData] in
            guard offset < pcmData.count else { return nil }
            
            let chunkEnd = min(offset + chunkSize, pcmData.count)
            let chunk = pcmData[offset ..< chunkEnd]
            offset = chunkEnd
            
            return chunk
        }
    }
    
    private func receiveMessages() async {
        guard let webSocketTask = webSocketTask else { return }
        
        do {
            while webSocketTask.state == .running {
                let message = try await webSocketTask.receive()
                
                switch message {
                case let .string(text):
                    handleMessage(text)
                case let .data(data):
                    if let text = String(data: data, encoding: .utf8) {
                        handleMessage(text)
                    }
                @unknown default:
                    break
                }
            }
        } catch {
            if webSocketTask.state != .completed {
                print("WebSocket receive error: \(error)")
            }
        }
    }
    
    private func handleMessage(_ message: String) {
        // Parse WebSocket response to check for metadata
        if let data = message.data(using: .utf8),
           let response = try? JSONDecoder().decode(WebSocketResponse.self, from: data),
           response.type == "Metadata"
        {
            metadataReceived = true
        }
    }
    
    private func finalizeRecording(recordingId: String) async throws -> ProcessedRecording {
        guard let finalizeURL = URL(string: "\(serverBaseURL)/api/recordings/\(recordingId)/done") else {
            throw DeepgramError.invalidServerURL
        }
        
        var request = URLRequest(url: finalizeURL)
        request.httpMethod = "POST"
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw DeepgramError.finalizeError("Invalid response type")
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw DeepgramError.finalizeError("Status \(httpResponse.statusCode): \(errorMessage)")
        }
        
        do {
            return try JSONDecoder().decode(ProcessedRecording.self, from: data)
        } catch {
            throw DeepgramError.finalizeError("Failed to decode response: \(error)")
        }
    }
}

// MARK: - Private Models

private struct WebSocketResponse: Codable {
    let type: String
    let message: String?
    let segment: TranscriptSegment?
    let fullTranscript: String?
    let duration: Double?
    let channels: Int?
}

private struct TranscriptSegment: Codable {
    let text: String
    let confidence: Double
    let start: Double
    let end: Double
    let isFinal: Bool
}