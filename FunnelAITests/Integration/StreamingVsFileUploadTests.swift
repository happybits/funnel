import AVFoundation
@testable import FunnelAI
import XCTest

/// Integration tests comparing streaming vs file upload performance
class StreamingVsFileUploadTests: XCTestCase {
    let serverBaseURL = "http://localhost:8000"
    var testAudioURL: URL!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Verify server is running
        try await verifyServerIsRunning()
        
        // Get test audio file
        guard let url = Bundle(for: type(of: self)).url(
            forResource: "sample-recording-mary-had-lamb",
            withExtension: "m4a"
        ) else {
            XCTFail("Could not find test audio file")
            return
        }
        
        testAudioURL = url
    }
    
    private func verifyServerIsRunning() async throws {
        guard let url = URL(string: "\(serverBaseURL)/health") else {
            XCTFail("Invalid server URL")
            return
        }
        
        do {
            let (_, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200
            else {
                XCTFail("Server health check failed. Make sure the server is running with 'deno task dev'")
                return
            }
        } catch {
            XCTFail("Could not connect to server at \(serverBaseURL). Make sure the server is running with 'deno task dev'. Error: \(error)")
        }
    }
    
    /// Test full file upload performance
    func testFullFileUpload() async throws {
        print("\n🎯 Testing full file upload...")
        
        let startTime = Date()
        
        // Read the entire file
        let audioData = try Data(contentsOf: testAudioURL)
        print("📦 File size: \(audioData.count / 1024) KB")
        
        // Create multipart form data
        let boundary = UUID().uuidString
        var body = Data()
        
        // Add audio file part
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"audio\"; filename=\"test-audio.m4a\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/mp4\r\n\r\n".data(using: .utf8)!)
        body.append(audioData)
        body.append("\r\n".data(using: .utf8)!)
        
        // Add closing boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        // Create request
        guard let url = URL(string: "\(serverBaseURL)/api/new-recording") else {
            XCTFail("Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        request.timeoutInterval = 120 // 2 minutes timeout
        
        print("⬆️ Uploading file...")
        let uploadStartTime = Date()
        
        // Upload and get response
        let (data, response) = try await URLSession.shared.data(for: request)
        
        let uploadTime = Date().timeIntervalSince(uploadStartTime)
        print("✅ Upload completed in \(String(format: "%.2f", uploadTime))s")
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200
        else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            XCTFail("Upload failed: \(errorMessage)")
            return
        }
        
        // Parse response
        let result = try JSONDecoder().decode(ProcessedRecording.self, from: data)
        
        let totalTime = Date().timeIntervalSince(startTime)
        
        print("\n📊 Full File Upload Results:")
        print("   Total time: \(String(format: "%.2f", totalTime))s")
        print("   Upload time: \(String(format: "%.2f", uploadTime))s")
        print("   Processing time: \(String(format: "%.2f", totalTime - uploadTime))s")
        print("   Transcript length: \(result.transcript.count) characters")
        print("   Bullet points: \(result.bulletSummary.count)")
        
        XCTAssertNotNil(result.transcript)
        XCTAssertNotNil(result.bulletSummary)
        XCTAssertNotNil(result.diagram)
    }
    
    /// Test streaming with realistic timing (mimics real-time streaming)
    func testStreamingWithRealisticTiming() async throws {
        print("\n🎯 Testing streaming with realistic timing (32s audio)...")
        
        let startTime = Date()
        let client = DeepgramClient(serverBaseURL: serverBaseURL)
        
        // Load audio file and convert to PCM
        let audioFile = try AVAudioFile(forReading: testAudioURL)
        let audioData = try audioFile.convertToPCM()
        
        print("📦 Audio data size: \(audioData.count / 1024) KB")
        
        // Calculate chunk size for ~32 second audio with 100ms chunks
        let audioDurationSeconds: Double = 32.0
        let chunkIntervalSeconds: Double = 0.1 // 100ms
        let totalChunks = Int(audioDurationSeconds / chunkIntervalSeconds)
        let chunkSize = audioData.count / totalChunks
        
        print("📊 Streaming plan: \(totalChunks) chunks of ~\(chunkSize / 1024) KB each")
        
        var streamedBytes = 0
        var chunkCount = 0
        
        let result = try await client.streamRecording {
            guard streamedBytes < audioData.count else {
                print("✅ Finished streaming all chunks")
                return nil
            }
            
            // Calculate chunk range
            let start = streamedBytes
            let end = min(streamedBytes + chunkSize, audioData.count)
            let chunk = audioData.subdata(in: start..<end)
            
            streamedBytes = end
            chunkCount += 1
            
            // Wait to simulate real-time streaming
            try await Task.sleep(for: .milliseconds(100))
            
            if chunkCount % 50 == 0 || chunkCount == 1 {
                let progress = Double(streamedBytes) / Double(audioData.count) * 100
                print("⏳ Streamed chunk \(chunkCount)/\(totalChunks) (\(String(format: "%.1f", progress))%)")
            }
            
            return chunk
        }
        
        let totalTime = Date().timeIntervalSince(startTime)
        
        print("\n📊 Realistic Streaming Results:")
        print("   Total time: \(String(format: "%.2f", totalTime))s")
        print("   Expected streaming time: \(String(format: "%.2f", audioDurationSeconds))s")
        print("   Processing overhead: \(String(format: "%.2f", totalTime - audioDurationSeconds))s")
        print("   Transcript length: \(result.transcript.count) characters")
        print("   Bullet points: \(result.bulletSummary.count)")
        
        XCTAssertNotNil(result.transcript)
        XCTAssertNotNil(result.bulletSummary)
        XCTAssertNotNil(result.diagram)
    }
    
    /// Test streaming as fast as possible (no artificial delays)
    func testStreamingAsFastAsPossible() async throws {
        print("\n🎯 Testing streaming as fast as possible...")
        
        let startTime = Date()
        let client = DeepgramClient(serverBaseURL: serverBaseURL)
        
        // Load audio file and convert to PCM
        let audioFile = try AVAudioFile(forReading: testAudioURL)
        let audioData = try audioFile.convertToPCM()
        
        print("📦 Audio data size: \(audioData.count / 1024) KB")
        
        // Use 1KB chunks for fast streaming
        let chunkSize = 1024
        var streamedBytes = 0
        var chunkCount = 0
        
        let result = try await client.streamRecording {
            guard streamedBytes < audioData.count else {
                print("✅ Finished streaming all chunks")
                return nil
            }
            
            // Calculate chunk range
            let start = streamedBytes
            let end = min(streamedBytes + chunkSize, audioData.count)
            let chunk = audioData.subdata(in: start..<end)
            
            streamedBytes = end
            chunkCount += 1
            
            if chunkCount % 100 == 0 || chunkCount == 1 {
                let progress = Double(streamedBytes) / Double(audioData.count) * 100
                print("⚡ Streamed chunk \(chunkCount) (\(String(format: "%.1f", progress))%)")
            }
            
            return chunk
        }
        
        let totalTime = Date().timeIntervalSince(startTime)
        
        print("\n📊 Fast Streaming Results:")
        print("   Total time: \(String(format: "%.2f", totalTime))s")
        print("   Total chunks: \(chunkCount)")
        print("   Average chunk time: \(String(format: "%.2f", totalTime / Double(chunkCount) * 1000))ms")
        print("   Transcript length: \(result.transcript.count) characters")
        print("   Bullet points: \(result.bulletSummary.count)")
        
        XCTAssertNotNil(result.transcript)
        XCTAssertNotNil(result.bulletSummary)
        XCTAssertNotNil(result.diagram)
    }
    
    /// Run all tests and compare results
    func testCompareAllMethods() async throws {
        print("\n🏁 Running comprehensive comparison test...\n")
        
        var results: [(method: String, time: Double)] = []
        
        // Test 1: Full file upload
        do {
            let start = Date()
            try await testFullFileUpload()
            let time = Date().timeIntervalSince(start)
            results.append(("Full File Upload", time))
        } catch {
            print("❌ Full file upload failed: \(error)")
        }
        
        // Test 2: Realistic streaming
        do {
            let start = Date()
            try await testStreamingWithRealisticTiming()
            let time = Date().timeIntervalSince(start)
            results.append(("Realistic Streaming (32s)", time))
        } catch {
            print("❌ Realistic streaming failed: \(error)")
        }
        
        // Test 3: Fast streaming
        do {
            let start = Date()
            try await testStreamingAsFastAsPossible()
            let time = Date().timeIntervalSince(start)
            results.append(("Fast Streaming", time))
        } catch {
            print("❌ Fast streaming failed: \(error)")
        }
        
        // Print comparison
        print("\n📊 === PERFORMANCE COMPARISON ===")
        for result in results.sorted(by: { $0.time < $1.time }) {
            print("   \(result.method): \(String(format: "%.2f", result.time))s")
        }
        
        if let fastest = results.min(by: { $0.time < $1.time }),
           let slowest = results.max(by: { $0.time < $1.time }) {
            let speedup = slowest.time / fastest.time
            print("\n🏆 \(fastest.method) is \(String(format: "%.1fx", speedup)) faster than \(slowest.method)")
        }
    }
}