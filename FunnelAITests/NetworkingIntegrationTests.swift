/**
 * Integration test that verifies WebSocket streaming functionality against a running development server.
 * This test requires the local server to be running and tests the full WebSocket connection lifecycle
 * including configuration, audio data transmission, and message reception.
 */
import AVFoundation
@testable import FunnelAI
import Testing
import Foundation

/// Basic connectivity and WebSocket lifecycle tests
struct NetworkingIntegrationTests {
    @Test
    func basicWebSocketConnection() async throws {
        print("\n🚀 === SIMPLE WEBSOCKET TEST START ===")

        // Check server
        let serverURL = URL(string: Constants.API.localBaseURL)!
        do {
            let (_, response) = try await URLSession.shared.data(for: URLRequest(url: serverURL))
            print("✅ Server responded with status: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
        } catch {
            Issue.record("❌ Server not running: \(error)")
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
        
        // Connect first
        wsTask.resume()
        print("🔗 WebSocket connected")
        
        // Start receiving task
        let receiveTask = Task {
            do {
                while wsTask.state == .running {
                    let message = try await wsTask.receive()
                    switch message {
                    case let .string(text):
                        print("📨 Received: \(text)")
                        messages.append(text)
                    case let .data(data):
                        print("📦 Received data: \(data.count) bytes")
                    @unknown default:
                        break
                    }
                }
            } catch {
                // Expected when WebSocket closes
                if !error.localizedDescription.contains("cancelled") {
                    print("❌ Receive error: \(error)")
                }
            }
        }

        // Send config after connection
        try await Task.sleep(nanoseconds: 200_000_000) // 200ms
        let config = """
        {"type":"config","format":"pcm16","sampleRate":16000,"channels":1}
        """
        try await wsTask.send(.string(config))
        print("⚙️ Sent config")
        
        // Wait for ready message
        try await Task.sleep(nanoseconds: 500_000_000) // 500ms

        // Send test audio chunk
        let testData = Data(repeating: 0, count: 1000)
        try await wsTask.send(.data(testData))
        print("🎵 Sent test audio chunk")

        // Wait a bit more for any responses
        try await Task.sleep(nanoseconds: 500_000_000) // 500ms

        // Close
        wsTask.cancel(with: .normalClosure, reason: nil)
        print("🔚 WebSocket closed")
        
        // Cancel receive task
        receiveTask.cancel()
        
        // Wait for task to complete
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms

        print("\n📊 Summary:")
        print("- Messages received: \(messages.count)")
        for (i, msg) in messages.enumerated() {
            print("  [\(i + 1)] \(msg)")
        }

        #expect(!messages.isEmpty, "Should receive at least one message")
        print("✅ Test passed!")
    }
}