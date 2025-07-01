import XCTest
import Foundation
import AVFoundation
@testable import FunnelAI

/// Tests for the V2 API using real audio files
class AudioStreamingServerV2RealAudioTests: XCTestCase {
    let serverURL = "https://funnel-api.deno.dev"
    // Use local server for faster testing
    // let serverURL = "http://localhost:8000"
    
    override func setUp() {
        super.setUp()
        print("=== Starting V2 Real Audio Test ===")
    }
    
    /// Test V2 flow with a real audio file
    func testV2WithRealAudioFile() async throws {
        // Load test audio file
        let bundle = Bundle(for: type(of: self))
        guard let audioURL = bundle.url(forResource: "test-audio-16khz", withExtension: "wav") else {
            print("⚠️ Test audio file not found, generating one...")
            let audioData = try await generateTestAudioFile()
            try await performTest(with: audioData)
            return
        }
        
        let audioData = try Data(contentsOf: audioURL)
        print("Loaded audio file: \(audioData.count) bytes")
        
        try await performTest(with: audioData)
    }
    
    /// Test V2 flow with generated speech
    func testV2WithGeneratedSpeech() async throws {
        print("Generating speech audio...")
        let audioData = try await generateSpeechAudio(
            text: "Hello, this is a test of the Funnel audio streaming API version 2. " +
                  "The quick brown fox jumps over the lazy dog. " +
                  "This sentence contains multiple words to test transcription accuracy."
        )
        
        print("Generated audio: \(audioData.count) bytes")
        try await performTest(with: audioData)
    }
    
    // MARK: - Helper Methods
    
    private func performTest(with audioData: Data) async throws {
        let recordingId = UUID().uuidString
        print("Recording ID: \(recordingId)")
        
        // 1. Stream audio
        try await streamAudioData(audioData, recordingId: recordingId)
        
        // 2. Finalize
        let finalizationResult = try await finalizeRecording(recordingId: recordingId)
        print("Finalization result: \(finalizationResult)")
        
        // 3. Get processed recording
        let recording = try await getProcessedRecording(recordingId: recordingId)
        
        // Verify
        XCTAssertFalse(recording.transcript.isEmpty)
        XCTAssertGreaterThan(recording.duration, 0)
        XCTAssertFalse(recording.bulletSummary.isEmpty)
        
        print("\n✅ Test completed successfully!")
        print("📝 Full transcript:")
        print(recording.transcript)
    }
    
    private func streamAudioData(_ audioData: Data, recordingId: String) async throws {
        print("\n1️⃣ Connecting WebSocket...")
        
        let wsURL = URL(string: "\(serverURL.replacingOccurrences(of: "https", with: "wss").replacingOccurrences(of: "http", with: "ws"))/api/v2/recordings/\(recordingId)/stream")!
        
        let session = URLSession(configuration: .default)
        let task = session.webSocketTask(with: wsURL)
        task.resume()
        
        // Wait for ready message
        var isReady = false
        var processingComplete = false
        
        // Start receiving messages
        Task {
            while task.state == .running && !processingComplete {
                do {
                    let message = try await task.receive()
                    if case .string(let text) = message,
                       let data = text.data(using: .utf8),
                       let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let type = json["type"] as? String {
                        
                        print("📨 Received: \(type)")
                        
                        switch type {
                        case "ready":
                            isReady = true
                        case "processingComplete":
                            processingComplete = true
                            if let duration = json["duration"] as? Double {
                                print("  Duration: \(duration)s")
                            }
                        case "error":
                            if let message = json["message"] as? String {
                                throw TestError.serverError(message)
                            }
                        default:
                            break
                        }
                    }
                } catch {
                    if !processingComplete {
                        print("❌ WebSocket error: \(error)")
                    }
                    break
                }
            }
        }
        
        // Wait for ready
        var attempts = 0
        while !isReady && attempts < 50 {
            try await Task.sleep(nanoseconds: 100_000_000) // 100ms
            attempts += 1
        }
        
        guard isReady else {
            throw TestError.websocketConnectionFailed
        }
        
        print("✅ WebSocket ready, streaming audio...")
        
        // Stream audio in chunks
        let chunkSize = 32000 // 1 second at 16kHz
        var offset = 0
        var chunkCount = 0
        
        while offset < audioData.count {
            let end = min(offset + chunkSize, audioData.count)
            let chunk = audioData.subdata(in: offset..<end)
            
            try await task.send(.data(chunk))
            chunkCount += 1
            print("  Sent chunk \(chunkCount) (\(chunk.count) bytes)")
            
            offset = end
            
            // Small delay between chunks
            try await Task.sleep(nanoseconds: 50_000_000) // 50ms
        }
        
        print("✅ All audio sent (\(chunkCount) chunks)")
        
        // Don't close WebSocket - let finalize handle it
    }
    
