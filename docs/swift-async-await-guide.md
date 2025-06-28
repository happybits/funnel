# Swift Async/Await Migration Guide

## Overview
Swift's async/await syntax (introduced in Swift 5.5) provides a modern, clean way to handle asynchronous operations. This guide covers how to use async/await effectively and migrate from callback-based code.

## Core Concepts

### 1. Async Functions
```swift
// Old callback style
func fetchData(completion: @escaping (Result<Data, Error>) -> Void) {
    // async work...
}

// New async/await style
func fetchData() async throws -> Data {
    // async work...
}
```

### 2. Calling Async Functions
```swift
// Must be called from async context
Task {
    do {
        let data = try await fetchData()
        // use data
    } catch {
        // handle error
    }
}
```

### 3. Error Handling
```swift
// Async functions that can fail use 'throws'
func riskyOperation() async throws -> String {
    // might throw an error
}

// Call with try/catch
do {
    let result = try await riskyOperation()
} catch {
    print("Error: \(error)")
}
```

## Converting Callbacks to Async/Await

### Using Continuations
Swift provides continuation APIs to bridge callback-based code:

#### CheckedContinuation (recommended)
```swift
func oldCallbackAPI(completion: @escaping (Result<String, Error>) -> Void) {
    // existing callback implementation
}

// Bridge to async/await
func modernAPI() async throws -> String {
    try await withCheckedThrowingContinuation { continuation in
        oldCallbackAPI { result in
            switch result {
            case .success(let value):
                continuation.resume(returning: value)
            case .failure(let error):
                continuation.resume(throwing: error)
            }
        }
    }
}
```

#### Simple Callback Without Errors
```swift
func simpleCallback(completion: @escaping (String) -> Void) {
    // callback implementation
}

// Bridge to async
func simpleAsync() async -> String {
    await withCheckedContinuation { continuation in
        simpleCallback { value in
            continuation.resume(returning: value)
        }
    }
}
```

### Important Continuation Rules
1. **Resume exactly once**: Each continuation must be resumed exactly once
2. **Don't capture continuations**: Never store continuations for later use
3. **Use CheckedContinuation in debug**: Helps catch programming errors

## Task Management

### Creating Tasks
```swift
// Unstructured task (detached)
Task {
    await doAsyncWork()
}

// Task with priority
Task(priority: .high) {
    await urgentWork()
}

// Task that returns a value
let task = Task { () -> String in
    return await fetchString()
}
let result = await task.value
```

### Task Cancellation
```swift
let task = Task {
    for i in 0..<100 {
        // Check for cancellation
        try Task.checkCancellation()
        
        // Or manually check
        if Task.isCancelled {
            break
        }
        
        await processItem(i)
    }
}

// Cancel the task
task.cancel()
```

## Actors and Thread Safety

### MainActor
```swift
@MainActor
class ViewModel: ObservableObject {
    @Published var data: String = ""
    
    // Automatically runs on main thread
    func updateUI() {
        data = "Updated"
    }
}

// Call from background
Task {
    await viewModel.updateUI()
}
```

### Custom Actors
```swift
actor DataCache {
    private var cache: [String: Data] = [:]
    
    func store(key: String, data: Data) {
        cache[key] = data
    }
    
    func retrieve(key: String) -> Data? {
        cache[key]
    }
}
```

## Real-World Examples

### Example 1: Network Request
```swift
// Old way
func fetchUser(id: String, completion: @escaping (Result<User, Error>) -> Void) {
    URLSession.shared.dataTask(with: url) { data, response, error in
        if let error = error {
            completion(.failure(error))
            return
        }
        // parse data...
        completion(.success(user))
    }.resume()
}

// New way
func fetchUser(id: String) async throws -> User {
    let (data, _) = try await URLSession.shared.data(from: url)
    return try JSONDecoder().decode(User.self, from: data)
}
```

### Example 2: Sequential Operations
```swift
// Old way - callback hell
fetchUser { userResult in
    switch userResult {
    case .success(let user):
        fetchPosts(for: user.id) { postsResult in
            switch postsResult {
            case .success(let posts):
                updateUI(user: user, posts: posts)
            case .failure(let error):
                showError(error)
            }
        }
    case .failure(let error):
        showError(error)
    }
}

// New way - clean and linear
Task {
    do {
        let user = try await fetchUser()
        let posts = try await fetchPosts(for: user.id)
        await updateUI(user: user, posts: posts)
    } catch {
        await showError(error)
    }
}
```

### Example 3: Parallel Operations
```swift
// Run multiple async operations in parallel
Task {
    async let user = fetchUser()
    async let settings = fetchSettings()
    async let notifications = fetchNotifications()
    
    // Wait for all to complete
    let (userData, userSettings, userNotifications) = try await (user, settings, notifications)
}
```

## Migration Strategy for AudioRecorderManager

### Current Callback-Based Code
```swift
func requestMicrophonePermission(completion: @escaping (Bool) -> Void)
func startRecording(completion: @escaping (Result<URL, Error>) -> Void)
func startLiveStreaming(completion: @escaping (Result<Void, Error>) -> Void)
```

### Migrated Async/Await Versions
```swift
func requestMicrophonePermission() async -> Bool {
    await withCheckedContinuation { continuation in
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            continuation.resume(returning: granted)
        }
    }
}

func startRecording() async throws -> URL {
    try await withCheckedThrowingContinuation { continuation in
        startRecordingInternal { result in
            switch result {
            case .success(let url):
                continuation.resume(returning: url)
            case .failure(let error):
                continuation.resume(throwing: error)
            }
        }
    }
}

func startLiveStreaming() async throws {
    try await withCheckedThrowingContinuation { continuation in
        startLiveStreamingInternal { result in
            switch result {
            case .success:
                continuation.resume()
            case .failure(let error):
                continuation.resume(throwing: error)
            }
        }
    }
}
```

## Best Practices

1. **Use @MainActor for UI updates**: Ensures UI code runs on main thread
2. **Handle Task cancellation**: Check `Task.isCancelled` in long-running operations
3. **Avoid blocking the main thread**: Use Task for async work
4. **Use structured concurrency**: Prefer async let and TaskGroup over unstructured Tasks
5. **Don't mix callbacks and async/await**: Migrate entire call chains

## Common Pitfalls

1. **Forgetting await**: Compiler will catch this
2. **Not handling errors**: Use try/catch for throwing async functions
3. **Creating retain cycles**: Use weak self in Task closures when needed
4. **Multiple continuation resumes**: Will crash in debug builds

## Testing Async Code

```swift
// XCTest supports async tests
func testAsyncOperation() async throws {
    let result = try await myAsyncFunction()
    XCTAssertEqual(result, expectedValue)
}

// Test with expectations for callback-based code
func testCallbackMigration() async {
    let expectation = expectation(description: "Async operation")
    
    Task {
        let result = await myAsyncOperation()
        XCTAssertNotNil(result)
        expectation.fulfill()
    }
    
    await fulfillment(of: [expectation], timeout: 5.0)
}
```

## References
- [Swift Concurrency Documentation](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/concurrency/)
- [WWDC 2021: Meet async/await in Swift](https://developer.apple.com/videos/play/wwdc2021/10132/)
- [Swift Evolution Proposal SE-0296](https://github.com/apple/swift-evolution/blob/main/proposals/0296-async-await.md)