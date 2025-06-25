import Foundation

// Test configuration and environment setup
enum TestConfiguration {
    // Server configuration
    static let mockServerPort: UInt16 = 8080
    static let mockServerURL = "ws://localhost:\(mockServerPort)"

    // Timeouts
    static let recordButtonTimeout: TimeInterval = 5
    static let recordingStateTimeout: TimeInterval = 5
    static let processingTimeout: TimeInterval = 30
    static let contentLoadTimeout: TimeInterval = 10
    static let networkTimeout: TimeInterval = 10

    // Audio configuration
    static let defaultRecordingDuration: TimeInterval = 3.0
    static let audioToneFrequency: Float = 440.0
    static let speechPatternDuration: Double = 10.0

    // Content validation
    static let minimumBulletPoints = 1
    static let minimumContentLength = 50
    static let minimumTranscriptWords = 20

    // Launch environment
    static var testLaunchEnvironment: [String: String] {
        return [
            "TEST_MODE": "1",
            "STREAM_URL": mockServerURL,
            "SKIP_ONBOARDING": "1",
            "LOG_LEVEL": "DEBUG",
        ]
    }

    // Check if running in test mode
    static var isTestMode: Bool {
        return ProcessInfo.processInfo.environment["TEST_MODE"] == "1"
    }

    // Audio test mode helpers
    static func configureForBlackHole() {
        print("""
        ⚠️ BlackHole Audio Setup Required:
        1. Install: brew install blackhole-2ch
        2. System Preferences → Sound → Input
        3. Select "BlackHole 2ch" as input device
        4. Restart iOS Simulator if needed
        """)
    }
}

// Test data helpers
extension TestConfiguration {
    // Sample transcript for mock responses
    static let sampleTranscript = """
    So I've been thinking about how we could improve the user experience of our audio recording app. 
    The main idea is to make it more intuitive for users to start recording their thoughts without 
    having to navigate through multiple screens. We could implement a one-tap recording feature that 
    immediately starts capturing audio. Additionally, I think we should add visual feedback during 
    recording, like a waveform display, to show users that their audio is being captured properly. 
    Another important aspect would be to process the audio in real-time and provide immediate 
    transcription results.
    """

    // Sample bullet points for mock responses
    static let sampleBulletPoints = [
        "Implement one-tap recording feature for immediate audio capture",
        "Add visual waveform feedback during recording to confirm audio capture",
        "Process audio in real-time for faster transcription results",
        "Simplify navigation by reducing the number of screens",
        "Focus on intuitive user experience for thought capture",
    ]

    // Sample diagram for mock responses
    static let sampleDiagram = (
        title: "Audio Recording Flow",
        description: "User journey from recording to transcription",
        content: "User Tap → Start Recording → Visual Feedback → Stop Recording → Processing → Results Display"
    )
}

// Environment setup validator
class TestEnvironmentValidator {
    static func validateSetup() -> [String] {
        var issues: [String] = []

        // Check if BlackHole is available (this is a simplified check)
        if !isBlackHoleConfigured() {
            issues.append("BlackHole audio driver not detected - audio simulation may not work")
        }

        // Check if test mode is enabled
        if !TestConfiguration.isTestMode {
            issues.append("TEST_MODE environment variable not set")
        }

        // Check network availability for mock server
        if !isPortAvailable(TestConfiguration.mockServerPort) {
            issues.append("Port \(TestConfiguration.mockServerPort) may be in use - mock server might fail to start")
        }

        return issues
    }

    private static func isBlackHoleConfigured() -> Bool {
        // This is a placeholder - actual implementation would check system audio configuration
        // For now, we'll just check if the test is running in simulator
        #if targetEnvironment(simulator)
            return true
        #else
            return false
        #endif
    }

    private static func isPortAvailable(_: UInt16) -> Bool {
        // Simple port availability check
        // In real implementation, would attempt to bind to the port
        return true
    }
}
