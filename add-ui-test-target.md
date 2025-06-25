# Adding UI Test Target to Xcode Project

To complete the UI test setup, you need to manually add a UI test target in Xcode:

## Steps:

1. **Open the project in Xcode**:
   ```bash
   open FunnelAI.xcodeproj
   ```

2. **Add New Target**:
   - Go to File → New → Target...
   - Select "UI Testing Bundle" under iOS
   - Click Next

3. **Configure the Target**:
   - Product Name: `FunnelUITests`
   - Team: `6L379HCV5Q` (your team ID)
   - Bundle Identifier: `com.funnel.FunnelUITests`
   - Language: Swift
   - Target to be Tested: `FunnelAI`
   - Click Finish

4. **Update Target Settings**:
   - Select the FunnelUITests target
   - Go to Build Phases → Copy Bundle Resources
   - Remove any default test files that were created
   - The test files we created (`FunnelUITests.swift` and `FunnelUITestsLaunchTests.swift`) should be automatically included

5. **Run the Tests**:
   - Use the test script: `./run-ui-tests.sh`
   - Or in Xcode: Product → Test (⌘U)

## Test Files Created:

- `FunnelUITests/FunnelUITests.swift` - Main test file with recording flow tests
- `FunnelUITests/FunnelUITestsLaunchTests.swift` - Launch performance tests
- `run-ui-tests.sh` - Script to run tests from command line

## Features Implemented:

### 1. Test Mode in AudioRecorderManager
- Added `isTestMode` property that checks for `--ui-testing` launch argument
- `startTestRecording()` method that copies sample audio file instead of real recording
- Simulates audio levels during "recording"

### 2. API Client Test Support
- Checks `API_BASE_URL` environment variable for custom test server
- Allows pointing to local server for testing

### 3. UI Accessibility Identifiers
- Added identifiers to key UI elements:
  - "Start Recording" / "Stop Recording" buttons
  - "CardsView" container
  - "BulletSummaryCard", "DiagramCard", "TranscriptCard"

### 4. Test Cases
- `testCompleteRecordingFlow()` - Tests the full recording to cards flow
- `testRecordingCancellation()` - Tests canceling a recording
- `verifyCardContent()` - Validates card content is not empty

## Running Tests

### Option 1: Command Line
```bash
# Run against production API
./run-ui-tests.sh

# Run against local server
TEST_API_URL=http://localhost:8000 ./run-ui-tests.sh
```

### Option 2: Xcode
1. Select the FunnelUITests scheme
2. Choose a simulator
3. Press ⌘U or Product → Test

## Next Steps

To add LLM-based content verification:
1. Create a test endpoint that accepts card content
2. Use Claude API to verify content quality
3. Add to `verifyCardContent()` method

The test infrastructure is now ready for comprehensive UI testing!