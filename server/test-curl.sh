#!/bin/bash

# Quick curl test for the /api/new-recording endpoint

echo "🧪 Testing /api/new-recording with curl"
echo "======================================"

if [ -z "$1" ]; then
    echo "Usage: ./test-curl.sh <audio-file-path>"
    echo "Example: ./test-curl.sh ~/Desktop/recording.m4a"
    exit 1
fi

AUDIO_FILE="$1"

if [ ! -f "$AUDIO_FILE" ]; then
    echo "❌ File not found: $AUDIO_FILE"
    exit 1
fi

echo "📤 Uploading: $AUDIO_FILE"
echo "⏳ Processing..."

# Make the request and save response
RESPONSE=$(curl -s -X POST http://localhost:8000/api/new-recording \
  -F "audio=@$AUDIO_FILE" \
  -H "Accept: application/json")

# Check if request was successful
if [ $? -ne 0 ]; then
    echo "❌ Request failed"
    exit 1
fi

# Pretty print the response using jq if available, otherwise use python
if command -v jq &> /dev/null; then
    echo "$RESPONSE" | jq .
else
    echo "$RESPONSE" | python3 -m json.tool
fi

echo ""
echo "✅ Test complete!"