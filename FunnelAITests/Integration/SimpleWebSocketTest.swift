import AVFoundation
@testable import FunnelAI
import XCTest

/// Simplified test to debug WebSocket streaming
class SimpleWebSocketTest: XCTestCase {
    func testBasicWebSocketConnection() async throws {
        print("\n🚀 === SIMPLE WEBSOCKET TEST START ===")

        // Check server
        let serverURL = URL(string: Constants.API.localBaseURL)!
        do {
            let (_, response) = try await URLSession.shared.data(for: URLRequest(url: serverURL))
            print("✅ Server responded with status: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
        } catch {
            XCTFail("❌ Server not running: \(error)")
            return
        }

        // Create WebSocket
        let recordingId = UUID().uuidString
        let wsURL = URL(string: "\(Constants.API.webSocketScheme)://\(Constants.API.webSocketHost)/api/recordings/\(recordingId)/stream")!
        print("🔌 Connecting to: \(wsURL)")

        let session = URLSession(configuration: .default)
        let wsTask = session.webSocketTask(with: wsURL)

        // Track messages
        var messages: [String] = []
        let expectation = XCTestExpectation(description: "Receive messages")

        // Start receiving
        Task {
            do {
                while wsTask.state == .running {
                    let message = try await wsTask.receive()
                    switch message {
                    case let .string(text):
                        print("📨 Received: \(text)")
                        messages.append(text)
                        if text.contains("ready") {
                            expectation.fulfill()
                        }
                    case let .data(data):
                        print("📦 Received data: \(data.count) bytes")
                    @unknown default:
                        break
                    }
                }
            } catch {
                print("❌ Receive error: \(error)")
            }
        }

        // Connect
        wsTask.resume()
        print("🔗 WebSocket connected")

        // Send config
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        let config = """
        {"type":"config","format":"pcm16","sampleRate":16000,"channels":1}
        """
        try await wsTask.send(.string(config))
        print("⚙️ Sent config")

        // Wait for ready
        await fulfillment(of: [expectation], timeout: 2.0)

        // Send test audio chunk
        let testData = Data(repeating: 0, count: 1000)
        try await wsTask.send(.data(testData))
        print("🎵 Sent test audio chunk")

        // Wait a bit
        try await Task.sleep(nanoseconds: 500_000_000) // 500ms

        // Close
        wsTask.cancel(with: .normalClosure, reason: nil)
        print("🔚 WebSocket closed")

        print("\n📊 Summary:")
        print("- Messages received: \(messages.count)")
        for (i, msg) in messages.enumerated() {
            print("  [\(i + 1)] \(msg)")
        }

        XCTAssertFalse(messages.isEmpty, "Should receive at least one message")
        print("✅ Test passed!")
    }
}