    private func finalizeRecording(recordingId: String) async throws -> [String: Any] {
        print("\n2️⃣ Finalizing recording...")
        
        let url = URL(string: "\(serverURL)/api/v2/recordings/\(recordingId)/finalize")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw TestError.finalizationFailed("Invalid response")
        }
        
        print("✅ Finalized successfully")
        return json
    }
    
    private func getProcessedRecording(recordingId: String) async throws -> ProcessedRecording {
        print("\n3️⃣ Getting processed recording...")
        
        let url = URL(string: "\(serverURL)/api/v2/recordings/\(recordingId)")!
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw TestError.invalidResponse
        }
        
        return try JSONDecoder().decode(ProcessedRecording.self, from: data)
    }
    
    /// Generate test audio file with sine wave
    private func generateTestAudioFile() async throws -> Data {
        let sampleRate = 16000.0
        let duration = 3.0
        let frequency = 440.0
        
        var audioData = Data()
        let samples = Int(sampleRate * duration)
        
        for i in 0..<samples {
            let time = Double(i) / sampleRate
            let value = sin(2.0 * Double.pi * frequency * time) * 0.5
            let sample = Int16(value * Double(Int16.max))
            
            withUnsafeBytes(of: sample.littleEndian) { bytes in
                audioData.append(contentsOf: bytes)
            }
        }
        
        return audioData
    }
    
    /// Generate speech audio using AVSpeechSynthesizer
    private func generateSpeechAudio(text: String) async throws -> Data {
        return try await withCheckedThrowingContinuation { continuation in
            let synthesizer = AVSpeechSynthesizer()
            var audioData = Data()
            
            // Configure audio session
            let audioSession = AVAudioSession.sharedInstance()
            try? audioSession.setCategory(.playAndRecord, mode: .default)
            try? audioSession.setActive(true)
            
            // Create utterance
            let utterance = AVSpeechUtterance(string: text)
            utterance.rate = AVSpeechUtteranceDefaultSpeechRate
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
            
            // Set up audio buffer
            var audioFormat: AVAudioFormat?
            
            synthesizer.write(utterance) { buffer in
                guard let pcmBuffer = buffer as? AVAudioPCMBuffer,
                      pcmBuffer.frameLength > 0 else { 
                    // End of speech
                    if !audioData.isEmpty {
                        continuation.resume(returning: audioData)
                    } else {
                        continuation.resume(throwing: TestError.invalidResponse)
                    }
                    return
                }
                
                if audioFormat == nil {
                    audioFormat = pcmBuffer.format
                }
                
                // Convert to 16kHz mono PCM
                if let channelData = pcmBuffer.int16ChannelData {
                    let channelCount = Int(pcmBuffer.format.channelCount)
                    let frameLength = Int(pcmBuffer.frameLength)
                    
                    for frame in 0..<frameLength {
                        // Mix to mono if needed
                        var monoSample: Int16 = 0
                        for channel in 0..<channelCount {
                            monoSample += channelData[channel][frame] / Int16(channelCount)
                        }
                        
                        withUnsafeBytes(of: monoSample.littleEndian) { bytes in
                            audioData.append(contentsOf: bytes)
                        }
                    }
                }
            }
        }
    }
}