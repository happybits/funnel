# Migrating from XCTest to Swift Testing

**Documentation Source**: [Apple Developer - Migrating a test from XCTest](https://developer.apple.com/documentation/Testing/MigratingFromXCTest)  
**Topic**: Migration Guide from XCTest to Swift Testing

## Overview

This guide provides comprehensive instructions for migrating existing XCTest-based tests to the new Swift Testing framework. Swift Testing offers modern Swift-first design, better error messages, and full async/await support while maintaining compatibility with existing XCTest code during migration.

## Migration Steps

### 1. Import the Testing Module

Replace XCTest imports with the Testing module:

```swift
// Before
import XCTest

// After
import Testing
```

**Note**: A single file can import both modules during migration to support mixed test content.

### 2. Convert Test Classes to Suites

Transform XCTestCase subclasses into Swift types (preferably structs):

```swift
// Before
class FoodTruckTests: XCTestCase {
  ...
}

// After
struct FoodTruckTests {
  ...
}
```

**Best Practice**: Use structs instead of classes for better concurrency safety and to avoid shared mutable state.

### 3. Convert Setup and Teardown

Replace `setUp()` and `tearDown()` with `init()` and `deinit`:

```swift
// Before
class FoodTruckTests: XCTestCase {
  var batteryLevel: NSNumber!
  override func setUp() async throws {
    batteryLevel = 100
  }
  override func tearDown() {
    batteryLevel = 0
  }
}

// After
final class FoodTruckTests {
  var batteryLevel: NSNumber
  init() async throws {
    batteryLevel = 100
  }
  deinit {
    batteryLevel = 0
  }
}
```

**Note**: Use classes or actors (not structs) if you need `deinit` for teardown logic.

### 4. Convert Test Methods

Replace test method naming convention with `@Test` attribute:

```swift
// Before
func testEngineWorks() { ... }

// After
@Test func engineWorks() { ... }
```

**Important**: XCTest runs synchronous tests on the main actor by default, while Swift Testing runs on arbitrary tasks. Use `@MainActor` if main thread execution is required.

## Assertion Migration

### Basic Assertions

Replace XCTAssert functions with `#expect` and `#require`:

```swift
// Before
func testEngineWorks() throws {
  let engine = FoodTruck.shared.engine
  XCTAssertNotNil(engine.parts.first)
  XCTAssertGreaterThan(engine.batteryLevel, 0)
  try engine.start()
  XCTAssertTrue(engine.isRunning)
}

// After
@Test func engineWorks() throws {
  let engine = FoodTruck.shared.engine
  try #require(engine.parts.first != nil)
  #expect(engine.batteryLevel > 0)
  try engine.start()
  #expect(engine.isRunning)
}
```

### Assertion Conversion Table

| XCTest | Swift Testing |
|--------|---------------|
| `XCTAssert(x)`, `XCTAssertTrue(x)` | `#expect(x)` |
| `XCTAssertFalse(x)` | `#expect(!x)` |
| `XCTAssertNil(x)` | `#expect(x == nil)` |
| `XCTAssertNotNil(x)` | `#expect(x != nil)` |
| `XCTAssertEqual(x, y)` | `#expect(x == y)` |
| `XCTAssertNotEqual(x, y)` | `#expect(x != y)` |
| `XCTAssertIdentical(x, y)` | `#expect(x === y)` |
| `XCTAssertNotIdentical(x, y)` | `#expect(x !== y)` |
| `XCTAssertGreaterThan(x, y)` | `#expect(x > y)` |
| `XCTAssertLessThan(x, y)` | `#expect(x < y)` |
| `XCTAssertThrowsError(try f())` | `#expect(throws: (any Error).self) { try f() }` |
| `XCTAssertNoThrow(try f())` | `#expect(throws: Never.self) { try f() }` |
| `try XCTUnwrap(x)` | `try #require(x)` |
| `XCTFail("...")` | `Issue.record("...")` |

### Optional Unwrapping

Use `#require` to unwrap optionals:

```swift
// Before
let part = try XCTUnwrap(engine.parts.first)

// After
let part = try #require(engine.parts.first)
```

## Advanced Migration Topics

### Asynchronous Testing

Replace XCTestExpectation with Confirmations:

```swift
// Before
func testTruckEvents() async {
  let soldFood = expectation(description: "...")
  FoodTruck.shared.eventHandler = { event in
    if case .soldFood = event {
      soldFood.fulfill()
    }
  }
  await Customer().buy(.soup)
  await fulfillment(of: [soldFood])
}

// After
@Test func truckEvents() async {
  await confirmation("...") { soldFood in
    FoodTruck.shared.eventHandler = { event in
      if case .soldFood = event {
        soldFood()
      }
    }
    await Customer().buy(.soup)
  }
}
```

### Conditional Test Execution

Replace `XCTSkip` with trait annotations:

```swift
// Before
func testArepasAreTasty() throws {
  try XCTSkipIf(CashRegister.isEmpty)
  try XCTSkipUnless(FoodTruck.sells(.arepas))
  ...
}

// After
@Suite(.disabled(if: CashRegister.isEmpty))
struct FoodTruckTests {
  @Test(.enabled(if: FoodTruck.sells(.arepas)))
  func arepasAreTasty() {
    ...
  }
}
```

### Known Issues

Replace `XCTExpectFailure` with `withKnownIssue`:

```swift
// Before
func testGrillWorks() async {
  XCTExpectFailure("Grill is out of fuel") {
    try FoodTruck.shared.grill.start()
  }
}

// After
@Test func grillWorks() async {
  withKnownIssue("Grill is out of fuel") {
    try FoodTruck.shared.grill.start()
  }
}
```

For intermittent issues:

```swift
// Before
XCTExpectFailure("Grill may need fuel", options: .nonStrict()) {
  try FoodTruck.shared.grill.start()
}

// After
withKnownIssue("Grill may need fuel", isIntermittent: true) {
  try FoodTruck.shared.grill.start()
}
```

### Serial Test Execution

Add `.serialized` trait to run tests sequentially:

```swift
// Before (XCTest runs sequentially by default)
class RefrigeratorTests : XCTestCase {
  func testLightComesOn() throws { ... }
  func testLightGoesOut() throws { ... }
}

// After (Swift Testing runs in parallel by default)
@Suite(.serialized)
class RefrigeratorTests {
  @Test func lightComesOn() throws { ... }
  @Test func lightGoesOut() throws { ... }
}
```

### Attachments

Convert XCTAttachment to Attachment:

```swift
// Before
func testTortillaIntegrity() async {
  let tortilla = Tortilla(diameter: .large)
  let attachment = XCTAttachment(archivableObject: tortilla)
  self.add(attachment)
}

// After
@Test func tortillaIntegrity() async {
  let tortilla = Tortilla(diameter: .large)
  Attachment.record(tortilla)
}
```

## Migration Best Practices

1. **Gradual Migration**: Swift Testing works alongside XCTest, allowing incremental migration
2. **Use Structs**: Prefer structs for test suites to avoid shared state issues
3. **Leverage Swift Concurrency**: Use async/await instead of XCTestExpectation where possible
4. **Descriptive Names**: Remove "test" prefix and use descriptive function names
5. **Use Traits**: Take advantage of traits for test organization and conditional execution
6. **Parameterized Testing**: Use parameterized tests to reduce code duplication

## Key Differences Summary

| Feature | XCTest | Swift Testing |
|---------|--------|---------------|
| Test Declaration | `func testX()` | `@Test func x()` |
| Suite Type | Class inheriting `XCTestCase` | Any Swift type with `@Suite` |
| Setup/Teardown | `setUp()`/`tearDown()` | `init()`/`deinit` |
| Assertions | `XCTAssert*` functions | `#expect` and `#require` macros |
| Async Support | Limited | Full async/await support |
| Parallel Execution | Sequential by default | Parallel by default |
| Platform Support | Apple platforms primarily | Cross-platform |

## Compatibility Notes

- Requires Swift 6.0 or later
- Works alongside existing XCTest code
- Can run both XCTest and Swift Testing tests in the same test suite
- Full support in Xcode 16

## Related Resources

- [Meet Swift Testing WWDC Session](https://developer.apple.com/videos/play/wwdc2024/10179/)
- [Go Further with Swift Testing WWDC Session](https://developer.apple.com/videos/play/wwdc2024/10195/)
- [Swift Testing GitHub Repository](https://github.com/apple/swift-testing)
- [Swift Testing Documentation](https://developer.apple.com/documentation/testing)