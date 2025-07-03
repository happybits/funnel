# Makefile Guide for Agents

## Overview
The Makefile provides convenient commands for building, testing, and maintaining the Funnel iOS app. All commands start with `make` followed by the target name.

## Essential Commands for Development

### Verify Your Changes Compile
```bash
make build        # Build the main app
make build-test   # Build test target (catches test compilation errors)
```

**Always run these before considering a task complete!**

### Running Tests
```bash
make test         # Run all tests and generate HTML report
make test-class CLASS=YourTestClass    # Run specific test class
make test-method TEST=YourTestClass/testMethodName   # Run specific test
```

### Quick Development Cycle
```bash
make quick        # Fast build showing only errors/warnings
make format       # Format all Swift code
make clean        # Clean build artifacts
```

## How It Works

### Basic Syntax
```makefile
target-name:
    @command-to-execute
```

- `@` prefix hides the command from output (shows only results)
- Commands must start with a TAB character (not spaces)

### Variables
```makefile
SIMULATOR = iPhone 16 Pro    # Define variable
$(SIMULATOR)                 # Use variable
```

### Common Patterns

#### Build Commands
The Makefile wraps `xcodebuild` with sensible defaults:
```bash
# Instead of typing:
xcodebuild -project FunnelAI.xcodeproj -scheme FunnelAI -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build

# Just use:
make build
```

#### Error Handling
```makefile
command && echo "✅ Success" || (echo "❌ Failed" && exit 1)
```
This pattern runs a command and shows success/failure messages.

#### Quiet Output
Most commands use `-quiet` flag and grep for errors:
```bash
xcodebuild build -quiet 2>&1 | grep -E "(error:|warning:)" || echo "✅ Success"
```

## When to Use Each Command

### During Development
1. `make build` - After making code changes
2. `make build-test` - After modifying test files
3. `make format` - Before committing code
4. `make quick` - For rapid iteration

### When Debugging
1. `make clean` - If you see strange build errors
2. `make deep-clean` - For persistent issues
3. `make test-failures` - To see what tests failed

### Testing Workflow
1. `make build-test` - Verify tests compile
2. `make test` - Run all tests
3. Open `index.html` to view detailed results

## Tips for Agents

### Always Verify Compilation
Before marking any task complete:
```bash
make build        # For app changes
make build-test   # For test changes
```

### Check Exit Codes
The Makefile uses exit codes to indicate success/failure:
- Exit 0 = Success (green checkmark)
- Exit 1 = Failure (red X)

### Use Appropriate Targets
- Don't use `make test` just to check compilation - use `make build-test`
- Don't use `make clean` unless necessary - it slows down builds
- Use `make quick` for fast feedback during development

### Understanding Output
- 🟢 Green text = Success
- 🟡 Yellow text = Information/Warning
- 🔴 Red text = Error/Failure

## Troubleshooting

### "No rule to make target"
The target doesn't exist. Run `make help` to see available targets.

### Build Fails but Xcode Works
Try `make clean` then rebuild. The Makefile uses the same build system as Xcode.

### Can't Find Test Results
Test results are saved as `TestOutput.xcresult`. Run `make test-results` to see summary.

## Advanced Usage

### Running Specific Tests
```bash
# Run all tests in a class
make test-class CLASS=AudioStreamingServerTests

# Run a specific test method
make test-method TEST=AudioStreamingServerTests/testSimpleConnection
```

### Customizing Simulator
```bash
# Default is iPhone 16 Pro, but you can override:
make build SIMULATOR="iPhone 15"
```

### Parallel Execution
Some targets depend on others:
```bash
make run    # Automatically runs 'build' first
```

## Summary
The Makefile is your friend for iOS development. It standardizes commands, provides helpful output, and catches errors early. Always use `make build` and `make build-test` to verify your changes compile before marking tasks complete.