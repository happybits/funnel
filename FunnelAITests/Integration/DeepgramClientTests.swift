import AVFoundation
@testable import FunnelAI
import XCTest

/// Integration test for DeepgramClient
class DeepgramClientTests: XCTestCase {
    var client: DeepgramClient!
    var testAudioURL: URL!

    override func setUp() async throws {
        try await super.setUp()

        // Initialize client
        client = DeepgramClient(serverBaseURL: "http://localhost:8000")

        // Verify server is running
        try await verifyServerIsRunning()

        // Get test audio file from the test bundle
        guard let url = Bundle(for: type(of: self)).url(
            forResource: "sample-recording-mary-had-lamb",
            withExtension: "m4a"
        ) else {
            XCTFail("Could not find test audio file 'sample-recording-mary-had-lamb.m4a' in test bundle")
            return
        }
        
        testAudioURL = url
        print("📦 Using audio file from test bundle: \(url)")
    }

    private func verifyServerIsRunning() async throws {
        let serverURL = URL(string: "http://localhost:8000")!
        let request = URLRequest(url: serverURL)
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200
            else {
                print("❌ Server returned status: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
                XCTFail("Server is not running at \(serverURL). Please start the server with 'cd server && deno task dev'")
                throw XCTSkip("Server not running")
            }
            print("✅ Server is running at \(serverURL)")
        } catch {
            print("❌ Cannot connect to server: \(error)")
            XCTFail("Cannot connect to server at \(serverURL): \(error)")
            throw XCTSkip("Server not running")
        }
    }

    /// Test streaming audio file using DeepgramClient
    func testStreamAudioFileWithDeepgramClient() async throws {
        print("\n🎤 === DEEPGRAM CLIENT AUDIO STREAMING TEST START ===")

        // Stream the audio file
        let startTime = Date()
        let processedRecording = try await client.streamAudioFile(at: testAudioURL)
        let elapsedTime = Date().timeIntervalSince(startTime)

        print("\n⏱️ Total processing time: \(String(format: "%.2f", elapsedTime)) seconds")

        // Verify the results
        print("\n🎯 === PROCESSED RECORDING ===")
        print("Duration: \(processedRecording.duration) seconds")
        print("Full transcript: \"\(processedRecording.transcript)\"")
        print("Bullet summary (\(processedRecording.bulletSummary.count) items):")
        for (index, bullet) in processedRecording.bulletSummary.enumerated() {
            print("  \(index + 1). \(bullet)")
        }
        print("Diagram title: \(processedRecording.diagram.title)")
        print("Diagram description: \(processedRecording.diagram.description)")
        print("Diagram content preview: \(String(processedRecording.diagram.content.prefix(100)))...")
        print("=========================\n")

        // Assertions
        XCTAssertGreaterThan(processedRecording.duration, 0, "Duration should be greater than 0")
        XCTAssertFalse(processedRecording.transcript.isEmpty, "Transcript should not be empty")
        XCTAssertFalse(processedRecording.bulletSummary.isEmpty, "Bullet summary should not be empty")
        XCTAssertFalse(processedRecording.diagram.title.isEmpty, "Diagram title should not be empty")
        XCTAssertFalse(processedRecording.diagram.description.isEmpty, "Diagram description should not be empty")
        XCTAssertFalse(processedRecording.diagram.content.isEmpty, "Diagram content should not be empty")

        // Verify transcript contains expected content
        let transcriptLower = processedRecording.transcript.lowercased()
        XCTAssertTrue(
            transcriptLower.contains("mary") || transcriptLower.contains("lamb"),
            "Transcript should contain words from Mary Had a Little Lamb"
        )

        print("✅ DeepgramClient test completed successfully!")
    }

    /// Test streaming with custom audio data provider
    func testStreamWithCustomDataProvider() async throws {
        print("\n🎤 === CUSTOM DATA PROVIDER TEST START ===")

        // Load audio data
        let audioFile = try AVAudioFile(forReading: testAudioURL)
        let pcmData = try audioFile.convertToPCM()
        print("🎵 Loaded \(pcmData.count) bytes of PCM data")

        // Create a custom provider that streams in smaller chunks
        let chunkSize = 8000 // 0.5 seconds at 16kHz
        var offset = 0
        var chunkCount = 0

        let processedRecording = try await client.streamRecording {
            guard offset < pcmData.count else {
                print("✅ Finished streaming \(chunkCount) chunks")
                return nil
            }
            
            let chunkEnd = min(offset + chunkSize, pcmData.count)
            let chunk = pcmData[offset ..< chunkEnd]
            offset = chunkEnd
            chunkCount += 1
            
            if chunkCount % 5 == 0 {
                print("📤 Streamed chunk \(chunkCount) (\(offset)/\(pcmData.count) bytes)")
            }
            
            return chunk
        }

        // Verify results
        print("\n🎯 === RESULTS ===")
        print("Total chunks sent: \(chunkCount)")
        print("Transcript length: \(processedRecording.transcript.count) characters")
        print("Bullet points: \(processedRecording.bulletSummary.count)")
        
        XCTAssertFalse(processedRecording.transcript.isEmpty, "Transcript should not be empty")
        XCTAssertFalse(processedRecording.bulletSummary.isEmpty, "Bullet summary should not be empty")
        
        print("✅ Custom data provider test completed successfully!")
    }
}