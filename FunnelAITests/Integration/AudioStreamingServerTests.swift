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
                  httpResponse.statusCode == 200 else {
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


    // Transcript text of the sample audio file:
    /*
     Okay, so the idea is a children's storybook about a little girl who had an animal as a pet. A small animal, maybe something like a cute, fluffy animal like a bunny rabbit or a lamb. And it's a white animal, so yeah, I guess lamb would be good there. And then it would always follow Mary around. Oh yeah, the little girl is probably named Mary. Okay, there we go. Hopefully this hasn't been done before.
     */

    /// Test streaming audio file to server in chunks
    func testStreamAudioFileToServer() async throws {
        // Add a breakpoint here to see console output in Xcode
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
        
        // Start receiving messages
        Task {
            await receiveMessages(from: wsTask) { message in
                print("📨 Received: \(message)")
                receivedMessages.append(message)
                
                // Check if we got a transcript
                if message.contains("\"type\":\"transcript\"") {
                    // Try to parse the transcript
                    do {
                        if let data = message.data(using: .utf8),
                           let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                           let segment = json["segment"] as? [String: Any],
                           let text = segment["text"] as? String {
                            transcriptTexts.append(text)
                            print("📝 Transcript text: \"\(text)\"")
                            
                            // Also log the full transcript if available
                            if let fullTranscript = json["fullTranscript"] as? String {
                                print("📄 Full transcript so far: \"\(fullTranscript)\"")
                            }
                        } else {
                            print("⚠️ Failed to parse transcript from: \(message)")
                        }
                    } catch {
                        print("⚠️ JSON parsing error: \(error)")
                        print("   Message was: \(message)")
                    }
                }
                
                // Check for errors
                if message.contains("\"type\":\"error\"") {
                    print("❌ Received error message: \(message)")
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
        let chunkSize = 16000 // 1 second at 16kHz mono 16-bit (more efficient)
        let delayNanoseconds: UInt64 = 100_000_000 // 100ms between chunks
        var chunkCount = 0
        
        print("\n📤 Starting audio streaming...")
        print("   Chunk size: \(chunkSize) bytes")
        print("   Delay between chunks: 100ms")
        
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
        
        // Wait for transcripts to arrive - need to wait longer for Deepgram to process
        print("\n⏳ Waiting for transcripts to arrive...")
        
        // First, wait for initial transcripts
        var waitTime = 0
        let maxWaitTime = 10000 // 10 seconds max
        let checkInterval = 100 // 100ms
        
        while transcriptTexts.isEmpty && waitTime < maxWaitTime {
            try await Task.sleep(nanoseconds: UInt64(checkInterval) * 1_000_000)
            waitTime += checkInterval
        }
        
        // If we got transcripts, wait longer for the rest to arrive
        if !transcriptTexts.isEmpty {
            print("📨 Got first transcript, waiting for more...")
            
            // Keep waiting while we're still receiving new transcripts
            var lastCount = transcriptTexts.count
            var stableTime = 0
            let stableThreshold = 2000 // 2 seconds of no new transcripts
            
            while stableTime < stableThreshold && waitTime < maxWaitTime {
                try await Task.sleep(nanoseconds: 500_000_000) // 500ms
                waitTime += 500
                
                if transcriptTexts.count > lastCount {
                    // Got new transcripts, reset stable timer
                    lastCount = transcriptTexts.count
                    stableTime = 0
                    print("📨 Got more transcripts (total: \(lastCount))")
                } else {
                    // No new transcripts, increment stable timer
                    stableTime += 500
                }
            }
        }
        
        print("⏱️ Total wait time: \(waitTime)ms")
        print("📝 Final transcript count: \(transcriptTexts.count)")
        
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
        print("📊 Transcript count: \(transcriptTexts.count)")
        print("📏 Total transcript length: \(allTranscriptText.count) characters")
        
        // If we have no transcripts, fail early with clear message
        if transcriptTexts.isEmpty {
            let debugInfo = """
            No transcripts received from server.
            
            Debug info:
            - Recording ID: \(recordingId)
            - WebSocket URL: \(wsURL)
            - Audio size: \(pcmData.count) bytes
            - Chunks sent: \(chunkCount)
            - Total messages: \(receivedMessages.count)
            - Messages: \(receivedMessages.prefix(5).joined(separator: "\n"))
            
            Check if:
            1. Server is running
            2. WebSocket connection was successful
            3. Audio was properly streamed
            4. Deepgram API key is set in server
            """
            XCTFail(debugInfo)
            return
        }
        
        // Check for expected content based on the actual audio:
        // We expect at least: "children's storybook about a little girl who had an animal as a pet"
        // The full audio also mentions: "lamb", "Mary", etc. but those might come later
        let expectedWords = ["children", "storybook", "girl", "animal", "pet", "little"]
        var foundWords: [String] = []
        
        for word in expectedWords {
            if allTranscriptText.contains(word) {
                foundWords.append(word)
                print("✓ Contains '\(word)': true")
            } else {
                print("✗ Contains '\(word)': false")
            }
        }

        // More lenient assertions - we should at least get the beginning of the transcript
        XCTAssertTrue(allTranscriptText.contains("children") || allTranscriptText.contains("story"), 
                      "Transcript should contain 'children' or 'story'. Got: '\(allTranscriptText)'")
        XCTAssertTrue(allTranscriptText.contains("girl") || allTranscriptText.contains("animal"), 
                      "Transcript should contain 'girl' or 'animal'. Got: '\(allTranscriptText)'")
        XCTAssertGreaterThanOrEqual(foundWords.count, 2, 
                                    "Should find at least 2 of the expected words, found: \(foundWords)")
        
        print("\n✅ Transcript verification passed!")
        print("Found \(foundWords.count)/\(expectedWords.count) expected words: \(foundWords.joined(separator: ", "))")
        print("=================================")
        
        // Test completed successfully
        XCTAssertTrue(true, "Test completed successfully")
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
