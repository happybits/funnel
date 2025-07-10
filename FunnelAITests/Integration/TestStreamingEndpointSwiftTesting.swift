/**
 * Integration tests for the WebSocket streaming endpoint.
 * These tests require a local development server running.
 * Tests verify that audio streaming and real-time processing work correctly.
 */
import Testing
import Foundation
@testable import FunnelAI

final class TestStreamingEndpointSwiftTesting {
    let serverURL = "\(Constants.API.webSocketScheme)://\(Constants.API.webSocketHost)/api/stream-recording-ws"
    var webSocketTask: URLSessionWebSocketTask?
    
    init() {
        // No specific setup needed
    }
    
    deinit {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
    }
    
    @Test
    func streamingReturnsAllRequiredData() async throws {
        var receivedResponse: ProcessedRecording?
        
        let session = URLSession(configuration: .default)
        let webSocketTask = session.webSocketTask(with: URL(string: serverURL)!)
        webSocketTask.resume()
        
        // Send configuration
        let config = StreamConfig(sampleRate: 16000, encoding: "linear16", channels: 1)
        let configData = try JSONEncoder().encode(config)
        let configMessage = URLSessionWebSocketTask.Message.string(String(data: configData, encoding: .utf8)!)
        try await webSocketTask.send(configMessage)
        
        // Load test audio and simulate streaming
        let audioURL = Bundle(for: TestStreamingEndpointSwiftTesting.self).url(forResource: "sample-recording-mary-had-lamb", withExtension: "m4a")!
        let audioData = try Data(contentsOf: audioURL)
        
        // Stream in chunks
        let chunkSize = 4096
        for offset in stride(from: 0, to: audioData.count, by: chunkSize) {
            let endIndex = min(offset + chunkSize, audioData.count)
            let chunk = audioData[offset..<endIndex]
            let message = URLSessionWebSocketTask.Message.data(chunk)
            try await webSocketTask.send(message)
            
            // Simulate real-time streaming delay
            try await Task.sleep(nanoseconds: 50_000_000) // 50ms
        }
        
        // Send end signal
        let endMessage = URLSessionWebSocketTask.Message.string("END_OF_STREAM")
        try await webSocketTask.send(endMessage)
        
        // Use confirmation to wait for response
        try await confirmation("Receive complete response from streaming", expectedCount: 1) { confirmation in
            Task {
                while true {
                    do {
                        let message = try await webSocketTask.receive()
                        switch message {
                        case .string(let text):
                            if let data = text.data(using: .utf8),
                               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                                
                                // Check if this is the final response
                                if json["transcript"] != nil && json["bulletSummary"] != nil {
                                    let decoder = JSONDecoder()
                                    receivedResponse = try decoder.decode(ProcessedRecording.self, from: data)
                                    confirmation()
                                    break
                                }
                            }
                        case .data(_):
                            continue
                        @unknown default:
                            break
                        }
                    } catch {
                        break
                    }
                }
            }
        }
        
        // Verify response
        let response = try #require(receivedResponse)
        
        // Verify all required fields
        #expect(!response.transcript.isEmpty)
        #expect(!response.lightlyEditedTranscript.isEmpty)
        #expect(response.duration > 0)
        #expect(!response.bulletSummary.isEmpty)
        #expect(!response.diagram.title.isEmpty)
        #expect(!response.diagram.description.isEmpty)
        #expect(!response.diagram.content.isEmpty)
        #expect(!response.thoughtProvokingQuestions.isEmpty)
        
        // Verify data quality
        #expect(response.bulletSummary.count >= 3 && response.bulletSummary.count <= 6)
        #expect(response.thoughtProvokingQuestions.count >= 3)
        
        // Clean up
        webSocketTask.cancel(with: .goingAway, reason: nil)
    }
    
    @Test
    func streamingHandlesConnectionErrors() async throws {
        let badURL = "\(Constants.API.webSocketScheme)://\(Constants.API.localHost):9999/api/stream-recording-ws" // Wrong port
        let session = URLSession(configuration: .default)
        let badTask = session.webSocketTask(with: URL(string: badURL)!)
        badTask.resume()
        
        do {
            try await badTask.send(.string("test"))
            Issue.record("Should fail to connect")
        } catch {
            // Expected error - error is always non-nil in catch block
            // Just verifying we caught an error
        }
        
        // Clean up
        badTask.cancel(with: .goingAway, reason: nil)
    }
}

private struct StreamConfig: Codable {
    let sampleRate: Int
    let encoding: String
    let channels: Int
}