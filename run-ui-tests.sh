#!/bin/bash

# Run UI tests for Funnel app
# This script sets up the environment and runs the UI tests

set -e

echo "🧪 Running Funnel UI Tests..."

# Optional: Start local server if TEST_API_URL is set to localhost
if [[ "${TEST_API_URL}" == *"localhost"* ]] || [[ "${TEST_API_URL}" == *"127.0.0.1"* ]]; then
    echo "📡 Starting local server..."
    cd server
    deno task dev &
    SERVER_PID=$!
    cd ..
    
    # Wait for server to be ready
    echo "⏳ Waiting for server to start..."
    sleep 5
fi

# Build and run tests
echo "🏗️ Building and running UI tests..."

xcodebuild \
    -project FunnelAI.xcodeproj \
    -scheme FunnelAI \
    -destination 'platform=iOS Simulator,name=iPhone 15' \
    test \
    TEST_API_URL="${TEST_API_URL:-https://funnel-api.deno.dev}" \
    | xcpretty

# Cleanup
if [[ ! -z "${SERVER_PID}" ]]; then
    echo "🛑 Stopping local server..."
    kill $SERVER_PID
fi

echo "✅ UI Tests completed!"