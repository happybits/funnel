import XCTest
@testable import FunnelAI

final class TestServerResponseParsing: XCTestCase {
    
    func testCompleteResponseParsing() throws {
        let json = """
        {
            "transcript": "This is a test transcript with some content",
            "lightlyEditedTranscript": "This is a test transcript with some content",
            "duration": 45.5,
            "bulletSummary": [
                "First key point from the transcript",
                "Second important insight",
                "Third takeaway message"
            ],
            "diagram": {
                "title": "Test Diagram",
                "description": "A visual representation of the content",
                "content": "graph TD\\n  A[Start] --> B[Process]\\n  B --> C[End]"
            },
            "thoughtProvokingQuestions": [
                "What implications does this have?",
                "How might this apply to other contexts?",
                "What are the potential challenges?"
            ]
        }
        """
        
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        
        let response = try decoder.decode(ProcessedRecording.self, from: data)
        
        XCTAssertEqual(response.transcript, "This is a test transcript with some content")
        XCTAssertEqual(response.lightlyEditedTranscript, "This is a test transcript with some content")
        XCTAssertEqual(response.duration, 45.5, accuracy: 0.01)
        XCTAssertEqual(response.bulletSummary.count, 3)
        XCTAssertEqual(response.bulletSummary[0], "First key point from the transcript")
        XCTAssertEqual(response.diagram.title, "Test Diagram")
        XCTAssertEqual(response.diagram.description, "A visual representation of the content")
        XCTAssertTrue(response.diagram.content.contains("graph TD"))
        XCTAssertEqual(response.thoughtProvokingQuestions.count, 3)
    }
    
    func testMissingOptionalFields() throws {
        // Test minimal valid response
        let json = """
        {
            "transcript": "Minimal transcript",
            "lightlyEditedTranscript": "Minimal transcript",
            "duration": 10.0,
            "bulletSummary": ["Single point"],
            "diagram": {
                "title": "Simple",
                "description": "Basic diagram",
                "content": "A -> B"
            },
            "thoughtProvokingQuestions": []
        }
        """
        
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        
        let response = try decoder.decode(ProcessedRecording.self, from: data)
        
        XCTAssertEqual(response.transcript, "Minimal transcript")
        XCTAssertEqual(response.bulletSummary.count, 1)
        XCTAssertTrue(response.thoughtProvokingQuestions.isEmpty)
    }
    
    func testMalformedJSON() {
        let malformedCases = [
            // Missing required field
            """
            {
                "transcript": "Test",
                "duration": 10.0,
                "bulletSummary": ["Point"]
            }
            """,
            // Wrong type for duration
            """
            {
                "transcript": "Test",
                "lightlyEditedTranscript": "Test",
                "duration": "not a number",
                "bulletSummary": ["Point"],
                "diagram": {
                    "title": "Test",
                    "description": "Test",
                    "content": "Test"
                },
                "thoughtProvokingQuestions": []
            }
            """,
            // bulletSummary not an array
            """
            {
                "transcript": "Test",
                "lightlyEditedTranscript": "Test",
                "duration": 10.0,
                "bulletSummary": "Should be an array",
                "diagram": {
                    "title": "Test",
                    "description": "Test",
                    "content": "Test"
                },
                "thoughtProvokingQuestions": []
            }
            """
        ]
        
        let decoder = JSONDecoder()
        
        for (index, malformed) in malformedCases.enumerated() {
            let data = malformed.data(using: .utf8)!
            
            XCTAssertThrowsError(try decoder.decode(ProcessedRecording.self, from: data),
                                "Malformed case \(index) should throw decoding error")
        }
    }
    
    func testEdgeCases() throws {
        let json = """
        {
            "transcript": "",
            "lightlyEditedTranscript": "",
            "duration": 0.0,
            "bulletSummary": [],
            "diagram": {
                "title": "",
                "description": "",
                "content": ""
            },
            "thoughtProvokingQuestions": []
        }
        """
        
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        
        // Should parse without throwing
        let response = try decoder.decode(ProcessedRecording.self, from: data)
        
        XCTAssertTrue(response.transcript.isEmpty)
        XCTAssertEqual(response.duration, 0.0)
        XCTAssertTrue(response.bulletSummary.isEmpty)
        XCTAssertTrue(response.diagram.title.isEmpty)
    }
    
    func testLargeResponse() throws {
        // Test with realistic large content
        var bullets = [String]()
        var questions = [String]()
        
        for i in 1...6 {
            bullets.append("This is bullet point number \(i) with some substantial content")
        }
        
        for i in 1...5 {
            questions.append("Question \(i): What about this aspect of the discussion?")
        }
        
        // Create large content in a more memory-efficient way
        let transcriptPart = "This is a long transcript. "
        let transcriptContent = String(repeating: transcriptPart, count: 100)
        
        let diagramPart = "graph TD\\n  A --> B\\n"
        let diagramContent = String(repeating: diagramPart, count: 50)
        
        // Build JSON using JSONEncoder to avoid string interpolation issues
        let processedRecording = ProcessedRecording(
            transcript: transcriptContent,
            lightlyEditedTranscript: transcriptContent,
            duration: 300.5,
            bulletSummary: bullets,
            diagram: ProcessedRecording.DiagramData(
                title: "Complex System Architecture",
                description: "A detailed view of the system components and their interactions",
                content: diagramContent
            ),
            thoughtProvokingQuestions: questions
        )
        
        // First encode to verify the object can be encoded
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let encodedData = try encoder.encode(processedRecording)
        
        // Now decode it back to test the decoding
        let decoder = JSONDecoder()
        let response = try decoder.decode(ProcessedRecording.self, from: encodedData)
        
        // Verify the decoded data
        XCTAssertTrue(response.transcript.count > 2000, "Transcript should be longer than 2000 characters")
        XCTAssertEqual(response.bulletSummary.count, 6, "Should have 6 bullet points")
        XCTAssertEqual(response.thoughtProvokingQuestions.count, 5, "Should have 5 questions")
        XCTAssertTrue(response.diagram.content.contains("graph TD"), "Diagram should contain 'graph TD'")
        
        // Additional checks for data integrity
        XCTAssertEqual(response.transcript, transcriptContent, "Transcript content should match")
        XCTAssertEqual(response.duration, 300.5, accuracy: 0.01, "Duration should match")
        XCTAssertEqual(response.diagram.title, "Complex System Architecture", "Diagram title should match")
    }
}