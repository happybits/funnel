import Testing
import Foundation
@testable import FunnelAI

struct TestFileUploadEndpointSwiftTesting {
    let serverURL = "http://localhost:9000"
    
    @Test
    func fileUploadReturnsAllRequiredData() async throws {
        let bundle = Bundle(identifier: "co.happybits.FunnelAITests") ?? Bundle.main
        let audioURL = bundle.url(forResource: "sample-recording-mary-had-lamb", withExtension: "m4a")!
        let audioData = try Data(contentsOf: audioURL)
        
        var request = URLRequest(url: URL(string: "\(serverURL)/api/new-recording")!)
        request.httpMethod = "POST"
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"audio\"; filename=\"test.m4a\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/mp4\r\n\r\n".data(using: .utf8)!)
        body.append(audioData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        let (data, response) = try await URLSession.shared.data(for: request)
        let httpResponse = response as! HTTPURLResponse
        
        #expect(httpResponse.statusCode == 200, "Server should return 200 OK")
        
        let decoder = JSONDecoder()
        let processedRecording = try decoder.decode(ProcessedRecording.self, from: data)
        
        // Verify all required fields are present and non-empty
        #expect(!processedRecording.transcript.isEmpty, "Transcript should not be empty")
        #expect(!processedRecording.lightlyEditedTranscript.isEmpty, "Lightly edited transcript should not be empty")
        #expect(processedRecording.duration > 0, "Duration should be positive")
        #expect(!processedRecording.bulletSummary.isEmpty, "Bullet summary should not be empty")
        #expect(!processedRecording.diagram.title.isEmpty, "Diagram title should not be empty")
        #expect(!processedRecording.diagram.description.isEmpty, "Diagram description should not be empty")
        #expect(!processedRecording.diagram.content.isEmpty, "Diagram content should not be empty")
        #expect(!processedRecording.thoughtProvokingQuestions.isEmpty, "Should have at least one thought-provoking question")
        
        // Verify data quality
        #expect(processedRecording.bulletSummary.count >= 3 && processedRecording.bulletSummary.count <= 6,
                "Should have 3-6 bullet points")
        #expect(processedRecording.thoughtProvokingQuestions.count >= 3,
                "Should have at least 3 thought-provoking questions")
        
        // Verify lightly edited transcript removes filler words
        let fillerWords = ["um", "uh", "you know", "like"]
        let lightlyEditedLower = processedRecording.lightlyEditedTranscript.lowercased()
        for filler in fillerWords {
            #expect(!lightlyEditedLower.contains(filler),
                    "Lightly edited transcript should not contain '\(filler)'")
        }
    }
    
    @Test
    func fileUploadHandlesErrors() async throws {
        var request = URLRequest(url: URL(string: "\(serverURL)/api/new-recording")!)
        request.httpMethod = "POST"
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            let httpResponse = response as! HTTPURLResponse
            #expect(httpResponse.statusCode == 400, "Should return 400 for missing audio file")
        } catch {
            Issue.record("Request should complete with error status, not throw: \(error)")
        }
    }
}