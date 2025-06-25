import XCTest

final class AudioRecordingIntegrationTests: XCTestCase {
    var app: XCUIApplication!
    var mockServer: AudioStreamingMockServer!
    var audioEnvironment: AudioTestEnvironment!

    override func setUpWithError() throws {
        continueAfterFailure = false

        // Setup mock server
        mockServer = AudioStreamingMockServer()
        mockServer.startServer()

        // Setup audio test environment
        audioEnvironment = AudioTestEnvironment()
        audioEnvironment.setupTestAudioEnvironment()

        // Configure and launch app
        app = XCUIApplication()
        app.launchEnvironment["TEST_MODE"] = "1"
        app.launchEnvironment["STREAM_URL"] = "ws://localhost:8080"
        app.launch()
    }

    override func tearDownWithError() throws {
        mockServer.stopServer()
        audioEnvironment.cleanup()
        app = nil
    }

    func testCompleteAudioRecordingFlow() {
        // Grant microphone permission if needed
        addUIInterruptionMonitor(withDescription: "Microphone Permission") { alert in
            if alert.buttons["Allow"].exists {
                alert.buttons["Allow"].tap()
            } else if alert.buttons["OK"].exists {
                alert.buttons["OK"].tap()
            }
            return true
        }

        // Start synthetic audio generation using speech pattern for more realistic test
        audioEnvironment.generateSpeechPattern(duration: 10.0)

        // Look for the record button by its image name
        let recordButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'RecordBtn'")).firstMatch
        if !recordButton.exists {
            // Try finding by position if image recognition fails
            let recordButtonByPosition = app.buttons.element(boundBy: 0)
            XCTAssertTrue(recordButtonByPosition.waitForExistence(timeout: 5), "Record button should exist")
            recordButtonByPosition.tap()
        } else {
            recordButton.tap()
        }

        // Force permission dialog handling
        app.tap()

        // Verify recording state by looking for "Voice Recording" text
        let recordingIndicator = app.staticTexts["Voice Recording"]
        XCTAssertTrue(recordingIndicator.waitForExistence(timeout: 5), "Should show Voice Recording text")

        // Also verify the timer is shown (format: 00:00.00)
        let timerPredicate = NSPredicate(format: "label MATCHES %@", "\\d{2}:\\d{2}\\.\\d{2}")
        let timerText = app.staticTexts.matching(timerPredicate).firstMatch
        XCTAssertTrue(timerText.waitForExistence(timeout: 2), "Should show recording timer")

        // Verify streaming is active
        let streamingExpectation = XCTestExpectation(description: "Streaming active")
        mockServer.onAudioReceived = { data in
            if data.count > 1024 {
                streamingExpectation.fulfill()
            }
        }
        wait(for: [streamingExpectation], timeout: 10.0)

        // Record for a few seconds
        Thread.sleep(forTimeInterval: 3.0)

        // Stop recording - the same button changes to stop button
        let stopButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'StopRecordBtn'")).firstMatch
        if !stopButton.exists {
            // Try finding by position if image recognition fails
            let stopButtonByPosition = app.buttons.element(boundBy: 0)
            XCTAssertTrue(stopButtonByPosition.exists, "Stop button should exist during recording")
            stopButtonByPosition.tap()
        } else {
            stopButton.tap()
        }

        // Verify processing overlay appears with correct text
        let processingText = app.staticTexts["Processing - Hang tight!"]
        XCTAssertTrue(processingText.waitForExistence(timeout: 5), "Should show processing overlay")

        // Also check for progress indicator
        let progressIndicator = app.progressIndicators.firstMatch
        XCTAssertTrue(progressIndicator.exists, "Should show progress indicator")

        // Wait for processing to complete (overlay should disappear)
        let processingComplete = NSPredicate(format: "exists == false")
        expectation(for: processingComplete, evaluatedWith: processingText, handler: nil)
        waitForExpectations(timeout: 30, handler: nil)

        // Verify cards view appears - looking for the Summary card first
        let summaryText = app.staticTexts["Summary"]
        XCTAssertTrue(summaryText.waitForExistence(timeout: 5), "Summary card should appear after processing")

        // Look for bullet points (they start with "•")
        let bulletPoints = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "•"))
        XCTAssertGreaterThan(bulletPoints.count, 0, "Should have at least one bullet point")

        // Validate LLM-generated content in summary card
        validateBulletSummaryContent()

        // Swipe to next card (Diagram)
        let scrollView = app.scrollViews.firstMatch
        scrollView.swipeLeft()
        Thread.sleep(forTimeInterval: 0.5)

        // Verify diagram card exists
        let diagramElements = app.staticTexts.allElementsBoundByIndex
        var foundDiagramContent = false
        for element in diagramElements {
            if element.label.count > 10 &&
                !element.label.contains("Summary") &&
                !element.label.contains("•")
            {
                foundDiagramContent = true
                break
            }
        }
        XCTAssertTrue(foundDiagramContent, "Should find diagram content")

        // Swipe to transcript card
        scrollView.swipeLeft()
        Thread.sleep(forTimeInterval: 0.5)

        // Verify transcript content exists
        validateTranscriptContent()
    }

    func testRecordingWithoutAudioPermission() {
        // Deny microphone permission
        addUIInterruptionMonitor(withDescription: "Microphone Permission") { alert in
            if alert.buttons["Don't Allow"].exists {
                alert.buttons["Don't Allow"].tap()
            }
            return true
        }

        // Try to start recording
        let recordButton = app.buttons["recordButton"]
        XCTAssertTrue(recordButton.waitForExistence(timeout: 5))
        recordButton.tap()

        // Force permission dialog
        app.tap()

        // Verify error handling
        let errorAlert = app.alerts.firstMatch
        XCTAssertTrue(errorAlert.waitForExistence(timeout: 5), "Should show error alert")

        // Dismiss alert
        errorAlert.buttons["OK"].tap()
    }

    private func validateBulletSummaryContent() {
        // Get all text elements on screen
        let textElements = app.staticTexts.allElementsBoundByIndex
        var bulletPointsContent: [String] = []
        var foundSummaryTitle = false

        for textElement in textElements {
            let text = textElement.label

            // Check for Summary title
            if text == "Summary" {
                foundSummaryTitle = true
            }

            // Skip bullet markers themselves
            if text == "•" {
                continue
            }

            // Collect actual bullet content (text that appears after bullets)
            if text.count > 20 && !text.contains("Summary") && !text.contains("Voice Recording") {
                bulletPointsContent.append(text)
            }
        }

        XCTAssertTrue(foundSummaryTitle, "Should find Summary title")
        XCTAssertGreaterThan(bulletPointsContent.count, 0, "Should have at least one bullet point with content")

        // Validate content quality
        for content in bulletPointsContent {
            XCTAssertFalse(content.contains("no summary available"), "Should not show placeholder text")
            XCTAssertFalse(content.contains("Loading"), "Should not show loading text")
            XCTAssertFalse(content.contains("Error"), "Should not show error text")
        }

        // Verify total content length is substantial
        let totalContentLength = bulletPointsContent.reduce(0) { $0 + $1.count }
        XCTAssertGreaterThan(totalContentLength, 50, "Summary should contain substantial content")
    }

    private func validateTranscriptContent() {
        // Get all text elements on screen
        let textElements = app.staticTexts.allElementsBoundByIndex
        var transcriptContent = ""
        var foundTranscriptText = false

        for textElement in textElements {
            let text = textElement.label

            // Skip UI labels and look for actual transcript content
            if text.count > 50 &&
                !text.contains("Summary") &&
                !text.contains("•") &&
                !text.contains("Processing")
            {
                transcriptContent = text
                foundTranscriptText = true
                break
            }
        }

        XCTAssertTrue(foundTranscriptText, "Should find transcript content")
        XCTAssertGreaterThan(transcriptContent.count, 100, "Transcript should be substantial")

        // Verify it looks like actual transcribed speech
        let words = transcriptContent.split(separator: " ")
        XCTAssertGreaterThan(words.count, 10, "Transcript should contain multiple words")
    }
}

// MARK: - UI Test Extensions

extension XCUIElement {
    func waitForNonEmptyContent(timeout: TimeInterval = 30) -> Bool {
        let predicate = NSPredicate { [weak self] _, _ in
            guard let self = self else { return false }
            return self.exists && !self.label.isEmpty && self.label != "Loading..."
        }

        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)
        return XCTWaiter().wait(for: [expectation], timeout: timeout) == .completed
    }
}

extension XCUIElementQuery {
    func containingAnyText(_ texts: [String]) -> XCUIElementQuery {
        let predicates = texts.map {
            NSPredicate(format: "label CONTAINS[c] %@", $0)
        }
        let compoundPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: predicates)
        return matching(compoundPredicate)
    }
}
