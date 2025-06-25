# Funnel iOS Integration Tests

This directory contains integration tests for the Funnel audio recording app that verify the complete end-to-end flow without mocking.

## Test Architecture

The tests use real AVAudioRecorder functionality with virtual audio routing through BlackHole to simulate controlled audio input during automated testing.

### Key Components

1. **AudioRecordingIntegrationTests.swift** - Main test suite with complete recording flow tests
2. **AudioTestEnvironment.swift** - Manages virtual audio routing and synthetic audio generation
3. **MockWebSocketServer.swift** - Local WebSocket server for verifying streaming functionality
4. **LLMContentVerifier.swift** - Utilities for validating dynamic LLM-generated content

## Setup Requirements

### 1. Install BlackHole Audio Driver

BlackHole is required for routing audio during tests:

```bash
brew install blackhole-2ch
```

After installation:
1. Open System Preferences → Sound → Input
2. Select "BlackHole 2ch" as the input device
3. The iOS Simulator will automatically use this as its microphone

### 2. Configure Xcode Project

Add the UI test target to your project:

1. In Xcode, select File → New → Target
2. Choose "UI Testing Bundle" for iOS
3. Name it "FunnelUITests"
4. Add all test files from this directory to the target

### 3. Update Build Scheme

Ensure the test server URL is configured:

1. Edit your scheme in Xcode
2. Under Test → Arguments → Environment Variables
3. Add: `STREAM_URL = ws://localhost:8080`

## Running Tests

### Command Line

```bash
# Run all UI tests
xcodebuild test -scheme Funnel -destination 'platform=iOS Simulator,name=iPhone 15'

# Run specific test
xcodebuild test -scheme Funnel -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:FunnelUITests/AudioRecordingIntegrationTests/testCompleteAudioRecordingFlow
```

### In Xcode

1. Select the FunnelUITests scheme
2. Press Cmd+U to run all tests
3. Or click the diamond next to individual test methods

## Test Flow

The main integration test (`testCompleteAudioRecordingFlow`) performs these steps:

1. **Setup Phase**
   - Starts mock WebSocket server on port 8080
   - Configures BlackHole audio routing
   - Launches app with test environment variables

2. **Recording Phase**
   - Generates synthetic speech-like audio pattern
   - Taps record button
   - Handles microphone permission dialog
   - Verifies "Voice Recording" UI appears
   - Confirms audio streaming to server

3. **Processing Phase**
   - Stops recording after 3 seconds
   - Verifies "Processing - Hang tight!" overlay
   - Waits for server processing to complete

4. **Verification Phase**
   - Confirms Summary card appears with bullet points
   - Validates LLM-generated content (no placeholders)
   - Swipes to Diagram card and verifies content
   - Swipes to Transcript card and validates transcription

## Audio Simulation Options

### 1. Synthetic Tone Generation
```swift
audioEnvironment.generateTestTone(frequency: 440.0, duration: 10.0)
```

### 2. Speech Pattern Simulation
```swift
audioEnvironment.generateSpeechPattern(duration: 10.0)
```

### 3. Pre-recorded Audio File
```swift
audioEnvironment.playBundledTestAudio()
```

## Content Verification

Since LLM output varies, tests use pattern matching:

```swift
// Verify bullet points exist
let bullets = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "•"))
XCTAssertGreaterThan(bullets.count, 0)

// Check content quality
let verifier = LLMContentVerifier(app: app)
XCTAssertTrue(verifier.verifyBulletSummary())
```

## Troubleshooting

### BlackHole Not Working
- Ensure BlackHole is selected in System Preferences → Sound → Input
- Restart the iOS Simulator after changing audio input
- Try playing audio through BlackHole using QuickTime to test

### Tests Timing Out
- Increase timeout values in `waitForExistence(timeout:)`
- Check that the mock server is running on port 8080
- Verify the app's API endpoint is configured correctly

### Permission Dialogs Not Handled
- The test includes UI interruption monitors for permissions
- If failing, try adding explicit tap after record button press

### No Audio Received
- Check BlackHole volume is not muted
- Ensure synthetic audio generation is working
- Verify AVAudioSession configuration in the app

## Mock Server Endpoints

The mock WebSocket server simulates the real backend:

- Accepts WebSocket connections on `ws://localhost:8080`
- Receives binary audio data chunks
- Sends back mock transcription and processing results
- Validates audio data format and size

## Best Practices

1. **Run tests in isolation** - Each test should be independent
2. **Clean up resources** - Stop servers and audio in tearDown
3. **Use realistic timeouts** - Account for processing delays
4. **Verify incrementally** - Check each UI state transition
5. **Handle flakiness** - Add retries for network operations

## Continuous Integration

For CI environments without audio hardware:

1. Consider using a headless audio driver
2. Mock the audio input at a lower level
3. Focus on UI flow testing without audio verification
4. Run full audio tests on physical devices periodically