import AVFoundation
@testable import FunnelAI
import XCTest

// MARK: - WebSocket Response Models

private struct WebSocketResponse: Codable {
    let type: String
    let message: String?
    let segment: TranscriptSegment?
    let fullTranscript: String?
    // Metadata fields
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

/// Integration test for streaming audio to the server and receiving transcripts
class AudioStreamingServerTests: XCTestCase {
    var serverURL: URL!
    var testAudioURL: URL!

    override func setUp() async throws {
        try await super.setUp()

        // Verify server is running
        serverURL = URL(string: "http://localhost:8000")!
        try await verifyServerIsRunning()

        // Get test audio file - use direct path since it's not in the test bundle
        let projectPath = URL(fileURLWithPath: #file)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Funnel")
            .appendingPathComponent("Funnel")
            .appendingPathComponent("sample-recording-mary-had-lamb.m4a")

        if FileManager.default.fileExists(atPath: projectPath.path) {
            testAudioURL = projectPath
            print("📁 Using audio file from: \(projectPath)")
        } else {
            // Try Bundle as fallback
            if let url = Bundle(for: type(of: self)).url(
                forResource: "sample-recording-mary-had-lamb",
                withExtension: "m4a"
            ) {
                testAudioURL = url
                print("📦 Using audio file from test bundle")
            } else {
                XCTFail("Could not find test audio file 'sample-recording-mary-had-lamb.m4a' at \(projectPath)")
                return
            }
        }
    }

    private func verifyServerIsRunning() async throws {
        let request = URLRequest(url: serverURL)
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200
            else {
                print("❌ Server returned status: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
                XCTFail("Server is not running at \(serverURL!). Please start the server with 'cd server && deno task dev'")
                throw XCTSkip("Server not running")
            }
            print("✅ Server is running at \(serverURL!)")
        } catch {
            print("❌ Cannot connect to server: \(error)")
            XCTFail("Cannot connect to server at \(serverURL!): \(error)")
            throw XCTSkip("Server not running")
        }
    }

    /// Receive messages from WebSocket
    private func receiveMessages(from wsTask: URLSessionWebSocketTask, handler: @escaping (String) -> Void) async {
        do {
            while wsTask.state == .running {
                let message = try await wsTask.receive()

                switch message {
                case let .string(text):
                    handler(text)
                case let .data(data):
                    if let text = String(data: data, encoding: .utf8) {
                        handler("Data: \(text)")
                    } else {
                        handler("Data: \(data.count) bytes")
                    }
                @unknown default:
                    handler("Unknown message type")
                }
            }
        } catch {
            if wsTask.state != .completed {
                print("❌ WebSocket receive error: \(error)")
            }
        }
    }

    /// Simple test that streams audio and collects responses
    func testStreamAudioToServer() async throws {
        print("\n🎤 === SIMPLE AUDIO STREAMING TEST START ===")

        // Generate recording ID
        let recordingId = UUID().uuidString
        print("🆔 Recording ID: \(recordingId)")

        // Create WebSocket URL
        let wsURL = URL(string: "ws://localhost:8000/api/recordings/\(recordingId)/stream")!
        print("🔌 WebSocket URL: \(wsURL)")

        // Load and convert audio to PCM
        let audioFile = try AVAudioFile(forReading: testAudioURL)
        let pcmData = try audioFile.convertToPCM()
        print("🎵 Loaded audio: \(pcmData.count) bytes of PCM data")

        // Create WebSocket task
        let session = URLSession(configuration: .default)
        let wsTask = session.webSocketTask(with: wsURL)

        // Arrays to collect responses
        var allResponses: [String] = []
        var parsedResponses: [WebSocketResponse] = []
        var latestFullTranscript = ""
        var metadataReceived = false

        // Start receiving messages
        Task {
            await receiveMessages(from: wsTask) { message in
                allResponses.append(message)

                // Try to parse the response
                if let data = message.data(using: .utf8),
                   let response = try? JSONDecoder().decode(WebSocketResponse.self, from: data)
                {
                    parsedResponses.append(response)

                    // Update latest full transcript if available
                    if let fullTranscript = response.fullTranscript, !fullTranscript.isEmpty {
                        latestFullTranscript = fullTranscript
                    }

                    // Check for Metadata message - any Metadata response after CloseStream
                    // indicates Deepgram has finished processing all audio
                    // See: https://developers.deepgram.com/docs/close-stream
                    if response.type == "Metadata" {
                        print("📊 Received Metadata response (duration: \(response.duration ?? -1))")
                        print("✅ Received Metadata confirmation - transcription complete")
                        metadataReceived = true
                    }
                }
            }
        }

        // Connect WebSocket
        wsTask.resume()
        print("🔗 WebSocket connected")

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

        try await wsTask.send(.string(configString))
        print("⚙️ Sent config: \(configString)")

        try await Task.sleep(for: .milliseconds(100))

        // Stream entire audio file in chunks with 100ms delay
        let chunkSize = 16000 // 1 second at 16kHz mono 16-bit
        var chunkCount = 0

        print("\n📤 Streaming audio chunks (100ms delay between chunks)...")

        for chunkStart in stride(from: 0, to: pcmData.count, by: chunkSize) {
            let chunkEnd = min(chunkStart + chunkSize, pcmData.count)
            let chunk = pcmData[chunkStart ..< chunkEnd]

            // Send chunk
            try await wsTask.send(.data(chunk))
            chunkCount += 1

            try await Task.sleep(for: .milliseconds(100))
        }

        print("✅ Sent \(chunkCount) chunks")

        // Call finalize endpoint - this will trigger server to close Deepgram stream
        print("\n📮 Calling finalize endpoint (this will close Deepgram stream)...")
        let finalizeURL = URL(string: "http://localhost:8000/api/recordings/\(recordingId)/done")!
        var finalizeRequest = URLRequest(url: finalizeURL)
        finalizeRequest.httpMethod = "POST"

        do {
            let startTime = Date()
            let (data, response) = try await URLSession.shared.data(for: finalizeRequest)
            let elapsedTime = Date().timeIntervalSince(startTime)

            if let httpResponse = response as? HTTPURLResponse {
                print("Finalize response status: \(httpResponse.statusCode)")
                print("Finalize took: \(String(format: "%.1f", elapsedTime)) seconds")

                if httpResponse.statusCode == 200,
                   let responseString = String(data: data, encoding: .utf8)
                {
                    print("Finalize response: \(responseString)")

                    // Try to parse ProcessedRecording
                    if let processedRecording = try? JSONDecoder().decode(ProcessedRecording.self, from: data) {
                        print("\n🎯 === PROCESSED RECORDING ===")
                        print("Duration: \(processedRecording.duration) seconds")
                        print("Full transcript: \"\(processedRecording.transcript)\"")
                        print("Bullet summary: \(processedRecording.bulletSummary)")
                        print("Diagram title: \(processedRecording.diagram.title)")
                        print("Diagram description: \(processedRecording.diagram.description)")
                        print("===========================\n")
                    }
                }
            }
        } catch {
            print("❌ Failed to call finalize endpoint: \(error)")
        }

        // Wait for the Metadata confirmation from WebSocket
        print("\n⏳ Waiting for Metadata confirmation from WebSocket...")
        let maxWaitTime = 30000 // 30 seconds max
        var waitedTime = 0

        while !metadataReceived && waitedTime < maxWaitTime {
            try await Task.sleep(for: .milliseconds(100))
            waitedTime += 100
        }

        if metadataReceived {
            print("✅ Metadata confirmation received after \(waitedTime)ms")
        } else {
            print("⚠️ Metadata confirmation not received after \(waitedTime)ms")
        }

        // Now close WebSocket after receiving metadata confirmation
        wsTask.cancel(with: .normalClosure, reason: nil)
        print("🔚 WebSocket closed")

        // Print all collected responses
        print("\n📋 === ALL RESPONSES (\(allResponses.count) total) ===")
        for (index, response) in allResponses.enumerated() {
            print("\n[\(index + 1)] \(response)")
        }
        print("\n=== END OF RESPONSES ===\n")

        // Print parsed transcript information
        print("\n📝 === TRANSCRIPT ANALYSIS ===")
        print("Total parsed responses: \(parsedResponses.count)")

        // Get transcript responses
        let transcriptResponses = parsedResponses.filter { $0.type == "transcript" }
        print("Transcript responses: \(transcriptResponses.count)")

        // Show final segments
        let finalSegments = transcriptResponses.compactMap { response in
            response.segment?.isFinal == true ? response.segment : nil
        }
        print("\nFinal segments (\(finalSegments.count)):")
        for (index, segment) in finalSegments.enumerated() {
            print("  [\(index + 1)] \"\(segment.text)\" (start: \(segment.start), end: \(segment.end))")
        }

        // Show the final full transcript
        print("\n📄 FINAL FULL TRANSCRIPT FROM WEBSOCKET:")
        print("\"\(latestFullTranscript)\"")
        print("\n=== END TRANSCRIPT ANALYSIS ===\n")
    }
}
