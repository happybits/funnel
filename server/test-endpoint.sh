#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}🧪 Funnel API Endpoint Tester${NC}"
echo "================================"

# Check if server is running
echo -e "\n${YELLOW}Checking if server is running...${NC}"
if curl -s http://localhost:8000 > /dev/null; then
    echo -e "${GREEN}✅ Server is running${NC}"
else
    echo -e "${RED}❌ Server is not running!${NC}"
    echo -e "${YELLOW}Please start the server with: deno task dev${NC}"
    exit 1
fi

# Check for API keys
if [ -z "$OPENAI_API_KEY" ] || [ -z "$ANTHROPIC_API_KEY" ]; then
    echo -e "\n${YELLOW}⚠️  API keys not found in environment${NC}"
    echo "Please set OPENAI_API_KEY and ANTHROPIC_API_KEY"
    exit 1
fi

# Run tests
echo -e "\n${YELLOW}Running tests...${NC}"

# Basic test with minimal audio file
echo -e "\n${GREEN}1. Testing with minimal WAV file...${NC}"
deno test tests/new-recording-test.ts --allow-all --filter "test audio file"

# Test error cases
echo -e "\n${GREEN}2. Testing error handling...${NC}"
deno test tests/new-recording-test.ts --allow-all --filter "error handling"

# Test with real audio if provided
if [ -n "$1" ]; then
    echo -e "\n${GREEN}3. Testing with real audio file: $1${NC}"
    TEST_AUDIO_PATH="$1" deno test tests/new-recording-test.ts --allow-all --filter "real audio"
else
    echo -e "\n${YELLOW}💡 Tip: Pass an audio file path as argument to test with real audio${NC}"
    echo "   Example: ./test-endpoint.sh /path/to/audio.m4a"
fi

echo -e "\n${GREEN}✨ Test complete!${NC}"