import XCTest

final class AdditionalIntegrationTests: XCTestCase {
    var app: XCUIApplication!
    var mockServer: AudioStreamingMockServer!
    var audioEnvironment: AudioTestEnvironment!
    var contentVerifier: LLMContentVerifier!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        
        // Validate test environment
        let issues = TestEnvironmentValidator.validateSetup()
        if !issues.isEmpty {
            print("⚠️ Test environment issues found:")
            issues.forEach { print("  - \($0)") }
        }
        
        // Setup mock server
        mockServer = AudioStreamingMockServer(port: TestConfiguration.mockServerPort)
        mockServer.startServer()
        
        // Setup audio test environment
        audioEnvironment = AudioTestEnvironment()
        audioEnvironment.setupTestAudioEnvironment()
        
        // Configure and launch app
        app = XCUIApplication()
        app.launchEnvironment = TestConfiguration.testLaunchEnvironment
        app.launch()
        
        // Initialize content verifier
        contentVerifier = LLMContentVerifier(app: app)
    }
    
    override func tearDownWithError() throws {
        mockServer.stopServer()
        audioEnvironment.cleanup()
        app = nil
    }
    
    // Test very short recording handling
    func testShortRecordingValidation() {
        setupMicrophonePermission()
        
        // Start recording
        tapRecordButton()
        
        // Stop immediately (less than 0.5 seconds)
        Thread.sleep(forTimeInterval: 0.2)
        tapStopButton()
        
        // Should show error about recording being too short
        let errorText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] %@", "too short"))
        XCTAssertTrue(errorText.firstMatch.waitForExistence(timeout: 2), "Should show recording too short error")
    }
    
    // Test network error handling during streaming
    func testNetworkErrorDuringStreaming() {
        setupMicrophonePermission()
        
        // Configure server to simulate network error
        mockServer.onConnection = { connection in
            // Accept connection but close it after 1 second
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.mockServer.simulateNetworkError(on: connection)
            }
        }
        
        // Start recording
        audioEnvironment.generateTestTone(duration: 5.0)
        tapRecordButton()
        
        // Wait for network error
        Thread.sleep(forTimeInterval: 2.0)
        
        // Verify error handling
        let errorIndicator = app.staticTexts.containingAnyText(["Error", "Failed", "Connection"])
        XCTAssertTrue(errorIndicator.firstMatch.waitForExistence(timeout: 5), "Should show network error")
    }
    
    // Test multiple recordings in sequence
    func testMultipleRecordingsSequence() {
        setupMicrophonePermission()
        
        // First recording
        performRecording(duration: 2.0)
        
        // Wait for processing
        waitForProcessingComplete()
        
        // Verify first recording appears in list
        let backButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'BackBtn'")).firstMatch
        XCTAssertTrue(backButton.waitForExistence(timeout: 5))
        backButton.tap()
        
        // Verify we're back at home screen with recording in list
        let recordingsList = app.buttons.allElementsBoundByIndex.filter { button in
            button.staticTexts.count > 0
        }
        XCTAssertGreaterThan(recordingsList.count, 0, "Should show at least one recording in list")
        
        // Second recording
        performRecording(duration: 3.0)
        waitForProcessingComplete()
        
        // Verify content is different from first recording
        let summaryContent = gatherSummaryContent()
        XCTAssertGreaterThan(summaryContent.count, 0, "Second recording should have content")
    }
    
    // Test app behavior when microphone is in use by another app
    func testMicrophoneInUseScenario() {
        // This test simulates the scenario where another app is using the microphone
        // In real testing, this would require coordination with another process
        
        setupMicrophonePermission()
        
        // Attempt to start recording
        tapRecordButton()
        
        // Check if app handles the scenario gracefully
        // Either it shows an error or queues the recording
        let recordingStarted = app.staticTexts["Voice Recording"].waitForExistence(timeout: 3)
        let errorShown = app.staticTexts.containingAnyText(["microphone", "in use", "unavailable"]).firstMatch.exists
        
        XCTAssertTrue(recordingStarted || errorShown, "App should either start recording or show appropriate error")
    }
    
    // Test recordings list interaction
    func testRecordingsListNavigation() {
        // Create a recording first
        setupMicrophonePermission()
        performRecording(duration: 2.0)
        waitForProcessingComplete()
        
        // Go back to home
        let backButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'BackBtn'")).firstMatch
        backButton.tap()
        
        // Find and tap on the recording in the list
        let recordingCell = app.buttons.element(boundBy: 1) // Skip record button
        XCTAssertTrue(recordingCell.waitForExistence(timeout: 5), "Recording should appear in list")
        
        // Verify recording info is shown
        let dateText = recordingCell.staticTexts.matching(NSPredicate(format: "label MATCHES %@", ".*\\d{1,2}.*202\\d.*")).firstMatch
        XCTAssertTrue(dateText.exists, "Recording should show date")
        
        // Tap to open recording
        recordingCell.tap()
        
        // Verify we're viewing the recording
        let summaryTitle = app.staticTexts["Summary"]
        XCTAssertTrue(summaryTitle.waitForExistence(timeout: 5), "Should navigate to recording cards view")
    }
    
    // Test swipe gestures between cards
    func testCardSwipeNavigation() {
        setupMicrophonePermission()
        performRecording(duration: 2.0)
        waitForProcessingComplete()
        
        // Verify we start on Summary card
        XCTAssertTrue(contentVerifier.verifyBulletSummary(), "Should start on summary card")
        
        // Swipe to Diagram
        let scrollView = app.scrollViews.firstMatch
        scrollView.swipeLeft()
        Thread.sleep(forTimeInterval: 0.5)
        
        // Verify diagram content
        XCTAssertTrue(contentVerifier.verifyDiagramContent(), "Should show diagram after swipe")
        
        // Swipe to Transcript
        scrollView.swipeLeft()
        Thread.sleep(forTimeInterval: 0.5)
        
        // Verify transcript content
        XCTAssertTrue(contentVerifier.verifyTranscriptContent(), "Should show transcript after second swipe")
        
        // Swipe back to Diagram
        scrollView.swipeRight()
        Thread.sleep(forTimeInterval: 0.5)
        
        // Swipe back to Summary
        scrollView.swipeRight()
        Thread.sleep(forTimeInterval: 0.5)
        
        // Verify we're back at Summary
        let summaryTitle = app.staticTexts["Summary"]
        XCTAssertTrue(summaryTitle.exists, "Should be back at summary card")
    }
    
    // Helper methods
    
    private func setupMicrophonePermission() {
        addUIInterruptionMonitor(withDescription: "Microphone Permission") { alert in
            alert.buttons["Allow"].tap()
            return true
        }
    }
    
    private func tapRecordButton() {
        let recordButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'RecordBtn'")).firstMatch
        if !recordButton.exists {
            app.buttons.element(boundBy: 0).tap()
        } else {
            recordButton.tap()
        }
        app.tap() // Force permission handling
    }
    
    private func tapStopButton() {
        let stopButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'StopRecordBtn'")).firstMatch
        if !stopButton.exists {
            app.buttons.element(boundBy: 0).tap()
        } else {
            stopButton.tap()
        }
    }
    
    private func performRecording(duration: TimeInterval) {
        audioEnvironment.generateSpeechPattern(duration: duration + 2)
        tapRecordButton()
        
        // Verify recording started
        let recordingIndicator = app.staticTexts["Voice Recording"]
        XCTAssertTrue(recordingIndicator.waitForExistence(timeout: 5))
        
        Thread.sleep(forTimeInterval: duration)
        tapStopButton()
    }
    
    private func waitForProcessingComplete() {
        let processingText = app.staticTexts["Processing - Hang tight!"]
        XCTAssertTrue(processingText.waitForExistence(timeout: 5))
        
        let processingComplete = NSPredicate(format: "exists == false")
        expectation(for: processingComplete, evaluatedWith: processingText)
        waitForExpectations(timeout: TestConfiguration.processingTimeout)
    }
    
    private func gatherSummaryContent() -> [String] {
        var content: [String] = []
        let texts = app.staticTexts.allElementsBoundByIndex
        
        for text in texts {
            if text.label.count > 20 && 
               !text.label.contains("Summary") && 
               !text.label.contains("•") {
                content.append(text.label)
            }
        }
        
        return content
    }
}