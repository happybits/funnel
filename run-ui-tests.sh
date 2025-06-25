#!/bin/bash

# Funnel UI Tests Runner Script

set -e

echo "🧪 Funnel UI Tests Runner"
echo "========================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if BlackHole is installed
check_blackhole() {
    echo -e "${YELLOW}Checking BlackHole installation...${NC}"
    if system_profiler SPAudioDataType | grep -q "BlackHole"; then
        echo -e "${GREEN}✓ BlackHole is installed${NC}"
        return 0
    else
        echo -e "${RED}✗ BlackHole not found${NC}"
        echo "Please install BlackHole:"
        echo "  brew install blackhole-2ch"
        echo ""
        echo "After installation:"
        echo "1. Open System Preferences → Sound → Input"
        echo "2. Select 'BlackHole 2ch' as input device"
        return 1
    fi
}

# Build the test target
build_tests() {
    echo -e "${YELLOW}Building test target...${NC}"
    xcodebuild build-for-testing \
        -scheme FunnelAI \
        -destination 'platform=iOS Simulator,name=iPhone 15' \
        -quiet || {
            echo -e "${RED}✗ Build failed${NC}"
            exit 1
        }
    echo -e "${GREEN}✓ Build successful${NC}"
}

# Run specific test or all tests
run_tests() {
    local test_filter=""
    if [ -n "$1" ]; then
        test_filter="-only-testing:FunnelUITests/$1"
        echo -e "${YELLOW}Running test: $1${NC}"
    else
        echo -e "${YELLOW}Running all UI tests...${NC}"
    fi
    
    xcodebuild test-without-building \
        -scheme FunnelAI \
        -destination 'platform=iOS Simulator,name=iPhone 15' \
        $test_filter \
        -resultBundlePath TestResults || {
            echo -e "${RED}✗ Tests failed${NC}"
            return 1
        }
    
    echo -e "${GREEN}✓ Tests passed${NC}"
    return 0
}

# Generate test report
generate_report() {
    if command -v xcpretty &> /dev/null; then
        echo -e "${YELLOW}Generating test report...${NC}"
        cat TestResults/*.xcresult/TestSummaries.plist | xcpretty --report html --output test-report.html
        echo -e "${GREEN}✓ Report generated: test-report.html${NC}"
    fi
}

# Main execution
main() {
    echo ""
    
    # Check prerequisites
    if ! check_blackhole; then
        echo -e "${YELLOW}Warning: Tests may fail without proper audio setup${NC}"
        echo "Continue anyway? (y/n)"
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    
    echo ""
    
    # Build tests
    build_tests
    
    echo ""
    
    # Run tests
    if [ "$1" = "--help" ]; then
        echo "Usage: $0 [test_name]"
        echo ""
        echo "Examples:"
        echo "  $0                    # Run all tests"
        echo "  $0 testCompleteAudioRecordingFlow"
        echo "  $0 AudioRecordingIntegrationTests/testCompleteAudioRecordingFlow"
        exit 0
    fi
    
    run_tests "$1"
    test_result=$?
    
    echo ""
    
    # Generate report if tests were run
    if [ -d "TestResults" ]; then
        generate_report
    fi
    
    exit $test_result
}

# Run main function with all arguments
main "$@"