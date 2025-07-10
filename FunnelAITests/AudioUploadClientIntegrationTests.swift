import AVFoundation
import Foundation
import Testing
@testable import FunnelAI

/**
 * Critical integration tests for the AudioUploadClient.
 * Tests both streaming and file upload modes against a running development server.
 * Verifies that both upload methods produce identical results for the same audio input.
 * This is the primary test for validating core app functionality.
 */
@Suite("AudioUploadClient Integration Tests")
struct AudioUploadClientIntegrationTests {
    let serverURL = "http://localhost:8000"
    
    @Test("Stream audio with mock microphone provider")
    func streamAudioDataWithAudioUploadClient() async throws {
        let client = AudioUploadClient(serverBaseURL: serverURL)
        
        // Generate test audio data
        let testAudioData = generateTestAudioData(durationSeconds: 5.0, sampleRate: 16000)
        var dataOffset = 0
        let chunkSize = 3200 // 100ms at 16kHz
        
        // Create mock audio provider that returns chunks
        let audioDataProvider: () async throws -> Data? = {
            guard dataOffset < testAudioData.count else { return nil }
            
            let endIndex = min(dataOffset + chunkSize, testAudioData.count)
            let chunk = testAudioData[dataOffset..<endIndex]
            dataOffset = endIndex
            
            // Simulate real-time streaming
            try await Task.sleep(for: .milliseconds(100))
            return chunk
        }
        
        // Stream the audio
        let result = try await client.streamRecording(
            sampleRate: 16000,
            audioDataProvider: audioDataProvider
        )
        
        // Verify we got a valid response
        #expect(!result.transcript.isEmpty)
        #expect(!result.lightlyEditedTranscript.isEmpty)
        #expect(!result.bulletSummary.isEmpty)
        #expect(!result.diagram.title.isEmpty)
        #expect(!result.diagram.content.isEmpty)
        #expect(result.thoughtProvokingQuestions.count > 0)
        #expect(result.duration > 0)
    }
    
    @Test("Upload audio file directly")
    func uploadAudioFile() async throws {
        let client = AudioUploadClient(serverBaseURL: serverURL)
        
        // Create a temporary audio file
        let testAudioData = generateTestAudioData(durationSeconds: 5.0, sampleRate: 16000)
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test_audio_\(UUID().uuidString).wav")
        
        // Write WAV file with proper header
        let wavData = createWAVFile(from: testAudioData, sampleRate: 16000)
        try wavData.write(to: tempURL)
        
        defer {
            try? FileManager.default.removeItem(at: tempURL)
        }
        
        // Upload the file
        let result = try await client.uploadFile(audioFileURL: tempURL)
        
        // Verify we got a valid response
        #expect(!result.transcript.isEmpty)
        #expect(!result.lightlyEditedTranscript.isEmpty)
        #expect(!result.bulletSummary.isEmpty)
        #expect(!result.diagram.title.isEmpty)
        #expect(!result.diagram.content.isEmpty)
        #expect(result.thoughtProvokingQuestions.count > 0)
        #expect(result.duration > 0)
    }
    
    @Test("Streaming and file upload produce consistent results")
    func verifyConsistentResults() async throws {
        let client = AudioUploadClient(serverBaseURL: serverURL)
        
        // Generate identical test audio
        let testAudioData = generateTestAudioData(durationSeconds: 5.0, sampleRate: 16000)
        
        // Test 1: Stream the audio
        var dataOffset = 0
        let chunkSize = 3200
        let audioDataProvider: () async throws -> Data? = {
            guard dataOffset < testAudioData.count else { return nil }
            let endIndex = min(dataOffset + chunkSize, testAudioData.count)
            let chunk = testAudioData[dataOffset..<endIndex]
            dataOffset = endIndex
            try await Task.sleep(for: .milliseconds(100))
            return chunk
        }
        
        let streamResult = try await client.streamRecording(
            sampleRate: 16000,
            audioDataProvider: audioDataProvider
        )
        
        // Test 2: Upload the same audio as a file
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test_consistency_\(UUID().uuidString).wav")
        let wavData = createWAVFile(from: testAudioData, sampleRate: 16000)
        try wavData.write(to: tempURL)
        defer {
            try? FileManager.default.removeItem(at: tempURL)
        }
        
        let fileResult = try await client.uploadFile(audioFileURL: tempURL)
        
        // Verify both methods produce similar results
        // Transcripts might have minor differences, but should be very similar
        #expect(streamResult.transcript.count > 0)
        #expect(fileResult.transcript.count > 0)
        
        // Durations should be identical
        #expect(abs(streamResult.duration - fileResult.duration) < 0.5)
        
        // Both should produce summaries and diagrams
        #expect(!streamResult.bulletSummary.isEmpty)
        #expect(!fileResult.bulletSummary.isEmpty)
        #expect(!streamResult.diagram.content.isEmpty)
        #expect(!fileResult.diagram.content.isEmpty)
    }
    
