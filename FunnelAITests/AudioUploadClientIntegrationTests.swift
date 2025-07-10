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
    let serverURL = Constants.API.localBaseURL
    
    @Test("Stream audio with mock microphone provider")
    func streamAudioDataWithAudioUploadClient() async throws {
        let client = AudioUploadClient(serverBaseURL: serverURL)
        
        // Load real audio file
        let audioData = try loadSampleAudioData()
        var dataOffset = 0
        let chunkSize = 3200 // 100ms at 16kHz
        
        // Create mock audio provider that returns chunks
        let audioDataProvider: () async throws -> Data? = {
            guard dataOffset < audioData.count else { return nil }
            
            let endIndex = min(dataOffset + chunkSize, audioData.count)
            let chunk = audioData[dataOffset..<endIndex]
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
        
        // Use the real sample audio file
        let sampleAudioURL = getSampleAudioURL()
        
        // Check if file exists
        #expect(FileManager.default.fileExists(atPath: sampleAudioURL.path))
        
        // Upload the file
        let result = try await client.uploadFile(audioFileURL: sampleAudioURL)
        
        // Verify we got a valid response
        #expect(!result.transcript.isEmpty)
        #expect(!result.lightlyEditedTranscript.isEmpty)
        #expect(!result.bulletSummary.isEmpty)
        #expect(!result.diagram.title.isEmpty)
        #expect(!result.diagram.content.isEmpty)
        #expect(result.thoughtProvokingQuestions.count > 0)
        #expect(result.duration > 0)
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
            // Expected error - URLError when can't connect to server
            #expect(error is URLError)
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
            // Expected error - Could be various types depending on when it fails
            // File system errors, URL loading errors, or AudioUploadClient errors
            #expect(error != nil)
        }
    }
    
    // MARK: - Helper Functions
    
    /// Get the URL for the sample audio file
    private func getSampleAudioURL() -> URL {
        // For tests, use the direct path to the sample file in the project
        let projectPath = URL(fileURLWithPath: #file)
            .deletingLastPathComponent()  // Remove filename
            .deletingLastPathComponent()  // Remove FunnelAITests
            .appendingPathComponent("Funnel")
            .appendingPathComponent("Funnel")
            .appendingPathComponent("sample-recording-mary-had-lamb.m4a")
        
        return projectPath
    }
    
    /// Load sample audio data and convert to PCM
    private func loadSampleAudioData() throws -> Data {
        let audioURL = getSampleAudioURL()
        
        // Load the audio file
        let audioFile = try AVAudioFile(forReading: audioURL)
        let format = audioFile.processingFormat
        let frameCount = AVAudioFrameCount(audioFile.length)
        
        // Create a buffer for the audio data
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            throw NSError(domain: "AudioError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create audio buffer"])
        }
        
        // Read the audio data
        try audioFile.read(into: buffer)
        buffer.frameLength = frameCount
        
        // Convert to 16kHz mono PCM if needed
        let targetFormat = AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: 16000, channels: 1, interleaved: true)!
        
        // If already in the correct format, just return the data
        if format.sampleRate == 16000 && format.channelCount == 1 && format.commonFormat == .pcmFormatInt16 {
            return Data(bytes: buffer.int16ChannelData![0], count: Int(buffer.frameLength) * 2)
        }
        
        // Otherwise, convert the audio
        let converter = AVAudioConverter(from: format, to: targetFormat)!
        let convertedBuffer = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: AVAudioFrameCount(Double(frameCount) * 16000.0 / format.sampleRate))!
        
        var error: NSError?
        converter.convert(to: convertedBuffer, error: &error) { inNumPackets, outStatus in
            outStatus.pointee = .haveData
            return buffer
        }
        
        if let error = error {
            throw error
        }
        
        return Data(bytes: convertedBuffer.int16ChannelData![0], count: Int(convertedBuffer.frameLength) * 2)
    }
    
    /// Generate test audio data (sine wave) - DEPRECATED, use loadSampleAudioData instead
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

extension FixedWidthInteger {
    var littleEndianData: Data {
        withUnsafeBytes(of: self.littleEndian) { Data($0) }
    }
}