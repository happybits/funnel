import Testing
import Foundation
@testable import FunnelAI

struct TestServerResponseParsingSwiftTesting {
    
    @Test func completeResponseParsing() throws {
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
        
        #expect(response.transcript == "This is a test transcript with some content")
        #expect(response.lightlyEditedTranscript == "This is a test transcript with some content")
        #expect(abs(response.duration - 45.5) < 0.01)
        #expect(response.bulletSummary.count == 3)
        #expect(response.bulletSummary[0] == "First key point from the transcript")
        #expect(response.diagram.title == "Test Diagram")
        #expect(response.diagram.description == "A visual representation of the content")
        #expect(response.diagram.content.contains("graph TD"))
        #expect(response.thoughtProvokingQuestions.count == 3)
    }
    
    @Test func missingOptionalFields() throws {
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
        
        #expect(response.transcript == "Minimal transcript")
        #expect(response.bulletSummary.count == 1)
        #expect(response.thoughtProvokingQuestions.isEmpty)
    }
    
    @Test func malformedJSON() {
        let malformedCases = [
            """
            {
                "transcript": "Test",
                "duration": 10.0,
                "bulletSummary": ["Point"]
            }
            """,
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
        
        for malformed in malformedCases {
            let data = malformed.data(using: .utf8)!
            
            #expect(throws: (any Error).self) {
                try decoder.decode(ProcessedRecording.self, from: data)
            }
        }
    }
    
    @Test func edgeCases() throws {
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
        
        let response = try decoder.decode(ProcessedRecording.self, from: data)
        
        #expect(response.transcript.isEmpty)
        #expect(response.duration == 0.0)
        #expect(response.bulletSummary.isEmpty)
        #expect(response.diagram.title.isEmpty)
    }
    
    @Test func largeResponse() throws {
        var bullets = [String]()
        var questions = [String]()
        
        for i in 1...6 {
            bullets.append("This is bullet point number \(i) with some substantial content")
        }
        
        for i in 1...5 {
            questions.append("Question \(i): What about this aspect of the discussion?")
        }
        
        let transcriptPart = "This is a long transcript. "
        let transcriptContent = String(repeating: transcriptPart, count: 100)
        
        let diagramPart = "graph TD\\n  A --> B\\n"
        let diagramContent = String(repeating: diagramPart, count: 50)
        
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
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let encodedData = try encoder.encode(processedRecording)
        
        let decoder = JSONDecoder()
        let response = try decoder.decode(ProcessedRecording.self, from: encodedData)
        
        #expect(response.transcript.count > 2000)
        #expect(response.bulletSummary.count == 6)
        #expect(response.thoughtProvokingQuestions.count == 5)
        #expect(response.diagram.content.contains("graph TD"))
        
        #expect(response.transcript == transcriptContent)
        #expect(abs(response.duration - 300.5) < 0.01)
        #expect(response.diagram.title == "Complex System Architecture")
    }
}