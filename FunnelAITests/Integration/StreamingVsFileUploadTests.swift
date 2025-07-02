import AVFoundation
@testable import FunnelAI
import XCTest

/// Integration tests comparing streaming vs file upload performance
class StreamingVsFileUploadTests: XCTestCase {
    let serverBaseURL = "http://localhost:8000"
    var testAudioURL: URL!
    
    override func setUp() async throws {
        try await super.setUp()
        
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
    
    /// Test full file upload performance
    func testFullFileUpload() async throws {
        print("\n🎯 Testing full file upload...")
        
        let startTime = Date()
        
        // Read the file to get size info
        let audioData = try Data(contentsOf: testAudioURL)
        print("📦 File size: \(audioData.count / 1024) KB")
        
        print("⬆️ Uploading file...")
        let uploadStartTime = Date()
        
        // Use APIClient to upload the file
        let result = try await APIClient.shared.processAudio(fileURL: testAudioURL)
        
        let uploadTime = Date().timeIntervalSince(uploadStartTime)
        print("✅ Upload completed in \(String(format: "%.2f", uploadTime))s")
        
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
        
        let result = try await client.streamRecording(sampleRate: 16000) {
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
}
