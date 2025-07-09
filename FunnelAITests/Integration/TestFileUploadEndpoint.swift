import XCTest
@testable import FunnelAI

final class TestFileUploadEndpoint: XCTestCase {
    let serverURL = "http://localhost:9000"
    
    func testFileUploadReturnsAllRequiredData() async throws {
        let audioURL = Bundle(for: type(of: self)).url(forResource: "test_audio", withExtension: "m4a")!
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
        
        XCTAssertEqual(httpResponse.statusCode, 200, "Server should return 200 OK")
        
        let decoder = JSONDecoder()
        let processedRecording = try decoder.decode(ProcessedRecording.self, from: data)
        
        // Verify all required fields are present and non-empty
        XCTAssertFalse(processedRecording.transcript.isEmpty, "Transcript should not be empty")
        XCTAssertFalse(processedRecording.lightlyEditedTranscript.isEmpty, "Lightly edited transcript should not be empty")
        XCTAssertGreaterThan(processedRecording.duration, 0, "Duration should be positive")
        XCTAssertFalse(processedRecording.bulletSummary.isEmpty, "Bullet summary should not be empty")
        XCTAssertFalse(processedRecording.diagram.title.isEmpty, "Diagram title should not be empty")
        XCTAssertFalse(processedRecording.diagram.description.isEmpty, "Diagram description should not be empty")
        XCTAssertFalse(processedRecording.diagram.content.isEmpty, "Diagram content should not be empty")
        XCTAssertFalse(processedRecording.thoughtProvokingQuestions.isEmpty, "Should have at least one thought-provoking question")
        
        // Verify data quality
        XCTAssertTrue(processedRecording.bulletSummary.count >= 3 && processedRecording.bulletSummary.count <= 6, 
                      "Should have 3-6 bullet points")
        XCTAssertTrue(processedRecording.thoughtProvokingQuestions.count >= 3, 
                      "Should have at least 3 thought-provoking questions")
        
        // Verify lightly edited transcript removes filler words
        let fillerWords = ["um", "uh", "you know", "like"]
        let lightlyEditedLower = processedRecording.lightlyEditedTranscript.lowercased()
        for filler in fillerWords {
            XCTAssertFalse(lightlyEditedLower.contains(filler), 
                          "Lightly edited transcript should not contain '\(filler)'")
        }
    }
    
    func testFileUploadHandlesErrors() async throws {
        var request = URLRequest(url: URL(string: "\(serverURL)/api/new-recording")!)
        request.httpMethod = "POST"
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            let httpResponse = response as! HTTPURLResponse
            XCTAssertEqual(httpResponse.statusCode, 400, "Should return 400 for missing audio file")
        } catch {
            XCTFail("Request should complete with error status, not throw: \(error)")
        }
    }
}