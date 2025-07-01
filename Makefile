# Funnel iOS App Makefile
# Usage: make [command]

# Default simulator device
SIMULATOR = iPhone 16 Pro
SCHEME = FunnelAI
PROJECT = FunnelAI.xcodeproj

# Colors for output
GREEN = \033[0;32m
YELLOW = \033[0;33m
RED = \033[0;31m
NC = \033[0m # No Color

.PHONY: help build clean install run test format lint all

# Default target
all: build

help:
	@echo "$(GREEN)Funnel iOS App - Available commands:$(NC)"
	@echo ""
	@echo "$(YELLOW)Building & Running:$(NC)"
	@echo "  $(YELLOW)make build$(NC)         - Build the app"
	@echo "  $(YELLOW)make run$(NC)           - Build and run on simulator"
	@echo "  $(YELLOW)make release$(NC)       - Build for release"
	@echo "  $(YELLOW)make quick$(NC)         - Quick build with minimal output"
	@echo ""
	@echo "$(YELLOW)Testing:$(NC)"
	@echo "  $(YELLOW)make test$(NC)          - Run all tests"
	@echo "  $(YELLOW)make test-class CLASS=Name$(NC)  - Run specific test class"
	@echo "  $(YELLOW)make test-method TEST=Class/method$(NC) - Run specific test"
	@echo "  $(YELLOW)make test-results$(NC)  - Show test results summary"
	@echo "  $(YELLOW)make test-failures$(NC) - Show test failures"
	@echo ""
	@echo "$(YELLOW)Maintenance:$(NC)"
	@echo "  $(YELLOW)make clean$(NC)         - Clean build artifacts"
	@echo "  $(YELLOW)make clean-tests$(NC)   - Clean test results"
	@echo "  $(YELLOW)make deep-clean$(NC)    - Deep clean including DerivedData"
	@echo "  $(YELLOW)make format$(NC)        - Format Swift code"
	@echo "  $(YELLOW)make lint$(NC)          - Run SwiftLint (if installed)"
	@echo "  $(YELLOW)make install$(NC)       - Install required tools"

# Build the app
build:
	@echo "$(GREEN)Building for $(SIMULATOR)...$(NC)"
	@xcodebuild -project $(PROJECT) \
		-scheme $(SCHEME) \
		-destination 'platform=iOS Simulator,name=$(SIMULATOR)' \
		build \
		-quiet && echo "$(GREEN)✅ Build succeeded$(NC)" || (echo "$(RED)❌ Build failed$(NC)" && exit 1)

# Clean build artifacts
clean:
	@echo "$(YELLOW)Cleaning build artifacts...$(NC)"
	@rm -rf ~/Library/Developer/Xcode/DerivedData/FunnelAI-*
	@xcodebuild -project $(PROJECT) -scheme $(SCHEME) clean -quiet 2>/dev/null || true
	@echo "$(GREEN)✅ Clean complete$(NC)"

# Deep clean (includes test results)
deep-clean: clean clean-tests
	@echo "$(GREEN)✅ Deep clean complete$(NC)"

# Install required tools
install:
	@echo "$(GREEN)Checking and installing required tools...$(NC)"
	@command -v swiftformat >/dev/null 2>&1 || (echo "Installing SwiftFormat..." && brew install swiftformat)
	@echo "$(GREEN)✅ All tools installed$(NC)"

# Build and run on simulator
run: build
	@echo "$(GREEN)Running on $(SIMULATOR)...$(NC)"
	@xcrun simctl boot "$(SIMULATOR)" 2>/dev/null || true
	@open -a Simulator
	@xcodebuild -project $(PROJECT) \
		-scheme $(SCHEME) \
		-destination 'platform=iOS Simulator,name=$(SIMULATOR)' \
		-derivedDataPath .build \
		-quiet \
		build
	@xcrun simctl install booted .build/Build/Products/Debug-iphonesimulator/$(SCHEME).app
	@xcrun simctl launch booted com.joya.funnel

# Run all tests
test:
	@echo "$(GREEN)Running all tests...$(NC)"
	@rm -rf TestOutput.xcresult 2>/dev/null || true
	@rm -rf test-results 2>/dev/null || true
	@xcodebuild test \
		-project $(PROJECT) \
		-scheme FunnelAITests \
		-destination 'platform=iOS Simulator,name=$(SIMULATOR)' \
		-resultBundlePath TestOutput.xcresult \
		2>&1 | grep -E "(Test Suite|passed|failed)" || true
	@echo "$(GREEN)✅ Test run complete. Results saved to TestOutput.xcresult$(NC)"
	@echo "$(YELLOW)Generating HTML report...$(NC)"
	@xchtmlreport TestOutput.xcresult
	@echo "$(GREEN)✅ HTML report generated$(NC)"
	@echo ""
	@echo "$(GREEN)📊 View test report:$(NC)"
	@echo "    file://$(PWD)/index.html"
	@echo ""
	@echo "$(YELLOW)Click the link above or run:$(NC)"
	@echo "    open index.html"

# Run specific test class
test-class:
	@if [ -z "$(CLASS)" ]; then \
		echo "$(RED)Error: CLASS not specified. Usage: make test-class CLASS=SimplePrintTest$(NC)"; \
		exit 1; \
	fi
	@echo "$(GREEN)Running tests in $(CLASS)...$(NC)"
	@rm -rf TestOutput-$(CLASS).xcresult 2>/dev/null || true
	@xcodebuild test \
		-project $(PROJECT) \
		-scheme FunnelAITests \
		-destination 'platform=iOS Simulator,name=$(SIMULATOR)' \
		-only-testing:FunnelAITests/$(CLASS) \
		-resultBundlePath TestOutput-$(CLASS).xcresult \
		2>&1 | grep -E "(Test Suite|passed|failed)" || true
	@echo "$(GREEN)✅ Test run complete. Results saved to TestOutput-$(CLASS).xcresult$(NC)"

# Run specific test method
test-method:
	@if [ -z "$(TEST)" ]; then \
		echo "$(RED)Error: TEST not specified. Usage: make test-method TEST=SimplePrintTest/testSimplePrint$(NC)"; \
		exit 1; \
	fi
	@echo "$(GREEN)Running test $(TEST)...$(NC)"
	@rm -rf TestOutput-method.xcresult 2>/dev/null || true
	@xcodebuild test \
		-project $(PROJECT) \
		-scheme FunnelAITests \
		-destination 'platform=iOS Simulator,name=$(SIMULATOR)' \
		-only-testing:FunnelAITests/$(TEST) \
		-resultBundlePath TestOutput-method.xcresult \
		2>&1 | grep -E "(Test Suite|passed|failed)" || true
	@echo "$(GREEN)✅ Test run complete. Results saved to TestOutput-method.xcresult$(NC)"

# Parse test results
test-results:
	@if [ ! -d "TestOutput.xcresult" ]; then \
		echo "$(RED)No test results found. Run 'make test' first.$(NC)"; \
		exit 1; \
	fi
	@echo "$(GREEN)Test Results Summary:$(NC)"
	@xcrun xcresulttool get test-results summary \
		--path TestOutput.xcresult \
		--format json | jq -r '"\(.title)\nResult: \(.result)\nPassed: \(.passedTests) Failed: \(.failedTests)"'

# Show test failures
test-failures:
	@if [ ! -d "TestOutput.xcresult" ]; then \
		echo "$(RED)No test results found. Run 'make test' first.$(NC)"; \
		exit 1; \
	fi
	@echo "$(YELLOW)Test Failures:$(NC)"
	@xcrun xcresulttool get test-results tests \
		--path TestOutput.xcresult \
		--format json | \
		jq -r '.testNodes[].children[].children[].children[] | 
		       select(.result=="Failed") | 
		       "\(.name)\n  \(.children[]?.name // "")\n"' || echo "$(GREEN)No failures found!$(NC)"

# Clean test results
clean-tests:
	@echo "$(YELLOW)Cleaning test results...$(NC)"
	@rm -rf TestOutput*.xcresult
	@rm -rf test-results.xcresult
	@rm -rf SimplePrintTest.xcresult
	@rm -rf FreshTestOutput.xcresult
	@rm -rf test-results
	@rm -f index.html
	@echo "$(GREEN)✅ Test results cleaned$(NC)"

# Format Swift code
format:
	@echo "$(GREEN)Formatting Swift code...$(NC)"
	@swiftformat . --swiftversion 5.0
	@echo "$(GREEN)✅ Code formatted$(NC)"

# Run SwiftLint
lint:
	@echo "$(GREEN)Running SwiftLint...$(NC)"
	@if command -v swiftlint >/dev/null 2>&1; then \
		swiftlint; \
		echo "$(GREEN)✅ Linting complete$(NC)"; \
	else \
		echo "$(YELLOW)SwiftLint not installed. Install with: brew install swiftlint$(NC)"; \
	fi

# Quick build without all the noise
quick: 
	@xcodebuild -project $(PROJECT) \
		-scheme $(SCHEME) \
		-destination 'platform=iOS Simulator,name=$(SIMULATOR)' \
		build \
		-quiet \
		2>&1 | grep -E "(error:|warning:)" || echo "$(GREEN)✅ Build succeeded$(NC)"

# Watch for changes and rebuild
watch:
	@echo "$(GREEN)Watching for changes... (Press Ctrl+C to stop)$(NC)"
	@fswatch -o . -e ".*\.xcodeproj" -e "\.build" -e "DerivedData" | xargs -n1 -I{} make quick

# Build for release
release:
	@echo "$(GREEN)Building Release configuration...$(NC)"
	@xcodebuild -project $(PROJECT) \
		-scheme $(SCHEME) \
		-configuration Release \
		-destination "generic/platform=iOS" \
		archive \
		-archivePath ./build/$(SCHEME).xcarchive \
		-quiet
	@echo "$(GREEN)✅ Release build complete$(NC)"