import XCTest
@testable import FunnelAI

final class TestStreamingEndpoint: XCTestCase {
    let serverURL = "ws://localhost:9000/api/stream-recording-ws"
    var webSocketTask: URLSessionWebSocketTask?
    
    override func tearDown() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        super.tearDown()
    }
    
    func testStreamingReturnsAllRequiredData() async throws {
        let expectation = XCTestExpectation(description: "Receive complete response from streaming")
        var receivedResponse: ProcessedRecording?
        
        let session = URLSession(configuration: .default)
        webSocketTask = session.webSocketTask(with: URL(string: serverURL)!)
        webSocketTask?.resume()
        
        // Send configuration
        let config = StreamConfig(sampleRate: 16000, encoding: "linear16", channels: 1)
        let configData = try JSONEncoder().encode(config)
        let configMessage = URLSessionWebSocketTask.Message.string(String(data: configData, encoding: .utf8)!)
        try await webSocketTask?.send(configMessage)
        
        // Load test audio and simulate streaming
        let audioURL = Bundle(for: type(of: self)).url(forResource: "test_audio", withExtension: "m4a")!
        let audioData = try Data(contentsOf: audioURL)
        
        // Stream in chunks
        let chunkSize = 4096
        for offset in stride(from: 0, to: audioData.count, by: chunkSize) {
            let endIndex = min(offset + chunkSize, audioData.count)
            let chunk = audioData[offset..<endIndex]
            let message = URLSessionWebSocketTask.Message.data(chunk)
            try await webSocketTask?.send(message)
            
            // Simulate real-time streaming delay
            try await Task.sleep(nanoseconds: 50_000_000) // 50ms
        }
        
        // Send end signal
        let endMessage = URLSessionWebSocketTask.Message.string("END_OF_STREAM")
        try await webSocketTask?.send(endMessage)
        
        // Receive messages
        Task {
            while true {
                do {
                    let message = try await webSocketTask?.receive()
                    switch message {
                    case .string(let text):
                        if let data = text.data(using: .utf8),
                           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                            
                            // Check if this is the final response
                            if json["transcript"] != nil && json["bulletSummary"] != nil {
                                let decoder = JSONDecoder()
                                receivedResponse = try decoder.decode(ProcessedRecording.self, from: data)
                                expectation.fulfill()
                                break
                            }
                        }
                    case .data(_):
                        continue
                    case .none:
                        break
                    @unknown default:
                        break
                    }
                } catch {
                    break
                }
            }
        }
        
        await fulfillment(of: [expectation], timeout: 30.0)
        
        // Verify response
        XCTAssertNotNil(receivedResponse, "Should receive a complete response")
        guard let response = receivedResponse else { return }
        
        // Verify all required fields
        XCTAssertFalse(response.transcript.isEmpty, "Transcript should not be empty")
        XCTAssertFalse(response.lightlyEditedTranscript.isEmpty, "Lightly edited transcript should not be empty")
        XCTAssertGreaterThan(response.duration, 0, "Duration should be positive")
        XCTAssertFalse(response.bulletSummary.isEmpty, "Bullet summary should not be empty")
        XCTAssertFalse(response.diagram.title.isEmpty, "Diagram title should not be empty")
        XCTAssertFalse(response.diagram.description.isEmpty, "Diagram description should not be empty")
        XCTAssertFalse(response.diagram.content.isEmpty, "Diagram content should not be empty")
        XCTAssertFalse(response.thoughtProvokingQuestions.isEmpty, "Should have thought-provoking questions")
        
        // Verify data quality
        XCTAssertTrue(response.bulletSummary.count >= 3 && response.bulletSummary.count <= 6,
                      "Should have 3-6 bullet points")
        XCTAssertTrue(response.thoughtProvokingQuestions.count >= 3,
                      "Should have at least 3 questions")
    }
    
    func testStreamingHandlesConnectionErrors() async throws {
        let badURL = "ws://localhost:9999/api/stream-recording-ws" // Wrong port
        let session = URLSession(configuration: .default)
        let badTask = session.webSocketTask(with: URL(string: badURL)!)
        badTask.resume()
        
        do {
            try await badTask.send(.string("test"))
            XCTFail("Should fail to connect")
        } catch {
            // Expected error
            XCTAssertNotNil(error, "Should receive connection error")
        }
    }
}

private struct StreamConfig: Codable {
    let sampleRate: Int
    let encoding: String
    let channels: Int
}