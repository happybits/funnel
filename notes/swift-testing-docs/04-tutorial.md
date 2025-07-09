# Swift Testing Tutorial: Add Functionality with Swift Testing

## Tutorial Overview

This tutorial focuses on building a Score Keeper app while learning Swift Testing, Apple's modern testing framework. You'll create a model that tracks game state and resets players' scores when the game starts, while writing unit tests to ensure your app works correctly.

## Step-by-Step Tutorial

### Step 1: Setting Up Swift Testing

Swift Testing is included with Xcode 16 and the Swift 6 toolchain. To get started:

1. Import the Testing framework in your test files:
```swift
import Testing
```

2. Create a test target if you don't have one (important: don't link tests to your main executable)

### Step 2: Creating the Player Model

First, create a simple player model for the Score Keeper app:

```swift
struct Player: Identifiable {
    let id = UUID()
    var name: String
    var score: Int
    var color: Color
    
    init(name: String, score: Int = 0, color: Color = .blue) {
        self.name = name
        self.score = score
        self.color = color
    }
}
```

### Step 3: Writing Your First Test

Tests in Swift Testing use the `@Test` macro instead of XCTest's method prefix:

```swift
@Test("Player initializes with default score of zero")
func playerDefaultScore() {
    let player = Player(name: "Alice")
    #expect(player.score == 0)
}
```

### Step 4: Creating the Game State Model

Build a game state model that manages multiple players:

```swift
@Observable
class GameState {
    var players: [Player] = []
    var isGameActive = false
    
    func addPlayer(name: String) {
        let player = Player(name: name)
        players.append(player)
    }
    
    func updateScore(for playerId: UUID, by points: Int) {
        if let index = players.firstIndex(where: { $0.id == playerId }) {
            players[index].score += points
        }
    }
    
    func resetGame() {
        for index in players.indices {
            players[index].score = 0
        }
        isGameActive = false
    }
}
```

### Step 5: Testing Game State with Descriptive Names

Use descriptive test names with the `displayName` parameter:

```swift
@Test("Game state correctly resets all player scores to zero")
func gameReset() {
    let gameState = GameState()
    
    // Add players and set scores
    gameState.addPlayer(name: "Alice")
    gameState.addPlayer(name: "Bob")
    gameState.players[0].score = 10
    gameState.players[1].score = 15
    gameState.isGameActive = true
    
    // Reset the game
    gameState.resetGame()
    
    // Verify all scores are reset
    #expect(gameState.players.allSatisfy { $0.score == 0 })
    #expect(!gameState.isGameActive)
}
```

### Step 6: Using Parameterized Tests

Test multiple scenarios with a single test using parameterized tests:

```swift
@Test("Score updates correctly for different point values", 
      arguments: [-5, 0, 1, 10, 100])
func scoreUpdate(points: Int) {
    let gameState = GameState()
    gameState.addPlayer(name: "Test Player")
    let playerId = gameState.players[0].id
    
    gameState.updateScore(for: playerId, by: points)
    
    #expect(gameState.players[0].score == points)
}
```

### Step 7: Testing Edge Cases

```swift
@Test("Updating score for non-existent player does not crash")
func updateNonExistentPlayer() {
    let gameState = GameState()
    let fakeId = UUID()
    
    // This should not crash
    gameState.updateScore(for: fakeId, by: 10)
    
    #expect(gameState.players.isEmpty)
}
```

### Step 8: Organizing Tests with Tags

Use tags to organize related tests:

```swift
@Test("Maximum players limit enforced", .tags(.gameRules))
func maxPlayersLimit() {
    let gameState = GameState()
    let maxPlayers = 8
    
    for i in 1...10 {
        gameState.addPlayer(name: "Player \(i)")
    }
    
    #expect(gameState.players.count <= maxPlayers)
}

// Define custom tags
extension Tag {
    @Tag static var gameRules: Self
    @Tag static var scoring: Self
    @Tag static var playerManagement: Self
}
```

## Code Examples and Patterns

### Pattern 1: Using #require for Preconditions

```swift
@Test func playerExists() throws {
    let gameState = GameState()
    gameState.addPlayer(name: "Alice")
    
    let player = try #require(gameState.players.first)
    #expect(player.name == "Alice")
}
```

### Pattern 2: Async Testing

```swift
@Test func saveGameState() async throws {
    let gameState = GameState()
    gameState.addPlayer(name: "Alice")
    
    let saved = try await gameState.save()
    #expect(saved == true)
}
```

### Pattern 3: Test Suites

