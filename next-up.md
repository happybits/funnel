# Next Up: Implement Finalize Transcript Feature

## Overview
When the user stops recording on iOS, we need to automatically trigger transcript finalization (similar to the "Finalize & Process" button on the web test page). This will finalize the Deepgram transcript and save it to Deno KV.

## Current Implementation Reference

### Web Client (test-page.ts)
- Has a "Finalize & Process" button that calls `POST /api/recordings/{recordingId}/done`
- This endpoint processes the recording and generates summaries
- See lines 541-568 in `/server/api/test-page.ts`

### iOS Client (AudioRecorderManager.swift)
- Currently just stops the audio engine and closes WebSocket
- No finalization step implemented yet
- See `stopLiveStreaming()` method around line 310

### Server WebSocket Handler (stream-recording-ws.ts)
- On WebSocket close, it calls `deepgramConnection.finish()` 
- Updates recording status to "processing" in KV
- See lines 126-141 in `/server/api/stream-recording-ws.ts`

## Implementation Plan

### 1. iOS Client Changes (AudioRecorderManager.swift)

#### Option A: Call REST endpoint after WebSocket closes
```swift
private func stopLiveStreaming() {
    // ... existing stop logic ...
    
    // After WebSocket closes, call finalize endpoint
    if let recordingId = recordingId {
        Task {
            await finalizeRecording(recordingId: recordingId)
        }
    }
}

private func finalizeRecording(recordingId: String) async {
    // Call POST /api/recordings/{recordingId}/done
    // Handle response with transcript and summaries
}
```

#### Option B: Send finalize message through WebSocket before closing
```swift
// Send finalize command before closing
let finalizeMsg = ["type": "finalize"]
webSocket?.send(.string(JSONString(finalizeMsg))) { _ in
    // Then close WebSocket
    webSocket?.cancel(with: .goingAway, reason: nil)
}
```

### 2. Server Changes

#### If using Option A (REST endpoint):
- Ensure `/api/recordings/{recordingId}/done` endpoint exists and works
- May need to create this endpoint if it doesn't exist
- Should retrieve final transcript from KV and process summaries

#### If using Option B (WebSocket message):
- Add handler in `stream-recording-ws.ts` for "finalize" message type
- Trigger Deepgram finalization
- Process and save final transcript
- Send final response back through WebSocket

### 3. Deepgram Finalization

The server already calls `deepgramConnection.finish()` on WebSocket close, which should:
- Send any remaining audio data to Deepgram
- Receive final transcript segments
- The transcript event handler already saves to KV

### 4. Data Flow

1. User stops recording on iOS
2. iOS sends finalize signal (via REST or WebSocket)
3. Server ensures Deepgram connection is properly closed
4. Server waits for all final transcript segments
5. Server compiles complete transcript from segments
6. Server saves final transcript to Deno KV
7. Server returns success response to iOS

## Key Considerations

### Timing
- Need to ensure all audio chunks are sent before finalizing
- May need a small delay between last audio chunk and finalization
- Consider implementing a "flush" mechanism

### Error Handling
- What if Deepgram connection already closed?
- What if no transcript segments were received?
- Network interruption during finalization

### State Management
- Recording status transitions: "recording" → "processing" → "completed"
- Ensure proper cleanup of resources
- Handle edge cases (app backgrounding, network loss)

## Implementation Priority

1. **First**: Verify current server behavior when WebSocket closes
   - Check if transcript is already being saved properly
   - Test what happens with `deepgramConnection.finish()`

2. **Second**: Implement iOS finalization call
   - Recommend Option A (REST endpoint) for simplicity
   - Matches web client pattern

3. **Third**: Ensure server processes final transcript
   - Compile segments into complete transcript
   - Save to KV with proper status

4. **Fourth**: Return processed data to iOS
   - Include transcript, duration, word count
   - Could later add summaries/bullet points

## Testing Checklist

- [ ] iOS stops recording → transcript is finalized
- [ ] All audio chunks are processed before finalization
- [ ] Final transcript is saved to Deno KV
- [ ] Recording status updates correctly
- [ ] Error cases handled gracefully
- [ ] Network interruption doesn't lose data

## Code References

- **Finalize endpoint example**: `/server/api/test-page.ts` lines 541-568
- **WebSocket close handler**: `/server/api/stream-recording-ws.ts` lines 126-141
- **iOS stop recording**: `/Funnel/Funnel/AudioRecorderManager.swift` line 310
- **Recording data model**: `/server/lib/deepgram.ts` lines 115-134

## Next Steps After This

1. Implement transcript processing (bullet points, summaries)
2. Create iOS UI to display finalized transcript
3. Add ability to save/export transcripts
4. Implement offline support and retry logic