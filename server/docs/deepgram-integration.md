# Deepgram Real-Time Transcription Integration

This document describes how Funnel uses Deepgram's real-time transcription API
for processing audio streams.

## Overview

Funnel uses Deepgram's WebSocket-based real-time transcription API to convert
streaming audio into text transcripts. The integration follows a specific flow
to ensure complete and accurate transcription of audio recordings.

## Architecture

### Components

1. **iOS Client**: Streams PCM audio data via WebSocket to our Deno server
2. **Deno Server**: Acts as a proxy, forwarding audio to Deepgram and returning
   transcripts
3. **Deepgram API**: Processes audio and returns incremental transcript segments

### Data Flow

```
iOS App → WebSocket → Deno Server → WebSocket → Deepgram API
                           ↓                          ↓
                      Transcript ← ← ← ← ← ← ← Transcript
```

## Implementation Details

### 1. WebSocket Connection Setup

When a client connects to `/api/recordings/{recordingId}/stream`, the server:

1. Creates a WebSocket connection to Deepgram with these options:
   ```typescript
   {
     punctuate: true,
     interim_results: true,
     model: "nova-2",
     language: "en-US",
     encoding: "linear16",  // for PCM audio
     sample_rate: 16000,    // 16kHz
     channels: 1            // mono
   }
   ```

2. Stores the Deepgram connection in memory for later access during finalization

### 2. Audio Streaming

The client sends audio in chunks:

- Format: 16-bit PCM, 16kHz, mono
- Chunk size: Typically 16000 bytes (1 second of audio)
- The server forwards each chunk directly to Deepgram

### 3. Transcript Processing

Deepgram sends two types of transcript segments:

1. **Interim Results** (`isFinal: false`):
   - Partial transcripts that may change
   - Sent frequently as audio is being processed
   - Used for real-time display

2. **Final Results** (`isFinal: true`):
   - Confirmed transcripts that won't change
   - These are stored and used for the final transcript

Example transcript message:

```json
{
  "type": "transcript",
  "segment": {
    "text": "Hello world",
    "confidence": 0.98,
    "start": 0.5,
    "end": 1.2,
    "isFinal": true
  },
  "fullTranscript": "Hello world"
}
```

### 4. Finalization Process

This is the critical part for ensuring complete transcripts:

1. **Client signals completion** by calling
   `POST /api/recordings/{recordingId}/done`

2. **Server sends CloseStream** to Deepgram:
   ```json
   { "type": "CloseStream" }
   ```

3. **Deepgram processes remaining audio** and sends a Metadata response:
   ```json
   {
     "type": "Metadata",
     "transaction_key": "deprecated",
     "request_id": "8c8ebea9-dbec-45fa-a035-e4632cb05b5f",
     "sha256": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
     "created": "2024-08-29T22:37:55.202Z",
     "duration": 32.5, // Total audio duration processed
     "channels": 1
   }
   ```

4. **Server waits for Metadata** before returning from the finalize endpoint

5. **Server forwards Metadata to client** via WebSocket

6. **Client waits for Metadata** before closing the WebSocket connection

### 5. Key Implementation Notes

#### Why the Finalization Flow Matters

- **Problem**: If you close the connection too early, you may miss final
  transcript segments
- **Solution**: The CloseStream → Metadata flow ensures all audio has been
  processed

#### Metadata Response Interpretation

- The `duration` field in the Metadata response represents the total duration of
  audio processed
- It will NOT be 0 - it will be the actual duration (e.g., 32.5 seconds)
- Any Metadata response after CloseStream indicates completion

#### Active Connection Management

The server maintains a Map of active Deepgram connections:

```typescript
const activeDeepgramConnections = new Map<string, any>();
```

This allows the finalize endpoint to access and close the Deepgram connection
for a specific recording.

## Error Handling

1. **Timeout**: If Metadata isn't received within 30 seconds, the server
   continues anyway
2. **Connection Loss**: If the WebSocket disconnects, the server calls
   `deepgramConnection.finish()`
3. **Missing Connection**: If finalize is called but no active connection
   exists, it proceeds with available data

## Testing Considerations

When testing the integration:

1. **Don't close WebSocket immediately** after calling finalize
2. **Wait for Metadata message** to confirm all transcripts are processed
3. **Verify full transcript** matches the audio duration

## API Reference

- Deepgram CloseStream Documentation:
  https://developers.deepgram.com/docs/close-stream
- Deepgram Real-time Transcription:
  https://developers.deepgram.com/docs/getting-started-with-live-streaming-audio

## Common Pitfalls

1. **Closing too early**: Don't close the WebSocket immediately after streaming
   audio
2. **Not waiting for Metadata**: The finalize endpoint must wait for Deepgram's
   confirmation
3. **Expecting duration: 0**: The Metadata duration is the total audio duration,
   not 0
4. **Missing final segments**: Always use the CloseStream flow to ensure
   completeness
