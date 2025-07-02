import XCTest
import Foundation
@testable import FunnelAI

/// Tests for the simplified V2 audio streaming API
class AudioStreamingServerV2Tests: XCTestCase {
    let serverURL = "http://localhost:8000"
    let testAudioDuration = 5.0 // 5 seconds of test audio
    
    override func setUp() {
        super.setUp()
        print("=== Starting V2 Audio Streaming Test ===")
    }
    
    override func tearDown() {
        print("=== Completed V2 Audio Streaming Test ===")
        super.tearDown()
    }
    
    /// Test the complete V2 flow: stream audio, finalize, then retrieve results
    func testV2AudioStreamingFlow() async throws {
        // Generate a unique recording ID
        let recordingId = UUID().uuidString
        print("Recording ID: \(recordingId)")
        
        // 1. Connect WebSocket and stream audio
        try await streamAudioViaWebSocket(recordingId: recordingId)
        
        // 2. Finalize the recording
        try await finalizeRecording(recordingId: recordingId)
        
        // 3. Retrieve the processed recording
        let recording = try await getProcessedRecording(recordingId: recordingId)
        
        // Verify results
        XCTAssertFalse(recording.transcript.isEmpty, "Transcript should not be empty")
        XCTAssertGreaterThan(recording.duration, 0, "Duration should be greater than 0")
        XCTAssertFalse(recording.bulletSummary.isEmpty, "Bullet summary should not be empty")
        XCTAssertFalse(recording.diagram.title.isEmpty, "Diagram title should not be empty")
        
        print("✅ Test completed successfully!")
        print("Transcript length: \(recording.transcript.count) characters")
        print("Duration: \(recording.duration) seconds")
        print("Bullet points: \(recording.bulletSummary.count)")
    }
    
    // MARK: - Helper Methods
    
    /// Stream audio chunks via WebSocket
    private func streamAudioViaWebSocket(recordingId: String) async throws {
        print("\n1️⃣ Starting WebSocket audio streaming...")
        
        let wsURL = URL(string: "\(serverURL.replacingOccurrences(of: "http", with: "ws"))/api/v2/recordings/\(recordingId)/stream")!
        
        let session = URLSession(configuration: .default)
        let socket = session.webSocketTask(with: wsURL)
        socket.resume()
        
        // Wait for ready message
        let readyExpectation = XCTestExpectation(description: "WebSocket ready")
        
        Task {
            while socket.state == .running {
                do {
                    let message = try await socket.receive()
                    switch message {
                    case .string(let text):
                        if let data = text.data(using: .utf8),
                           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                           let type = json["type"] as? String {
                            print("Received message: \(type)")
                            
                            if type == "ready" {
                                readyExpectation.fulfill()
                            } else if type == "processingComplete" {
                                print("✅ Processing complete notification received")
                                if let duration = json["duration"] as? Double {
                                    print("  Duration: \(duration) seconds")
                                }
                            }
                        }
                    case .data:
                        print("Received unexpected binary data")
                    @unknown default:
                        break
                    }
                } catch {
                    print("WebSocket receive error: \(error)")
                    break
                }
            }
        }
        
        await fulfillment(of: [readyExpectation], timeout: 10)
        print("✅ WebSocket connected and ready")
        
        // Generate and send test audio chunks
        let sampleRate = 16000
        let chunkDuration = 1.0 // 1 second chunks
        let samplesPerChunk = Int(Double(sampleRate) * chunkDuration)
        let totalChunks = Int(testAudioDuration / chunkDuration)
        
        print("Streaming \(totalChunks) audio chunks...")
        
        for i in 0..<totalChunks {
            // Generate PCM audio data (sine wave for testing)
            let audioData = generatePCMAudioChunk(
                frequency: 440.0 + Double(i) * 50.0, // Vary frequency
                sampleRate: sampleRate,
                samples: samplesPerChunk
            )
            
            try await socket.send(.data(audioData))
            print("  Sent chunk \(i + 1)/\(totalChunks) (\(audioData.count) bytes)")
            
            // Small delay between chunks
            try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        }
        
        print("✅ All audio chunks sent")
        
        // Keep connection open until we call finalize
        // Don't close the WebSocket yet!
    }
    
    /// Finalize the recording
    private func finalizeRecording(recordingId: String) async throws {
        print("\n2️⃣ Finalizing recording...")
        
        let url = URL(string: "\(serverURL)/api/v2/recordings/\(recordingId)/finalize")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw TestError.invalidResponse
        }
        
        print("Finalize response status: \(httpResponse.statusCode)")
        
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            print("Finalize response: \(json)")
            
            if httpResponse.statusCode == 200,
               let success = json["success"] as? Bool,
               success {
                print("✅ Recording finalized successfully")
                if let processingTime = json["processingTime"] as? Int {
                    print("  Processing time: \(processingTime)ms")
                }
                if let segmentCount = json["segmentCount"] as? Int {
                    print("  Segment count: \(segmentCount)")
                }
            } else {
                throw TestError.finalizationFailed(json["error"] as? String ?? "Unknown error")
            }
        } else {
            throw TestError.invalidJSON
        }
    }
    
    /// Get the processed recording with transcript and AI summaries
    private func getProcessedRecording(recordingId: String) async throws -> ProcessedRecording {
        print("\n3️⃣ Getting processed recording...")
        
        let url = URL(string: "\(serverURL)/api/v2/recordings/\(recordingId)")!
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw TestError.invalidResponse
        }
        
        print("Get recording response status: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorJson["error"] as? String {
                throw TestError.serverError(error)
            }
            throw TestError.httpError(httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        let recording = try decoder.decode(ProcessedRecording.self, from: data)
        
        print("✅ Retrieved processed recording")
        print("  Transcript preview: \(String(recording.transcript.prefix(100)))...")
        print("  Bullet points:")
        for (i, bullet) in recording.bulletSummary.prefix(3).enumerated() {
            print("    \(i + 1). \(bullet)")
        }
        print("  Diagram: \(recording.diagram.title)")
        
        return recording
    }
    
    /// Generate PCM audio data for testing
    private func generatePCMAudioChunk(frequency: Double, sampleRate: Int, samples: Int) -> Data {
        var audioData = Data()
        
        for i in 0..<samples {
            // Generate sine wave
            let time = Double(i) / Double(sampleRate)
            let value = sin(2.0 * Double.pi * frequency * time)
            
            // Convert to 16-bit PCM
            let sample = Int16(value * Double(Int16.max))
            withUnsafeBytes(of: sample.littleEndian) { bytes in
                audioData.append(contentsOf: bytes)
            }
        }
        
        return audioData
    }
}

// MARK: - Supporting Types

// Note: ProcessedRecording and Diagram are imported from the main app target

enum TestError: LocalizedError {
    case websocketConnectionFailed
    case invalidResponse
    case invalidJSON
    case finalizationFailed(String)
    case serverError(String)
    case httpError(Int)
    
    var errorDescription: String? {
        switch self {
        case .websocketConnectionFailed:
            return "Failed to connect WebSocket"
        case .invalidResponse:
            return "Invalid HTTP response"
        case .invalidJSON:
            return "Invalid JSON response"
        case .finalizationFailed(let message):
            return "Finalization failed: \(message)"
        case .serverError(let message):
            return "Server error: \(message)"
        case .httpError(let code):
            return "HTTP error: \(code)"
        }
    }
}

