# Test Reorganization Plan

## Overview
This document outlines the plan to reorganize and improve the test suite for the Funnel app, focusing on clarity, comprehensive coverage, and maintainability.

## Key Changes

### 1. Rename DeepgramClient → AudioUploadClient
The current `DeepgramClient` name is misleading since it connects to our server (which then connects to Deepgram), not directly to Deepgram. The new name `AudioUploadClient` better reflects its purpose: uploading audio to our server via streaming or file upload.

**AudioUploadClient capabilities:**
- Stream audio in real-time (microphone or file playback)
- Upload complete audio files
- Both methods should return identical `ProcessedRecording` results

## iOS Test Structure (No Subfolders)

```
FunnelAITests/
├── APIModelsTests.swift                      // Unit tests for JSON parsing
├── AudioProcessingTests.swift                // Unit tests for audio conversion  
├── ViewModelTests.swift                      // Unit tests for NewRecordingViewModel
├── AudioUploadClientIntegrationTests.swift   // Integration tests for both streaming and file upload
└── NetworkingIntegrationTests.swift          // Basic networking/WebSocket integration tests
```

### Test Descriptions

#### AudioUploadClientIntegrationTests.swift
```swift
/**
 * Critical integration tests for the AudioUploadClient.
 * Tests both streaming and file upload modes against a running development server.
 * Verifies that both upload methods produce identical results for the same audio input.
 * This is the primary test for validating core app functionality.
 */
```
- Test streaming with mock microphone provider
- Test direct file upload
- Verify both methods return identical ProcessedRecording for same audio
- Test error handling for both modes

#### APIModelsTests.swift
- Move from Integration folder (currently TestServerResponseParsingSwiftTesting)
- Pure unit tests for JSON encoding/decoding
- No server required

#### NetworkingIntegrationTests.swift
- Renamed from SimpleWebSocketTestSwiftTesting
- Basic connectivity and WebSocket lifecycle tests
- Remove redundant streaming logic

### Files to Remove
- `TestStreamingEndpointSwiftTesting.swift` - redundant with AudioUploadClientIntegrationTests
- `TestFileUploadEndpointSwiftTesting.swift` - consolidated into AudioUploadClientIntegrationTests

## Server Test Structure (With Subfolders)

```
server/tests/
├── unit/
│   ├── api-models.test.ts              // Test response shapes
│   ├── filler-word-removal.test.ts     // Test transcript editing logic
│   └── prompt-generation.test.ts       // Test prompt construction
└── integration/
    └── audio-processing-integration.test.ts // Full pipeline test
```

### New Server Tests

#### unit/filler-word-removal.test.ts
```typescript
/**
 * Unit tests for transcript editing logic.
 * Verifies filler word removal and light editing functionality.
 */
```
- Test removal of "um", "uh", "you know", "like"
- Test preservation of important punctuation
- Test edge cases (filler words as part of other words)

#### unit/api-models.test.ts
- Extract model validation from current api_test.ts
- Remove legacy endpoint tests (TranscribeResponse, etc.)
- Focus on NewRecordingResponse validation

## Implementation Order

1. **Rename DeepgramClient to AudioUploadClient** throughout codebase
2. **Add file upload capability** to AudioUploadClient
3. **Create AudioUploadClientIntegrationTests** combining both upload modes
4. **Move and rename** existing tests according to plan
5. **Add missing server unit tests** (filler-word-removal, prompt-generation)
6. **Remove redundant tests**

## Success Criteria

- All critical user flows have integration test coverage
- Unit tests run in < 1 second
- Integration tests clearly indicate server dependency
- No duplicate test coverage
- Test names clearly indicate what they test
- Same audio input produces identical results via streaming or file upload