# Current Task: Lightly Edited Transcript Feature

## Overview

Added a new feature to generate and display lightly edited transcripts that
remove filler words (um, uh, like, you know) while preserving the speaker's
natural tone and meaning.

## Changes Made

### Server-Side (TypeScript/Deno)

1. **Created new prompt file**: `/server/lib/prompts/edit-transcript-prompt.txt`
   - Defines how to clean up raw transcripts while preserving authenticity

2. **Updated Anthropic client**: `/server/lib/anthropic.ts`
   - Added `generateLightlyEditedTranscript()` method
   - Added `EditTranscriptResponse` interface

3. **Updated API types**: `/server/types/api.ts`
   - Added `lightlyEditedTranscript` field to `NewRecordingResponse`

4. **Updated endpoints**:
   - `/api/new-recording`: Now generates lightly edited transcript in parallel
     with other AI processing
   - `/api/recordings/:recordingId/done`: Also generates lightly edited
     transcript for streamed recordings

5. **Updated AI processing**: `/server/lib/ai-processing.ts`
   - Added `lightlyEditedTranscript` to `ProcessedRecording` interface
   - Added `generateLightlyEditedTranscript()` helper function

### Client-Side (Swift/iOS)

1. **Updated data models**:
   - `ProcessedRecording` in `APIModels.swift`: Added `lightlyEditedTranscript`
     field
   - `Recording` in `Recording.swift`: Added `lightlyEditedTranscript` property

2. **Updated view model**: `NewRecordingViewModel.swift`
   - Maps the new `lightlyEditedTranscript` field from API response to SwiftData
     model

3. **Updated UI**: `SwipeableCardsView.swift`
   - `TranscriptCard` now displays `lightlyEditedTranscript` with fallback to
     raw transcript
   - Updated preview data to include sample lightly edited transcript

### Tests

1. **Server tests**:
   - Added test in `api_test.ts` for `NewRecordingResponse` validation with new
     field
   - Added test for verifying filler word removal
   - Updated integration test in `new-recording-test.ts` to log and validate
     lightly edited transcript

2. **Client tests**:
   - Updated `DeepgramClientTests.swift` to verify lightly edited transcript
     exists and differs from raw

## Current Status

✅ Feature implementation complete ✅ Tests updated and passing validation ✅
All server linting issues fixed

## Next Steps

1. Run full test suite (`make test` in both server and iOS directories)
2. Test the feature end-to-end with real audio

## How It Works

When audio is processed, the system now:

1. Generates raw transcript (via Whisper or Deepgram)
2. Sends raw transcript to Claude with editing prompt
3. Claude returns cleaned version without filler words
4. Both versions are stored and returned to client
5. UI displays the lightly edited version in the transcript card
