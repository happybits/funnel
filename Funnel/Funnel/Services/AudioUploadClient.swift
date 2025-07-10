import AVFoundation
import Foundation

/// Client for streaming audio to our Deno server (which then forwards to Deepgram API)
class AudioUploadClient {
    private let serverBaseURL: String
    private var webSocketTask: URLSessionWebSocketTask?
    private var recordingId: String?
    private var metadataReceived = false

    // Callbacks for UI updates
    var onAudioLevel: ((Float) -> Void)?
    var onStatusUpdate: ((String) -> Void)?
    var onError: ((AudioUploadError) -> Void)?

    enum AudioUploadError: LocalizedError {
        case invalidServerURL
        case noRecordingId
        case webSocketError(String)
        case streamingError(String)
        case finalizeError(String)
        case microphonePermissionDenied
        case recordingTooShort(minimumDuration: TimeInterval)
        case connectionFailed(String)

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
            case .microphonePermissionDenied:
                return "Microphone permission denied"
            case let .recordingTooShort(minimumDuration):
                return "Recording too short (minimum \(minimumDuration)s)"
            case let .connectionFailed(message):
                return "Connection failed: \(message)"
            }
        }
    }

    init(serverBaseURL: String) {
        self.serverBaseURL = serverBaseURL
        print("AudioUploadClient: Initialized with server URL: \(self.serverBaseURL)")
    }

    /// Get the current recording ID
    var currentRecordingId: String? {
        return recordingId
    }

    /// Start a new recording session and stream audio data
    /// - Parameters:
    ///   - sampleRate: The sample rate of the audio data being provided
    ///   - audioDataProvider: Async closure that provides audio chunks
    /// - Returns: The processed recording with transcript, summary, and diagram
    func streamRecording(sampleRate: Double, audioDataProvider: @escaping () async throws -> Data?) async throws -> ProcessedRecording {
        // Reset state
        metadataReceived = false

        // Generate new recording ID
        recordingId = UUID().uuidString
        guard let recordingId = recordingId else {
            throw AudioUploadError.noRecordingId
        }

        onStatusUpdate?("Connecting...")

        // Create WebSocket URL
        let wsURLString = serverBaseURL.replacingOccurrences(of: "http://", with: "ws://")
            .replacingOccurrences(of: "https://", with: "wss://")
        guard let wsURL = URL(string: "\(wsURLString)/api/recordings/\(recordingId)/stream") else {
            throw AudioUploadError.invalidServerURL
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
            "sampleRate": Int(sampleRate),
            "channels": 1,
        ]
        let configData = try JSONSerialization.data(withJSONObject: config)
        let configString = String(data: configData, encoding: .utf8)!

        try await webSocketTask?.send(.string(configString))

        onStatusUpdate?("Recording...")

        try await Task.sleep(for: .milliseconds(100))

        // Stream audio data
        while let chunk = try await audioDataProvider() {
            guard !chunk.isEmpty else { break }

            // Calculate audio level from PCM data
            if let audioLevel = calculateAudioLevel(from: chunk) {
                onAudioLevel?(audioLevel)
            }

            try await webSocketTask?.send(.data(chunk))
            try await Task.sleep(for: .milliseconds(100))
        }

        onStatusUpdate?("Processing...")

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
            throw AudioUploadError.invalidServerURL
        }

        var request = URLRequest(url: finalizeURL)
        request.httpMethod = "POST"

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AudioUploadError.finalizeError("Invalid response type")
        }

        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw AudioUploadError.finalizeError("Status \(httpResponse.statusCode): \(errorMessage)")
        }

        do {
            return try JSONDecoder().decode(ProcessedRecording.self, from: data)
        } catch {
            throw AudioUploadError.finalizeError("Failed to decode response: \(error)")
        }
    }

    /// Upload a complete audio file to the server
    /// - Parameter audioFileURL: URL of the audio file to upload
    /// - Returns: The processed recording with transcript, summary, and diagram
    func uploadFile(audioFileURL: URL) async throws -> ProcessedRecording {
        onStatusUpdate?("Uploading...")
        
        guard let uploadURL = URL(string: "\(serverBaseURL)/api/new-recording") else {
            throw AudioUploadError.invalidServerURL
        }
        
        // Create multipart form data
        var request = URLRequest(url: uploadURL)
        request.httpMethod = "POST"
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        // Read audio file
        let audioData = try Data(contentsOf: audioFileURL)
        
        // Create multipart body
        var body = Data()
        
        // Add audio file part
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"audio\"; filename=\"\(audioFileURL.lastPathComponent)\"\r\n".data(using: .utf8)!)
        
        // Determine content type based on file extension
        let contentType = mimeType(for: audioFileURL.pathExtension)
        body.append("Content-Type: \(contentType)\r\n\r\n".data(using: .utf8)!)
        body.append(audioData)
        body.append("\r\n".data(using: .utf8)!)
        
        // Close boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        onStatusUpdate?("Processing...")
        
        // Make request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AudioUploadError.finalizeError("Invalid response type")
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw AudioUploadError.finalizeError("Status \(httpResponse.statusCode): \(errorMessage)")
        }
        
        do {
            return try JSONDecoder().decode(ProcessedRecording.self, from: data)
        } catch {
            throw AudioUploadError.finalizeError("Failed to decode response: \(error)")
        }
    }
    
    /// Determine MIME type based on file extension
    private func mimeType(for pathExtension: String) -> String {
        switch pathExtension.lowercased() {
        case "mp3":
            return "audio/mpeg"
        case "mp4":
            return "audio/mp4"
        case "wav":
            return "audio/wav"
        case "m4a":
            return "audio/m4a"
        default:
            return "audio/mpeg" // Default to mp3
        }
    }
    
    /// Calculate audio level from PCM16 data
    private func calculateAudioLevel(from data: Data) -> Float? {
        let int16Array = data.withUnsafeBytes { bytes in
            bytes.bindMemory(to: Int16.self)
        }

        guard !int16Array.isEmpty else { return nil }

        // Calculate RMS (Root Mean Square)
        let sum = int16Array.reduce(Float(0)) { result, sample in
            let floatSample = Float(sample) / Float(Int16.max)
            return result + (floatSample * floatSample)
        }

        let rms = sqrt(sum / Float(int16Array.count))

        // Convert to dB
        let avgPower = 20 * log10(max(0.00001, rms))

        // Normalize to 0-1 range
        let minDb: Float = -50
        let maxDb: Float = -10
        let normalizedLevel = (avgPower - minDb) / (maxDb - minDb)
        let clampedLevel = max(0, min(1, normalizedLevel))

        // Apply power curve for better visual response
        return pow(clampedLevel, 2.5)
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
