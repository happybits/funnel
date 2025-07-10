import AVFoundation
@testable import FunnelAI
import Testing
import Foundation

enum TestError: Error {
    case fileNotFound
}

/// Integration test for DeepgramClient
struct DeepgramClientTestsSwiftTesting {
    let client: DeepgramClient
    let testAudioURL: URL
    
    init() throws {
        // Initialize client
        client = DeepgramClient(serverBaseURL: Constants.API.localBaseURL)
        
        // Get test audio file from the test bundle
        let bundle = Bundle(identifier: "co.happybits.FunnelAITests") ?? Bundle.main
        guard let url = bundle.url(
            forResource: "sample-recording-mary-had-lamb",
            withExtension: "m4a"
        ) else {
            Issue.record("Could not find test audio file 'sample-recording-mary-had-lamb.m4a' in test bundle")
            throw TestError.fileNotFound
        }
        
        testAudioURL = url
        print("📦 Using audio file from test bundle: \(url)")
    }
    
    /// Test streaming audio data using DeepgramClient
    @Test
    func streamAudioDataWithDeepgramClient() async throws {
        print("\n🎤 === DEEPGRAM CLIENT AUDIO STREAMING TEST START ===")
        
        // Load audio data (convertToPCM converts to 16kHz)
        let audioFile = try AVAudioFile(forReading: testAudioURL)
        let pcmData = try audioFile.convertToPCM()
        print("🎵 Loaded \(pcmData.count) bytes of PCM data at 16kHz")
        
        // Create a custom provider that streams in smaller chunks
        let chunkSize = 8000 // 0.5 seconds at 16kHz
        var offset = 0
        var chunkCount = 0
        
        // Stream with explicit sample rate of 16000 Hz to match our converted audio
        let processedRecording = try await client.streamRecording(sampleRate: 16000) {
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
        
        // Verify the results
        print("\n🎯 === PROCESSED RECORDING ===")
        print("Total chunks sent: \(chunkCount)")
        print("Duration: \(processedRecording.duration) seconds")
        print("Full transcript: \"\(processedRecording.transcript)\"")
        print("Lightly edited transcript: \"\(processedRecording.lightlyEditedTranscript)\"")
        print("Bullet summary (\(processedRecording.bulletSummary.count) items):")
        for (index, bullet) in processedRecording.bulletSummary.enumerated() {
            print("  \(index + 1). \(bullet)")
        }
        print("Diagram title: \(processedRecording.diagram.title)")
        print("Diagram description: \(processedRecording.diagram.description)")
        print("=========================\n")
        
        // Assertions
        #expect(processedRecording.duration > 0, "Duration should be greater than 0")
        #expect(!processedRecording.transcript.isEmpty, "Transcript should not be empty")
        #expect(!processedRecording.lightlyEditedTranscript.isEmpty, "Lightly edited transcript should not be empty")
        #expect(processedRecording.transcript != processedRecording.lightlyEditedTranscript, "Lightly edited transcript should differ from raw transcript")
        #expect(!processedRecording.bulletSummary.isEmpty, "Bullet summary should not be empty")
        #expect(!processedRecording.diagram.title.isEmpty, "Diagram title should not be empty")
        #expect(!processedRecording.diagram.description.isEmpty, "Diagram description should not be empty")
        #expect(!processedRecording.diagram.content.isEmpty, "Diagram content should not be empty")
        
        // Verify transcript contains expected content
        let transcriptLower = processedRecording.transcript.lowercased()
        #expect(
            transcriptLower.contains("mary") || transcriptLower.contains("lamb"),
            "Transcript should contain words from Mary Had a Little Lamb"
        )
        
        print("✅ DeepgramClient test completed successfully!")
    }
}