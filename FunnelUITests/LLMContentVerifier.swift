import XCTest

// Utility class for verifying LLM-generated content with flexible pattern matching
class LLMContentVerifier {
    
    private let app: XCUIApplication
    
    init(app: XCUIApplication) {
        self.app = app
    }
    
    // Verify bullet summary content with pattern matching
    func verifyBulletSummary(timeout: TimeInterval = 10) -> Bool {
        // Wait for Summary title
        let summaryTitle = app.staticTexts["Summary"]
        guard summaryTitle.waitForExistence(timeout: timeout) else {
            XCTFail("Summary title not found")
            return false
        }
        
        // Look for bullet points
        let bulletPredicate = NSPredicate(format: "label BEGINSWITH[c] %@", "•")
        let bullets = app.staticTexts.matching(bulletPredicate)
        
        if bullets.count == 0 {
            XCTFail("No bullet points found")
            return false
        }
        
        // Collect all text content
        var contentItems: [String] = []
        let allTexts = app.staticTexts.allElementsBoundByIndex
        
        for text in allTexts {
            let label = text.label
            if label.count > 20 && 
               !label.contains("Summary") && 
               !label.contains("•") &&
               !isSystemText(label) {
                contentItems.append(label)
            }
        }
        
        // Verify we have substantial content
        guard contentItems.count > 0 else {
            XCTFail("No substantial content found in bullet summary")
            return false
        }
        
        // Check content quality
        for content in contentItems {
            if containsPlaceholderText(content) {
                XCTFail("Found placeholder text: \(content)")
                return false
            }
        }
        
        return true
    }
    
    // Verify diagram content
    func verifyDiagramContent(timeout: TimeInterval = 5) -> Bool {
        // Swipe to diagram card
        let scrollView = app.scrollViews.firstMatch
        scrollView.swipeLeft()
        Thread.sleep(forTimeInterval: 0.5)
        
        // Look for diagram content patterns
        let diagramPatterns = [
            "diagram", "concept", "flow", "relationship", 
            "process", "structure", "visual", "representation"
        ]
        
        let allTexts = app.staticTexts.allElementsBoundByIndex
        var foundDiagramContent = false
        var diagramText = ""
        
        for text in allTexts {
            let label = text.label.lowercased()
            
            // Check if text contains diagram-related keywords
            for pattern in diagramPatterns {
                if label.contains(pattern) {
                    foundDiagramContent = true
                    diagramText = text.label
                    break
                }
            }
            
            // Also check for substantial content that's not from other cards
            if text.label.count > 30 && 
               !text.label.contains("Summary") && 
               !text.label.contains("•") &&
               !isSystemText(text.label) {
                foundDiagramContent = true
                diagramText = text.label
            }
        }
        
        if !foundDiagramContent {
            // Check for "No diagram available" text
            let noDiagramText = app.staticTexts["No diagram available"]
            if noDiagramText.exists {
                XCTFail("Diagram shows 'No diagram available' placeholder")
                return false
            }
        }
        
        return foundDiagramContent
    }
    
    // Verify transcript content
    func verifyTranscriptContent(timeout: TimeInterval = 5) -> Bool {
        // Swipe to transcript card
        let scrollView = app.scrollViews.firstMatch
        scrollView.swipeLeft()
        Thread.sleep(forTimeInterval: 0.5)
        
        // Look for transcript content
        let allTexts = app.staticTexts.allElementsBoundByIndex
        var transcriptText = ""
        var foundTranscript = false
        
        for text in allTexts {
            let label = text.label
            
            // Transcript should be the longest text block
            if label.count > 100 && 
               !label.contains("Summary") && 
               !label.contains("•") &&
               !isSystemText(label) {
                transcriptText = label
                foundTranscript = true
                break
            }
        }
        
        guard foundTranscript else {
            XCTFail("No transcript content found")
            return false
        }
        
        // Verify it looks like speech
        let words = transcriptText.split(separator: " ")
        guard words.count > 20 else {
            XCTFail("Transcript too short: \(words.count) words")
            return false
        }
        
        // Check for natural language patterns
        let hasCapitalization = transcriptText.range(of: "[A-Z]", options: .regularExpression) != nil
        let hasPunctuation = transcriptText.range(of: "[.!?,]", options: .regularExpression) != nil
        
        if !hasCapitalization || !hasPunctuation {
            XCTFail("Transcript doesn't appear to be natural language")
            return false
        }
        
        return true
    }
    
    // Helper to check if text is system/UI text
    private func isSystemText(_ text: String) -> Bool {
        let systemTexts = [
            "Voice Recording", "Processing", "Hang tight",
            "Allow", "Don't Allow", "OK", "Cancel",
            "Microphone", "Permission", "Error"
        ]
        
        for systemText in systemTexts {
            if text.contains(systemText) {
                return true
            }
        }
        
        return false
    }
    
    // Helper to check for placeholder text
    private func containsPlaceholderText(_ text: String) -> Bool {
        let placeholders = [
            "no summary available",
            "no content",
            "loading",
            "error",
            "failed",
            "unavailable",
            "placeholder",
            "lorem ipsum",
            "sample text",
            "test content"
        ]
        
        let lowercased = text.lowercased()
        for placeholder in placeholders {
            if lowercased.contains(placeholder) {
                return true
            }
        }
        
        return false
    }
    
    // Analyze content with basic NLP heuristics
    func analyzeContentQuality(text: String) -> ContentQuality {
        let words = text.split(separator: " ")
        let sentences = text.split { ".!?".contains($0) }
        
        // Basic quality metrics
        let wordCount = words.count
        let avgWordLength = words.reduce(0) { $0 + $1.count } / max(words.count, 1)
        let sentenceCount = sentences.count
        let hasVariedVocabulary = Set(words).count > wordCount / 3
        
        // Determine quality
        if wordCount < 10 || avgWordLength < 3 {
            return .poor
        } else if wordCount < 30 || !hasVariedVocabulary {
            return .fair
        } else if wordCount > 50 && sentenceCount > 2 && hasVariedVocabulary {
            return .excellent
        } else {
            return .good
        }
    }
    
    enum ContentQuality {
        case poor
        case fair
        case good
        case excellent
    }
}

// Extension for pattern-based content matching
extension XCUIElementQuery {
    func containingPattern(_ pattern: String) -> XCUIElementQuery {
        let predicate = NSPredicate(format: "label MATCHES[c] %@", pattern)
        return matching(predicate)
    }
    
    func notContaining(_ text: String) -> XCUIElementQuery {
        let predicate = NSPredicate(format: "NOT (label CONTAINS[c] %@)", text)
        return matching(predicate)
    }
}