# Funnel iOS App Makefile
# Usage: make [command]

# Default simulator device
SIMULATOR = iPhone 16 Pro
SCHEME = Funnel
PROJECT = Funnel.xcodeproj

# Colors for output
GREEN = \033[0;32m
YELLOW = \033[0;33m
RED = \033[0;31m
NC = \033[0m # No Color

.PHONY: help build clean generate install run test format lint all

# Default target
all: generate build

help:
	@echo "$(GREEN)Funnel iOS App - Available commands:$(NC)"
	@echo "  $(YELLOW)make build$(NC)     - Generate project and build the app"
	@echo "  $(YELLOW)make generate$(NC)  - Generate Xcode project from project.yml"
	@echo "  $(YELLOW)make clean$(NC)     - Clean build artifacts and DerivedData"
	@echo "  $(YELLOW)make install$(NC)   - Install required tools (xcodegen, swiftformat)"
	@echo "  $(YELLOW)make run$(NC)       - Build and run on simulator"
	@echo "  $(YELLOW)make test$(NC)      - Run tests"
	@echo "  $(YELLOW)make format$(NC)    - Format Swift code"
	@echo "  $(YELLOW)make lint$(NC)      - Run SwiftLint (if installed)"
	@echo "  $(YELLOW)make all$(NC)       - Generate and build (default)"

# Generate Xcode project
generate:
	@echo "$(GREEN)Generating Xcode project...$(NC)"
	@xcodegen generate
	@echo "$(GREEN)✅ Project generated$(NC)"

# Build the app
build: generate
	@echo "$(GREEN)Building for $(SIMULATOR)...$(NC)"
	@xcodebuild -project $(PROJECT) \
		-scheme $(SCHEME) \
		-destination 'platform=iOS Simulator,name=$(SIMULATOR)' \
		build \
		-quiet && echo "$(GREEN)✅ Build succeeded$(NC)" || (echo "$(RED)❌ Build failed$(NC)" && exit 1)

# Clean build artifacts
clean:
	@echo "$(YELLOW)Cleaning build artifacts...$(NC)"
	@rm -rf ~/Library/Developer/Xcode/DerivedData/Funnel-*
	@xcodebuild -project $(PROJECT) -scheme $(SCHEME) clean -quiet 2>/dev/null || true
	@echo "$(GREEN)✅ Clean complete$(NC)"

# Deep clean (including regenerating project)
deep-clean: clean
	@echo "$(YELLOW)Removing generated project files...$(NC)"
	@rm -rf $(PROJECT)
	@echo "$(GREEN)✅ Deep clean complete$(NC)"

# Install required tools
install:
	@echo "$(GREEN)Checking and installing required tools...$(NC)"
	@command -v xcodegen >/dev/null 2>&1 || (echo "Installing XcodeGen..." && brew install xcodegen)
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

# Run tests
test: generate
	@echo "$(GREEN)Running tests...$(NC)"
	@xcodebuild -project $(PROJECT) \
		-scheme $(SCHEME) \
		-destination 'platform=iOS Simulator,name=$(SIMULATOR)' \
		test \
		-quiet \
		|| (echo "$(RED)❌ Tests failed$(NC)" && exit 1)
	@echo "$(GREEN)✅ Tests passed$(NC)"

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
	@xcodegen generate >/dev/null 2>&1
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
release: generate
	@echo "$(GREEN)Building Release configuration...$(NC)"
	@xcodebuild -project $(PROJECT) \
		-scheme $(SCHEME) \
		-configuration Release \
		-destination "generic/platform=iOS" \
		archive \
		-archivePath ./build/$(SCHEME).xcarchive \
		-quiet
	@echo "$(GREEN)✅ Release build complete$(NC)"