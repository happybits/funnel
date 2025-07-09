# Funnel App Test Summary

## Overview
This document summarizes all the tests in the Funnel app, covering both iOS (Swift) and server (TypeScript) test suites.

## iOS Tests (Swift)

### 1. IdeaExplorationCardTests.swift
Tests the new idea exploration card feature that displays thought-provoking questions.

- **testCardTypeIdeaExplorationShareContent()** - Verifies the share content formatting for idea exploration cards (numbered questions with double line breaks)
- **testCardTypeIdeaExplorationCanShare()** - Tests whether cards can be shared based on having content (returns true only if questions exist)
- **testCardTypeCopyContent()** - Ensures copy content matches share content exactly
- **testRecordingThoughtProvokingQuestions()** - Tests the Recording model's thoughtProvokingQuestions property storage and retrieval
- **testProcessedRecordingDecoding()** - Tests JSON decoding of ProcessedRecording with thoughtProvokingQuestions array
- **testProcessedRecordingDecodingWithEmptyQuestions()** - Tests decoding when thoughtProvokingQuestions is an empty array
- **testIdeaExplorationCardView()** - Verifies the IdeaExplorationCard SwiftUI view can be created and rendered
- **testIdeaExplorationCardWithEmptyQuestions()** - Tests the view handles empty questions gracefully
- **testPurpleIndigoGradientTheme()** - Tests the purple/indigo gradient theme has correct colors and components
- **testSwipeableCardsViewIncludesIdeaExplorationCard()** - Integration test verifying the card works within the swipeable cards context

### 2. SimpleWebSocketTest.swift
Basic WebSocket connection testing for audio streaming.

- **testBasicWebSocketConnection()** - Tests WebSocket connection establishment, configuration message sending, and basic message exchange with the server

### 3. StreamingVsFileUploadTests.swift
Performance comparison tests between streaming and traditional file upload.

- **testFullFileUpload()** - Tests traditional file upload performance metrics including upload time, processing time, and total time
- **testStreamingWithRealisticTiming()** - Tests streaming with 100ms chunks to simulate real-time audio capture, measuring time from last chunk to final result

### 4. DeepgramClientTests.swift
Deepgram client integration testing.

- **testStreamAudioDataWithDeepgramClient()** - Tests streaming audio to Deepgram service and verifies transcription, lightly edited transcript, bullet summary, and diagram generation

## Server Tests (TypeScript)

### 5. api_test.ts
API response shape validation and business logic tests.

- **TranscribeResponse validation** - Tests the shape of transcription responses (transcript string, duration number)
- **Error response validation** - Validates error response format with error message and optional details
- **SummarizeResponse validation** - Tests bullet summary array structure and content
- **DiagramResponse validation** - Validates diagram title, description, and content fields
- **NewRecordingResponse validation** - Tests the complete response including lightlyEditedTranscript
- **Summarize endpoint tests** - Tests bullet point generation from long transcripts (3-6 concise points)
- **Empty/long transcript handling** - Tests appropriate error responses for edge cases
- **Filler word removal** - Validates that "um", "uh", "you know", "like" are removed in lightly edited transcripts

### 6. new-recording-test.ts
New recording endpoint integration tests.

- **Missing audio file test** - Verifies 400 error response when no audio file is provided
- **Invalid file type test** - Tests validation rejecting non-audio files (e.g., .txt files)
- **Real audio file integration test** - Full end-to-end test with actual audio file, validating:
  - Transcription accuracy
  - Lightly edited transcript generation
  - Duration calculation
  - Bullet summary generation
  - Diagram creation

## Test Coverage Summary

### iOS Tests
- **Unit Tests**: Model properties, JSON decoding, view creation, gradient themes
- **Integration Tests**: WebSocket connections, streaming performance, Deepgram API integration
- **UI Tests**: SwiftUI view rendering and card interactions

### Server Tests
- **Unit Tests**: Response shape validation, data transformation logic
- **Integration Tests**: Full API endpoint testing with real and mock data
- **Error Handling**: Comprehensive validation of error cases and edge conditions

## Running Tests

### iOS Tests
```bash
# Run all tests
make test

# Run specific test class
make test-class CLASS=IdeaExplorationCardTests

# Run specific test method
make test-method TEST=IdeaExplorationCardTests/testCardTypeIdeaExplorationShareContent
```

### Server Tests
```bash
# Run all server tests
cd server
deno test

# Run specific test file
deno test tests/api_test.ts
deno test tests/new-recording-test.ts

# Run with API keys for integration tests
OPENAI_API_KEY=xxx ANTHROPIC_API_KEY=xxx deno test
```