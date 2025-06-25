import XCTest

final class FunnelUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false

        app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]

        // Optional: set test server URL if needed
        if let testAPIURL = ProcessInfo.processInfo.environment["TEST_API_URL"] {
            app.launchEnvironment["API_BASE_URL"] = testAPIURL
        }
    }

    override func tearDownWithError() throws {
        app = nil
    }

    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }

    func testCompleteRecordingFlow() throws {
        // Launch the app
        app.launch()

        // 1. Verify home screen
        let startRecordingButton = app.buttons["Start Recording"]
        XCTAssertTrue(startRecordingButton.waitForExistence(timeout: 5), "Start Recording button should exist")

        // 2. Start recording
        startRecordingButton.tap()

        // 3. Wait for recording view
        let stopRecordingButton = app.buttons["Stop Recording"]
        XCTAssertTrue(stopRecordingButton.waitForExistence(timeout: 3), "Stop Recording button should appear")

        // 4. Let it "record" for a few seconds (simulated recording)
        Thread.sleep(forTimeInterval: 3)

        // 5. Stop recording
        stopRecordingButton.tap()

        // 6. Verify processing overlay appears
        let processingText = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Processing'")).element
        XCTAssertTrue(processingText.waitForExistence(timeout: 3), "Processing indicator should appear")

        // 7. Wait for cards view (increase timeout as API processing can take time)
        let cardsView = app.otherElements["CardsView"]
        XCTAssertTrue(cardsView.waitForExistence(timeout: 30), "Cards view should appear after processing")

        // 8. Verify card content
        verifyCardContent()
    }

    func testRecordingCancellation() throws {
        app.launch()

        // Start recording
        let startButton = app.buttons["Start Recording"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 5))
        startButton.tap()

        // Cancel recording (if there's a cancel button)
        if app.buttons["Cancel"].exists {
            app.buttons["Cancel"].tap()

            // Should return to home screen
            XCTAssertTrue(startButton.waitForExistence(timeout: 3), "Should return to home screen after cancellation")
        }
    }

    // MARK: - Helper Methods

    private func verifyCardContent() {
        // Wait for cards to be rendered
        Thread.sleep(forTimeInterval: 1)

        // Check transcript card
        let transcriptCard = app.otherElements["TranscriptCard"]
        if transcriptCard.exists {
            // Verify transcript has content (not "No transcript available")
            let noTranscriptText = transcriptCard.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'no transcript'")).element
            XCTAssertFalse(noTranscriptText.exists, "Transcript should have content")

            // Verify there's some text content
            let transcriptTexts = transcriptCard.staticTexts
            XCTAssertTrue(transcriptTexts.count > 0, "Transcript should contain text")
        }

        // Check bullet summary card
        let bulletCard = app.otherElements["BulletSummaryCard"]
        if bulletCard.exists {
            // Verify summary has content (not "No summary available")
            let noSummaryText = bulletCard.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'no summary'")).element
            XCTAssertFalse(noSummaryText.exists, "Summary should have content")

            // Verify there are bullet points
            let bulletTexts = bulletCard.staticTexts
            XCTAssertTrue(bulletTexts.count > 0, "Summary should contain bullet points")
        }

        // Check diagram card
        let diagramCard = app.otherElements["DiagramCard"]
        if diagramCard.exists {
            // Verify diagram has content
            let noDiagramText = diagramCard.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'no diagram'")).element
            XCTAssertFalse(noDiagramText.exists, "Diagram should have content")
        }

        // Verify swipe functionality
        // Try swiping to next card
        if transcriptCard.exists {
            transcriptCard.swipeLeft()
            Thread.sleep(forTimeInterval: 0.5)

            // Verify we moved to a different card
            XCTAssertTrue(bulletCard.exists || diagramCard.exists, "Should be able to swipe between cards")
        }
    }
}
