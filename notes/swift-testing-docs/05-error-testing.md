# Testing for Errors in Swift Code

This guide covers error testing patterns and best practices using the Swift Testing framework introduced at WWDC24.

## Overview

The Swift Testing framework provides powerful and expressive APIs for testing error-throwing functions through the `#expect` macro. This modern approach replaces XCTest's error handling patterns with more intuitive and flexible methods.

## Basic Error Testing Syntax

### 1. Testing That a Function Throws

The simplest way to test that a function throws an error:

```swift
@Test func testThrowingFunction() {
    #expect(throws: (any Error).self) {
        try functionThatShouldThrow()
    }
}
```

### 2. Testing for Specific Error Types

To verify that a specific error type is thrown:

```swift
@Test func errorIsThrownForIncorrectInput() {
    let input = -1
    #expect(throws: ValidationError.self, "Values less than 0 should throw an error") {
        try checkInput(input)
    }
}
```

### 3. Testing for Exact Error Cases

When you need to verify the exact error case:

```swift
@Test func testSpecificErrorCase() {
    #expect(throws: ValidationError.valueTooSmall) {
        try checkInput(-5)
    }
}
```

## Advanced Error Testing Patterns

### 1. Inspecting Thrown Errors

For complex error validation, use the closure-based syntax:

```swift
@Test func testDetailedErrorValidation() {
    let input = -1
    #expect {
        try checkInput(input)
    } throws: { error in 
        guard let validationError = error as? ValidationError else {
            return false
        }
        
        switch validationError {
        case .valueTooSmall(let margin) where margin == 1:
            return true
        default:
            return false
        }
    }
}
```

### 2. Error Verification with Additional Checks

You can perform additional validations after verifying an error:

```swift
@Test func testErrorWithSideEffects() {
    var errorLogged = false
    let errorLogger = ErrorLogger { _ in
        errorLogged = true
    }
    
    #expect(throws: NetworkError.self) {
        try fetchData(with: errorLogger)
    }
    
    #expect(errorLogged == true, "Error should be logged")
}
```

### 3. Using #require with Errors (Swift 6.1+)

With Swift 6.1, you can capture and inspect the thrown error:

```swift
@Test func testErrorDetails() throws {
    let error = try #require(throws: CustomError.self) {
        try performOperation()
    }
    
    // Now you can inspect the error
    #expect(error.code == 404)
    #expect(error.message.contains("Not Found"))
}
```

## Best Practices

### 1. Avoid do-catch in Tests

Instead of using do-catch blocks, rely on `#expect` for cleaner test code:

```swift
// ❌ Avoid this pattern
@Test func testWithDoCatch() throws {
    do {
        try functionThatShouldThrow()
        Issue.record("Expected function to throw")
    } catch {
        // Verify error
    }
}

// ✅ Use this instead
@Test func testWithExpect() {
    #expect(throws: ExpectedError.self) {
        try functionThatShouldThrow()
    }
}
```

### 2. Provide Descriptive Messages

Always include meaningful messages for better test output:

```swift
@Test func testWithDescriptiveMessage() {
    #expect(
        throws: ValidationError.self,
        "Empty string should throw validation error"
    ) {
        try validate("")
    }
}
```

### 3. Test Both Success and Failure Paths

Ensure comprehensive coverage by testing both throwing and non-throwing scenarios:

```swift
@Test func testValidInput() throws {
    // Should not throw
    let result = try checkInput(5)
    #expect(result == true)
}

@Test func testInvalidInput() {
    // Should throw
    #expect(throws: ValidationError.self) {
        try checkInput(-1)
    }
}
```

### 4. Use Parameterized Tests for Multiple Error Cases

Test multiple error scenarios efficiently:

```swift
@Test(arguments: [
    (-1, ValidationError.valueTooSmall),
    (101, ValidationError.valueTooLarge),
    (nil, ValidationError.missingValue)
])
func testMultipleErrorCases(input: Int?, expectedError: ValidationError) {
    #expect(throws: expectedError) {
        try validateRange(input)
    }
}
```

## Common Patterns

### Testing Async Throwing Functions

```swift
@Test func testAsyncThrowingFunction() async {
    #expect(throws: NetworkError.self) {
        try await fetchDataFromAPI()
    }
}
```

### Testing Functions That Shouldn't Throw

```swift
@Test func testNonThrowingFunction() throws {
    // If this throws, the test will automatically fail
    let result = try safeOperation()
    #expect(result != nil)
}
```

### Combining Error Testing with Other Assertions

```swift
@Test func testComplexScenario() {
    var cleanup = false
    
    defer {
        #expect(cleanup == true, "Cleanup should run even after error")
    }
    
    #expect(throws: DatabaseError.self) {
        cleanup = true
        try database.performInvalidOperation()
    }
}
```

## Migration from XCTest

When migrating from XCTest to Swift Testing:

```swift
// XCTest pattern
func testError() {
    XCTAssertThrowsError(try parseJSON("invalid")) { error in
        XCTAssertEqual(error as? ParsingError, ParsingError.invalidFormat)
    }
}

// Swift Testing pattern
@Test func testError() {
    #expect(throws: ParsingError.invalidFormat) {
        try parseJSON("invalid")
    }
}
```

## Key Takeaways

1. **Use `#expect` for all error assertions** - It provides a cleaner, more expressive API than traditional patterns
2. **Be specific about expected errors** - Test for exact error types or cases when possible
3. **Leverage closure-based validation** - For complex error checking scenarios
4. **Include descriptive messages** - Help future developers understand test intentions
5. **Test comprehensively** - Cover both success and failure paths
6. **Avoid do-catch in tests** - Let the testing framework handle error management

The Swift Testing framework's error handling capabilities make it easier to write clear, maintainable tests that effectively verify error conditions in your code.