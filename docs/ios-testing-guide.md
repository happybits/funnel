# iOS Testing Guide

This guide covers how to write and run tests for the Funnel iOS app, with a focus on making test output visible to automated tools and CI/CD systems.

## Running Tests

### Using the Makefile (Recommended)

```bash
# Run all tests
make test

# Run a specific test class
make test-class CLASS=SimplePrintTest

# Run a specific test method
make test-method TEST=SimplePrintTest/testSimplePrint
```

### Using xcodebuild directly

```bash
# Run all tests
xcodebuild test \
  -project FunnelAI.xcodeproj \
  -scheme FunnelAITests \
  -destination "platform=iOS Simulator,name=iPhone 16"

# Run specific test
xcodebuild test \
  -project FunnelAI.xcodeproj \
  -scheme FunnelAITests \
  -destination "platform=iOS Simulator,name=iPhone 16" \
  -only-testing:FunnelAITests/SimplePrintTest/testSimplePrint
```

## Writing Tests for Visibility

### The Challenge
Standard `print()` statements in tests are not captured in structured test results (xcresult bundles). This makes it difficult for automated tools to extract test output.

### The Solution: Use Assertions
Instead of relying on print statements, use XCTest assertions with descriptive messages. These messages are captured in test results and can be parsed by tools.

### Examples

#### Making Test Data Visible
```swift
func testDataProcessing() {
    let input = "Hello, World!"
    let result = processData(input)
    
    // Instead of: print("Result: \(result)")
    // Use an assertion with a descriptive message:
    XCTAssertEqual(result, "Expected Value", 
                   "Data processing result: '\(result)' for input: '\(input)'")
}
```

#### Debugging with Intentional Failures
When you need to see values during development:
```swift
func testDebugging() {
    let complexObject = createComplexObject()
    
    // Temporarily fail to see the value
    XCTFail("DEBUG: Object state: \(complexObject)")
}
```

#### Conditional Debugging
```swift
func testWithConditionalOutput() {
    let value = calculateValue()
    
    #if DEBUG
    // Only fails in debug builds
    if ProcessInfo.processInfo.environment["SHOW_TEST_VALUES"] != nil {
        XCTFail("DEBUG: Calculated value is \(value)")
    }
    #endif
    
    XCTAssertGreaterThan(value, 0)
}
```

## Parsing Test Results

### Using xcresulttool

After running tests, an `.xcresult` bundle is created. Parse it with:

```bash
# Get test summary
xcrun xcresulttool get test-results summary \
  --path TestOutput.xcresult \
  --format json

# Get all test results
xcrun xcresulttool get test-results tests \
  --path TestOutput.xcresult \
  --format json

# Get specific test details
xcrun xcresulttool get test-results test-details \
  --test-id "SimplePrintTest/testSimplePrint()" \
  --path TestOutput.xcresult \
  --format json
```

### Extracting Failure Messages
```bash
# Get failure messages with jq
xcrun xcresulttool get test-results tests \
  --path TestOutput.xcresult \
  --format json | \
  jq -r '.testNodes[].children[].children[].children[] | 
         select(.result=="Failed") | 
         .children[].name'
```

## Best Practices

1. **Use Descriptive Assertion Messages**: Include context about what was being tested and what the actual values were.

2. **Avoid print() for Important Output**: Use assertions instead to ensure output is captured.

3. **Use XCTContext for Grouping**: 
   ```swift
   XCTContext.runActivity(named: "Processing user data") { _ in
       // Test code here
   }
   ```

4. **Clean Up Result Bundles**: Remove old `.xcresult` bundles before running tests to avoid conflicts.

5. **Use Unique Result Bundle Names**: When running tests in parallel or in CI, use timestamps:
   ```bash
   -resultBundlePath "TestOutput-$(date +%Y%m%d-%H%M%S).xcresult"
   ```

## Alternative Logging Approaches

If you must use logging:

1. **NSLog**: Unlike `print()`, NSLog output might appear in system logs
   ```swift
   NSLog("Test output: %@", value)
   ```

2. **os.Logger** (iOS 14+):
   ```swift
   import os
   let logger = Logger(subsystem: "com.joya.funnel.tests", category: "TestOutput")
   logger.info("Test value: \(value)")
   ```

3. **File-based logging**: Write to a file that can be read after tests complete.

## CI/CD Integration

For CI/CD pipelines, always:
1. Specify `-resultBundlePath` to control where results are saved
2. Parse the xcresult bundle for pass/fail status and failure messages
3. Archive the xcresult bundle as a build artifact for debugging