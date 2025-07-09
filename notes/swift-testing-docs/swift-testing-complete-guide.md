# Swift Testing Framework - Complete Guide

This guide consolidates documentation about Apple's Swift Testing framework, introduced at WWDC 2024. Swift Testing is a modern, expressive testing framework designed specifically for Swift, offering significant improvements over XCTest.

## Table of Contents
1. [Overview & Key Features](#overview--key-features)
2. [Getting Started](#getting-started)
3. [Core Concepts](#core-concepts)
4. [Writing Tests](#writing-tests)
5. [Advanced Features](#advanced-features)
6. [Error Testing](#error-testing)
7. [Organization & Best Practices](#organization--best-practices)
8. [Migration from XCTest](#migration-from-xctest)
9. [Platform Support & Integration](#platform-support--integration)

## Overview & Key Features

Swift Testing is Apple's modern testing framework built specifically for Swift, providing:

### Key Advantages
- **Swift-First Design**: Built for Swift with full language feature support
- **Expressive API**: Clean, declarative syntax using macros
- **Parallel by Default**: Tests run concurrently for faster execution
- **Better Diagnostics**: `#expect` macro provides detailed failure information
- **Cross-Platform**: Works on Apple platforms, Linux, and Windows
- **Open Source**: Community-driven development

### Core Features
- Parameterized testing (run same test with multiple inputs)
- Native async/await support
- Flexible test organization with tags and traits
- Rich result presentation in Xcode
- Side-by-side compatibility with XCTest

## Getting Started

### Requirements
- Xcode 16 beta or later
- Swift 6.0 or later
- Compatible with existing XCTest suites

### Basic Setup
```swift
import Testing

@Test func myFirstTest() {
    let result = 2 + 2
    #expect(result == 4)
}
```

### Project Configuration
1. Create a test target (don't link tests to main executable)
2. Import the Testing framework
3. Start writing tests with `@Test` attribute

## Core Concepts

### The Four Building Blocks

#### 1. @Test Functions
```swift
@Test func videoShouldPlay() async {
    let video = Video(url: videoURL)
    await video.load()
    #expect(video.isReadyToPlay)
}

@Test("Video plays successfully") // Custom display name
func testVideoPlayback() { }
```

#### 2. Expectations
```swift
// Basic expectation
#expect(value == expectedValue)

// With custom message
#expect(items.count > 0, "Items should not be empty")

// Require (stops test if fails)
let config = try #require(loadConfiguration())
```

#### 3. Traits
```swift
@Test(.enabled(if: Platform.isSimulator))
func simulatorOnlyTest() { }

@Test(.tags(.critical, .networking))
func criticalNetworkTest() { }

@Test(.disabled("Under development"))
func futureFeature() { }
```

#### 4. Test Suites
```swift
@Suite("Video Player Tests")
struct VideoPlayerTests {
    @Test func playbackStarts() { }
    @Test func playbackPauses() { }
    
    @Suite("Fullscreen Tests")
    struct FullscreenTests {
        @Test func enterFullscreen() { }
        @Test func exitFullscreen() { }
    }
}
```

## Writing Tests

### Parameterized Testing
```swift
// Single parameter
@Test(arguments: [1, 2, 3, 5, 8, 13])
func testFibonacci(value: Int) {
    #expect(isFibonacci(value))
}

// Multiple parameters (all combinations)
@Test(arguments: ["Alice", "Bob"], [21, 35, 50])
func testUser(name: String, age: Int) {
    // Runs 6 times (2 names × 3 ages)
}

// Paired parameters
@Test(arguments: zip(inputs, expectedOutputs))
func testTransformation(input: String, expected: String) {
    #expect(transform(input) == expected)
}
```

### Async Testing
```swift
@Test func fetchData() async throws {
    let data = try await networkClient.fetch()
    #expect(data.count > 0)
}

// Testing with continuations for legacy APIs
@Test func legacyAPI() async {
    await withCheckedContinuation { continuation in
        oldStyleAPI { result in
            #expect(result != nil)
            continuation.resume()
        }
    }
}
```

### Using Tags for Organization
```swift
// Define custom tags
extension Tag {
    @Tag static var integration: Self
    @Tag static var unit: Self
    @Tag static var performance: Self
}

// Apply tags to tests
@Test(.tags(.integration, .performance))
func complexIntegrationTest() { }

// Run specific tags from command line
// swift test --filter tag:integration
```

## Advanced Features

### Confirmations (Multiple Callbacks)
```swift
@Test func multipleCallbacks() async {
    await confirmation("All updates received", expectedCount: 3) { confirm in
        service.onUpdate = { _ in confirm() }
        service.onError = { _ in confirm() }
        service.onComplete = { confirm() }
        service.start()
    }
}
```

### Known Issues
```swift
@Test func featureInDevelopment() {
    withKnownIssue("Not yet implemented - see JIRA-123") {
        #expect(newFeature.isWorking)
    }
}
```

### Serialized Execution
```swift
// Force sequential execution when needed
@Test(.serialized)
func databaseMigration() {
    // Tests in this suite run one at a time
}
```

### Test Timeouts
```swift
@Test(.timeLimit(.minutes(2)))
func longRunningTest() async {
    // Test must complete within 2 minutes
}
```

## Error Testing

### Basic Error Testing
```swift
// Test that error is thrown
#expect(throws: ValidationError.self) {
    try validate(invalidInput)
}

// Test specific error case
#expect(throws: ValidationError.tooShort) {
    try validate("")
}

// Test any error
#expect(throws: (any Error).self) {
    try riskyOperation()
}
```

### Advanced Error Validation
```swift
// Inspect thrown error
#expect {
    try parseJSON(malformed)
} throws: { error in
    guard let parseError = error as? ParseError else { return false }
    return parseError.line == 5 && parseError.column == 12
}

// Capture error for inspection (Swift 6.1+)
@Test func detailedErrorCheck() throws {
    let error = try #require(throws: NetworkError.self) {
        try performRequest()
    }
    #expect(error.statusCode == 404)
    #expect(error.retryable == false)
}
```

### Error Testing Best Practices
```swift
// Test both success and failure
@Test func validInput() throws {
    let result = try process("valid")
    #expect(result.isSuccess)
}

@Test func invalidInput() {
    #expect(throws: ProcessError.self) {
        try process("invalid")
    }
}

// Parameterized error testing
@Test(arguments: [
    ("", ValidationError.empty),
    ("ab", ValidationError.tooShort),
    ("a".repeating(101), ValidationError.tooLong)
])
func validation(input: String, expectedError: ValidationError) {
    #expect(throws: expectedError) {
        try validate(input)
    }
}
```

## Organization & Best Practices

### Test Structure
```swift
@Suite("Feature Tests")
struct FeatureTests {
    // Shared setup
    let testData = TestData()
    
    init() {
        // Suite initialization
    }
    
    @Suite("Component A")
    struct ComponentATests {
        @Test func basicFunctionality() { }
        @Test func edgeCases() { }
    }
    
    @Suite("Component B") 
    struct ComponentBTests {
        @Test func integration() { }
    }
}
```

### Best Practices

1. **Test Independence**: Each test should be self-contained
```swift
@Test func userCreation() {
    let db = Database() // Fresh instance
    let user = db.createUser("Alice")
    #expect(user.name == "Alice")
}
```

2. **Descriptive Names**: Use clear, descriptive test names
```swift
@Test("User receives welcome email after registration")
func welcomeEmail() { }
```

3. **Single Responsibility**: Test one behavior per test
```swift
// Good: Focused test
@Test func scoreIncreasesOnCorrectAnswer() {
    let game = Game()
    game.submitAnswer(.correct)
    #expect(game.score == 10)
}
```

4. **Use Parameterized Tests**: Reduce duplication
```swift
@Test(arguments: TestCases.all)
func calculate(testCase: TestCase) {
    let result = calculator.evaluate(testCase.input)
    #expect(result == testCase.expected)
}
```

5. **Leverage Parallel Execution**: Design thread-safe tests
```swift
// Each test gets its own instance
@Test func concurrentTest() {
    let service = Service() // Not shared
    // Test implementation
}
```

## Migration from XCTest

### Basic Migration Examples
```swift
// XCTest
class UserTests: XCTestCase {
    func testUserCreation() {
        let user = User(name: "Alice")
        XCTAssertEqual(user.name, "Alice")
        XCTAssertEqual(user.score, 0)
    }
}

// Swift Testing
struct UserTests {
    @Test func userCreation() {
        let user = User(name: "Alice")
        #expect(user.name == "Alice")
        #expect(user.score == 0)
    }
}
```

### Assertion Migration
```swift
// XCTest → Swift Testing
XCTAssertEqual(a, b)         → #expect(a == b)
XCTAssertTrue(condition)     → #expect(condition)
XCTAssertNil(value)          → #expect(value == nil)
XCTAssertThrowsError(...)    → #expect(throws: ...)
XCTAssertNoThrow(...)        → try expression (no wrapper needed)
XCTFail("message")           → Issue.record("message")
```

### Setup/Teardown Migration
```swift
// XCTest
override func setUp() {
    database = Database()
}

// Swift Testing - Use init or computed properties
struct DatabaseTests {
    let database = Database()
    // OR
    init() {
        // Setup code
    }
}
```

## Platform Support & Integration

### Supported Platforms
- **Apple**: iOS, macOS, tvOS, watchOS, visionOS
- **Linux**: Full support for server-side Swift
- **Windows**: Complete Windows platform support

### Xcode Integration
- Test navigator support
- Inline result visualization
- Re-run specific test iterations
- Rich failure diagnostics

### Command Line Usage
```bash
# Run all tests
swift test

# Run specific test
swift test --filter UserTests

# Run tests with specific tag
swift test --filter tag:critical

# Run in parallel (default)
swift test --parallel

# Generate coverage report
swift test --enable-code-coverage
```

### CI/CD Integration
- **Xcode Cloud**: Automatic discovery and parallel execution
- **GitHub Actions**: Use swift test in workflows
- **Custom CI**: Full command-line support

## Performance Tips

1. **Parallel by Default**: Tests run concurrently automatically
2. **Use `.serialized` Sparingly**: Only when truly needed
3. **Avoid Shared State**: Each test should be independent
4. **Profile Long Tests**: Use `.timeLimit` to catch slow tests
5. **Batch Similar Tests**: Use parameterized tests for variations

## Resources

- [Apple Documentation](https://developer.apple.com/documentation/testing)
- [WWDC24: Meet Swift Testing](https://developer.apple.com/videos/play/wwdc2024/10179/)
- [WWDC24: Go Further with Swift Testing](https://developer.apple.com/videos/play/wwdc2024/10195/)
- [Swift Testing GitHub](https://github.com/swiftlang/swift-testing)
- [Swift Forums](https://forums.swift.org) - Community support

## Summary

Swift Testing represents a significant evolution in testing for Apple platforms:
- More expressive and intuitive than XCTest
- Designed specifically for Swift's modern features
- Excellent performance through parallel execution
- Seamless migration path from existing tests
- Strong tooling support in Xcode and command line

Start by writing new tests in Swift Testing while keeping existing XCTest suites. Gradually migrate as you become comfortable with the new patterns and APIs.