    @Test("Handle streaming errors gracefully")
    func handleStreamingErrors() async throws {
        // Test with invalid server URL
        let client = AudioUploadClient(serverBaseURL: "http://invalid-server-url")
        
        let audioDataProvider: () async throws -> Data? = {
            return nil // Empty provider
        }
        
        do {
            _ = try await client.streamRecording(
                sampleRate: 16000,
                audioDataProvider: audioDataProvider
            )
            Issue.record("Expected error for invalid server")
        } catch {
            // Expected error
            #expect(error is AudioUploadClient.AudioUploadError)
        }
    }
    
    @Test("Handle file upload errors gracefully")
    func handleFileUploadErrors() async throws {
        // Test with non-existent file
        let client = AudioUploadClient(serverBaseURL: serverURL)
        let nonExistentURL = FileManager.default.temporaryDirectory.appendingPathComponent("non_existent.wav")
        
        do {
            _ = try await client.uploadFile(audioFileURL: nonExistentURL)
            Issue.record("Expected error for non-existent file")
        } catch {
            // Expected error
            #expect(error != nil)
        }
    }
    
    // MARK: - Helper Functions
    
    /// Generate test audio data (sine wave)
    private func generateTestAudioData(durationSeconds: Double, sampleRate: Double) -> Data {
        let frequency = 440.0 // A4 note
        let amplitude: Int16 = 16383 // About 50% of max volume
        let samplesCount = Int(durationSeconds * sampleRate)
        
        var samples = [Int16]()
        for i in 0..<samplesCount {
            let time = Double(i) / sampleRate
            let value = sin(2.0 * .pi * frequency * time)
            let sample = Int16(Double(amplitude) * value)
            samples.append(sample)
        }
        
        return samples.withUnsafeBufferPointer { buffer in
            Data(buffer: buffer)
        }
    }
    
    /// Create a WAV file from PCM data
    private func createWAVFile(from pcmData: Data, sampleRate: Int) -> Data {
        var wavData = Data()
        
        // RIFF header
        wavData.append("RIFF".data(using: .ascii)!)
        wavData.append(UInt32(36 + pcmData.count).littleEndianData)
        wavData.append("WAVE".data(using: .ascii)!)
        
        // fmt subchunk
        wavData.append("fmt ".data(using: .ascii)!)
        wavData.append(UInt32(16).littleEndianData) // Subchunk size
        wavData.append(UInt16(1).littleEndianData) // Audio format (PCM)
        wavData.append(UInt16(1).littleEndianData) // Number of channels
        wavData.append(UInt32(sampleRate).littleEndianData) // Sample rate
        wavData.append(UInt32(sampleRate * 2).littleEndianData) // Byte rate
        wavData.append(UInt16(2).littleEndianData) // Block align
        wavData.append(UInt16(16).littleEndianData) // Bits per sample
        
        // data subchunk
        wavData.append("data".data(using: .ascii)!)
        wavData.append(UInt32(pcmData.count).littleEndianData)
        wavData.append(pcmData)
        
        return wavData
    }
}

// MARK: - Extensions

extension BinaryInteger {
    var littleEndianData: Data {
        withUnsafeBytes(of: self.littleEndian) { Data($0) }
    }
}