```swift
@Suite("Score Keeper Game Logic")
struct GameLogicTests {
    @Test func newGameStartsEmpty() {
        let gameState = GameState()
        #expect(gameState.players.isEmpty)
    }
    
    @Test func addingPlayerIncreasesCount() {
        let gameState = GameState()
        gameState.addPlayer(name: "Alice")
        #expect(gameState.players.count == 1)
    }
}
```

## Best Practices for Beginners

### 1. Start with Simple Tests
Begin with the most basic functionality and gradually add complexity:
```swift
// Start simple
@Test func playerHasName() {
    let player = Player(name: "Alice")
    #expect(player.name == "Alice")
}
```

### 2. Use Descriptive Test Names
Make your tests self-documenting:
```swift
@Test("Player score cannot go below zero when negative points applied")
func minimumScoreLimit() {
    // Test implementation
}
```

### 3. Test One Thing at a Time
Each test should verify a single behavior:
```swift
// Good: Tests one specific behavior
@Test func resetClearsScores() {
    // Only test score clearing
}

// Avoid: Testing multiple behaviors
@Test func resetWorksCorrectly() {
    // Tests scores, game state, and player count
}
```

### 4. Use #expect for Clear Assertions
The #expect macro provides better error messages:
```swift
let player = Player(name: "Alice", score: 10)
#expect(player.score == 10)  // Clear failure message if score != 10
```

### 5. Leverage Parallel Execution
Swift Testing runs tests in parallel by default. Ensure your tests are independent:
```swift
// Each test creates its own gameState
@Test func test1() {
    let gameState = GameState()  // Independent instance
}

@Test func test2() {
    let gameState = GameState()  // Independent instance
}
```

## Common Use Cases

### 1. Testing Model Initialization
```swift
@Test("Player initializes with all default values correctly")
func playerDefaults() {
    let player = Player(name: "Test")
    #expect(player.score == 0)
    #expect(player.color == .blue)
    #expect(!player.name.isEmpty)
}
```

### 2. Testing State Changes
```swift
@Test("Game state transitions correctly")
func gameStateTransitions() {
    let game = GameState()
    #expect(!game.isGameActive)
    
    game.startGame()
    #expect(game.isGameActive)
    
    game.endGame()
    #expect(!game.isGameActive)
}
```

### 3. Testing Collections
```swift
@Test("Player list maintains order after sorting")
func playerSorting() {
    let game = GameState()
    game.addPlayer(name: "Charlie")
    game.addPlayer(name: "Alice")
    game.addPlayer(name: "Bob")
    
    game.sortPlayersByName()
    
    let names = game.players.map { $0.name }
    #expect(names == ["Alice", "Bob", "Charlie"])
}
```

### 4. Testing Error Conditions
```swift
@Test("Adding duplicate player throws error")
func duplicatePlayerError() throws {
    let game = GameState()
    game.addPlayer(name: "Alice")
    
    #expect(throws: GameError.duplicatePlayer) {
        try game.addUniquePlayer(name: "Alice")
    }
}
```

### 5. Testing with Fixtures
```swift
@Suite struct GameTestsWithSetup {
    let game: GameState
    
    init() {
        game = GameState()
        game.addPlayer(name: "Alice")
        game.addPlayer(name: "Bob")
    }
    
    @Test func playersExist() {
        #expect(game.players.count == 2)
    }
}
```

## Tips for Score Keeper App Testing

1. **Test the Complete Game Lifecycle**: From initialization through gameplay to reset
2. **Verify Data Persistence**: If your app saves scores, test both save and load operations
3. **Test UI State Synchronization**: Ensure your model updates reflect in the UI
4. **Handle Edge Cases**: Test with 0 players, maximum players, extreme scores
5. **Test Concurrent Updates**: If your app supports real-time updates, test simultaneous score changes

## Migration Tips from XCTest

If you're coming from XCTest:
- Replace `XCTAssertEqual(a, b)` with `#expect(a == b)`
- Replace `func testX()` with `@Test func x()`
- Replace `XCTAssertThrowsError` with `#expect(throws:)`
- Replace `setUpWithError()` with init methods or computed properties

## Resources for Further Learning

1. [Apple's Swift Testing Documentation](https://developer.apple.com/documentation/testing)
2. [WWDC24: Meet Swift Testing](https://developer.apple.com/videos/play/wwdc2024/10179/)
3. [Swift Testing GitHub Repository](https://github.com/swiftlang/swift-testing)
4. Practice with the Score Keeper app by adding features like:
   - Player statistics tracking
   - Game history
   - Tournament modes
   - Team scoring

Remember: The key to mastering Swift Testing is practice. Start with simple tests and gradually increase complexity as you become more comfortable with the framework.