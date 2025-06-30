import XCTest
import AVFoundation
@testable import FunnelAI

/// Integration test for streaming audio to the server and receiving transcripts
class AudioStreamingServerTests: XCTestCase {
    var serverURL: URL!
    var testAudioURL: URL!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Verify server is running
        serverURL = URL(string: "http://localhost:8000")!
        try await verifyServerIsRunning()
        
        // Get test audio file
        guard let url = Bundle.main.url(
            forResource: "sample-recording-mary-had-lamb",
            withExtension: "m4a"
        ) else {
            XCTFail("Could not find test audio file 'sample-recording-mary-had-lamb.m4a'")
            return
        }
        testAudioURL = url
    }
    
    private func verifyServerIsRunning() async throws {
        let request = URLRequest(url: serverURL)
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                XCTFail("Server is not running at \(serverURL!). Please start the server with 'cd server && deno task dev'")
                throw XCTSkip("Server not running")
            }
        } catch {
            XCTFail("Cannot connect to server at \(serverURL!): \(error)")
            throw XCTSkip("Server not running")
        }
    }


    // Transcript text of the sample audio file:
    /*
     Okay, so the idea is a children's storybook about a little girl who had an animal as a pet. A small animal, maybe something like a cute, fluffy animal like a bunny rabbit or a lamb. And it's a white animal, so yeah, I guess lamb would be good there. And then it would always follow Mary around. Oh yeah, the little girl is probably named Mary. Okay, there we go. Hopefully this hasn't been done before.
     */

    /// Test streaming audio file to server in chunks
    func testStreamAudioFileToServer() async throws {
        print("\n🎤 === AUDIO STREAMING TEST START ===")
        print("📁 Audio file: \(testAudioURL.lastPathComponent)")
        
        // Generate recording ID
        let recordingId = UUID().uuidString
        print("🆔 Recording ID: \(recordingId)")
        
        // Create WebSocket URL
        let wsURL = URL(string: "ws://localhost:8000/api/recordings/\(recordingId)/stream")!
        print("🔌 WebSocket URL: \(wsURL)")
        
        // Load and convert audio to PCM
        let pcmData = try loadAndConvertToPCM()
        print("🎵 Loaded audio: \(pcmData.count) bytes of PCM data")
        
        // Create WebSocket task
        let session = URLSession(configuration: .default)
        let wsTask = session.webSocketTask(with: wsURL)
        
        // Track received messages
        var receivedMessages: [String] = []
        var transcriptTexts: [String] = []
        let messageExpectation = XCTestExpectation(description: "Receive transcript messages")
        messageExpectation.isInverted = false // We expect to receive messages
        messageExpectation.expectedFulfillmentCount = 1 // At least one transcript
        
        // Start receiving messages
        Task {
            await receiveMessages(from: wsTask) { message in
                print("📨 Received: \(message)")
                receivedMessages.append(message)
                
                // Check if we got a transcript
                if message.contains("\"type\":\"transcript\"") {
                    // Try to parse the transcript
                    if let data = message.data(using: .utf8),
                       let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let segment = json["segment"] as? [String: Any],
                       let text = segment["text"] as? String {
                        transcriptTexts.append(text)
                        print("📝 Transcript text: \"\(text)\"")
                    }
                    messageExpectation.fulfill()
                }
            }
        }
        
        // Connect WebSocket
        wsTask.resume()
        print("🔗 WebSocket connected")
        
        // Wait a moment for connection
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        
        // Send configuration
        let config: [String: Any] = [
            "type": "config",
            "format": "pcm16",
            "sampleRate": 16000,
            "channels": 1
        ]
        let configData = try JSONSerialization.data(withJSONObject: config)
        let configString = String(data: configData, encoding: .utf8)!
        
        try await wsTask.send(.string(configString))
        print("⚙️ Sent config: \(configString)")
        
        // Wait for ready message
        try await Task.sleep(nanoseconds: 200_000_000) // 200ms
        
        // Stream audio in chunks
        let chunkSize = 4800 // ~300ms at 16kHz mono 16-bit
        let delayNanoseconds: UInt64 = 10_000_000 // 10ms
        var chunkCount = 0
        
        print("\n📤 Starting audio streaming...")
        print("   Chunk size: \(chunkSize) bytes")
        print("   Delay between chunks: 10ms")
        
        for chunkStart in stride(from: 0, to: pcmData.count, by: chunkSize) {
            let chunkEnd = min(chunkStart + chunkSize, pcmData.count)
            let chunk = pcmData[chunkStart..<chunkEnd]
            
            // Send chunk
            try await wsTask.send(.data(chunk))
            chunkCount += 1
            
            if chunkCount % 10 == 0 {
                print("   📊 Sent chunk \(chunkCount): \(chunk.count) bytes")
            }
            
            // Small delay between chunks
            try await Task.sleep(nanoseconds: delayNanoseconds)
        }
        
        print("✅ Finished streaming \(chunkCount) chunks")
        
        // Wait for transcripts to arrive
        print("\n⏳ Waiting for transcripts...")
        await fulfillment(of: [messageExpectation], timeout: 10.0)
        
        // Close WebSocket
        wsTask.cancel(with: .normalClosure, reason: nil)
        print("🔚 WebSocket closed")
        
        // Log all received messages
        print("\n📋 === ALL RECEIVED MESSAGES ===")
        for (index, message) in receivedMessages.enumerated() {
            print("\n[\(index + 1)] \(message)")
        }
        print("================================\n")
        
        // Basic verification
        XCTAssertFalse(receivedMessages.isEmpty, "Should receive at least one message")
        
        // Check for transcript messages
        let transcriptMessages = receivedMessages.filter { $0.contains("\"type\":\"transcript\"") }
        XCTAssertFalse(transcriptMessages.isEmpty, "Should receive at least one transcript")
        
        print("🎉 Test completed successfully!")
        print("📊 Total messages received: \(receivedMessages.count)")
        print("📝 Transcript messages: \(transcriptMessages.count)")
        
        // Verify transcript content
        print("\n🔍 === TRANSCRIPT VERIFICATION ===")
        let allTranscriptText = transcriptTexts.joined(separator: " ").lowercased()
        print("📄 Full transcript: \"\(allTranscriptText)\"")
        
        // Check for expected content based on the actual audio:
        // "children's storybook about a little girl who had an animal as a pet"
        // "lamb would be good" "always follow Mary around" "little girl is probably named Mary"
        let expectedWords = ["mary", "lamb", "girl", "animal", "little"]
        var foundWords: [String] = []
        
        for word in expectedWords {
            if allTranscriptText.contains(word) {
                foundWords.append(word)
                print("✓ Contains '\(word)': true")
            } else {
                print("✗ Contains '\(word)': false")
            }
        }

        print("printing...")
        print(allTranscriptText)

        // Assert we found at least the key words Mary and lamb
        XCTAssertTrue(allTranscriptText.contains("mary"), "Transcript should contain 'mary'")
        XCTAssertTrue(allTranscriptText.contains("lamb") || allTranscriptText.contains("animal"), 
                      "Transcript should contain 'lamb' or 'animal'")
        XCTAssertGreaterThanOrEqual(foundWords.count, 3, 
                                    "Should find at least 3 of the expected words, found: \(foundWords)")
        
        print("\n✅ Transcript verification passed!")
        print("Found \(foundWords.count)/\(expectedWords.count) expected words: \(foundWords.joined(separator: ", "))")
        print("=================================")
    }
    
    /// Load audio file and convert to 16-bit PCM at 16kHz mono
    private func loadAndConvertToPCM() throws -> Data {
        let audioFile = try AVAudioFile(forReading: testAudioURL)
        
        // Define target format: 16kHz mono 16-bit PCM
        guard let outputFormat = AVAudioFormat(
            commonFormat: .pcmFormatInt16,
            sampleRate: 16000,
            channels: 1,
            interleaved: false
        ) else {
            throw NSError(domain: "AudioTest", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create output format"])
        }
        
        // Create converter
        guard let converter = AVAudioConverter(from: audioFile.processingFormat, to: outputFormat) else {
            throw NSError(domain: "AudioTest", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to create converter"])
        }
        
        // Read entire file
        let frameCount = AVAudioFrameCount(audioFile.length)
        guard let inputBuffer = AVAudioPCMBuffer(pcmFormat: audioFile.processingFormat, frameCapacity: frameCount) else {
            throw NSError(domain: "AudioTest", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to create input buffer"])
        }
        
        try audioFile.read(into: inputBuffer)
        
        // Create output buffer
        let outputFrameCapacity = converter.outputFormat.sampleRate * Double(frameCount) / audioFile.processingFormat.sampleRate
        guard let outputBuffer = AVAudioPCMBuffer(
            pcmFormat: outputFormat,
            frameCapacity: AVAudioFrameCount(outputFrameCapacity)
        ) else {
            throw NSError(domain: "AudioTest", code: 4, userInfo: [NSLocalizedDescriptionKey: "Failed to create output buffer"])
        }
        
        // Convert
        var error: NSError?
        let status = converter.convert(to: outputBuffer, error: &error) { _, outStatus in
            outStatus.pointee = .haveData
            return inputBuffer
        }
        
        guard status != .error, error == nil else {
            throw error ?? NSError(domain: "AudioTest", code: 5, userInfo: [NSLocalizedDescriptionKey: "Conversion failed"])
        }
        
        // Extract PCM data
        return extractPCMData(from: outputBuffer)
    }
    
    /// Extract raw PCM data from audio buffer
    private func extractPCMData(from buffer: AVAudioPCMBuffer) -> Data {
        let frameLength = Int(buffer.frameLength)
        var data = Data(capacity: frameLength * 2) // 2 bytes per 16-bit sample
        
        guard let samples = buffer.int16ChannelData?[0] else {
            return data
        }
        
        let samplePointer = UnsafeBufferPointer(start: samples, count: frameLength)
        
        for sample in samplePointer {
            // Convert to little endian
            let littleEndianSample = sample.littleEndian
            withUnsafeBytes(of: littleEndianSample) { bytes in
                data.append(contentsOf: bytes)
            }
        }
        
        return data
    }
    
    /// Receive messages from WebSocket
    private func receiveMessages(from wsTask: URLSessionWebSocketTask, handler: @escaping (String) -> Void) async {
        do {
            while wsTask.state == .running {
                let message = try await wsTask.receive()
                
                switch message {
                case .string(let text):
                    handler(text)
                case .data(let data):
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
}
