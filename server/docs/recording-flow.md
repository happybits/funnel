# Funnel Audio Recording Flow Documentation

## Overview

The Funnel server provides a real-time audio recording and transcription system
with AI-powered post-processing. This document explains how the recording flow
works, from initial connection to final processed output.

## Architecture

The system uses:

- **WebSocket connections** for real-time audio streaming
- **Deepgram API** for live transcription
- **Anthropic Claude API** for AI-powered summarization and visualization
- **Deno KV** for data persistence

## Recording Flow

### 1. Starting a Recording

When a client wants to start recording:

1. **Generate Recording ID**: Client generates a unique UUID for the recording
2. **WebSocket Connection**: Client connects to
   `/api/recordings/:recordingId/stream`
3. **Server Initialization**:
   - Creates a new recording entry in Deno KV with status `"recording"`
   - Establishes connection to Deepgram's live transcription API
   - Sends `ready` message back to client when Deepgram connection is
     established

```javascript
// Client connection
const ws = new WebSocket(`ws://server/api/recordings/${recordingId}/stream`);
```

### 2. Live Streaming & Transcription

During recording:

1. **Audio Streaming**:
   - Client captures audio using MediaRecorder API (typically WebM/Opus format)
   - Sends audio chunks via WebSocket as ArrayBuffer or Blob
   - Server forwards audio data to Deepgram in real-time

2. **Live Transcription**:
   - Deepgram processes audio and returns transcript segments
   - Each segment includes:
     - Text content
     - Confidence score
     - Timing information (start/end)
     - Final vs interim status

3. **Real-time Updates**:
   - Server stores each transcript segment in Deno KV
   - Sends transcript updates back to client via WebSocket
   - Client can display live transcription as user speaks

```json
// Example transcript update sent to client
{
  "type": "transcript",
  "segment": {
    "text": "Hello, this is a test recording",
    "confidence": 0.98,
    "start": 0.5,
    "end": 2.3,
    "isFinal": true
  },
  "fullTranscript": "Hello, this is a test recording"
}
```

### 3. Stopping the Recording

When recording stops:

1. **Client disconnects** WebSocket connection
2. **Server cleanup**:
   - Closes Deepgram connection
   - Updates recording status to `"processing"`
   - Sets recording end time
   - Final transcript is assembled from all "final" segments

### 4. Finalization Process

The finalization step (`POST /api/recordings/:recordingId/done`) transforms the
raw transcript into useful outputs:

1. **Validation**:
   - Checks if recording exists and has a transcript
   - Ensures recording hasn't already been processed

2. **AI Processing** (runs in parallel):

   a. **Bullet Point Summary**:
   - Sends transcript to Claude API
   - Extracts key points and action items
   - Returns structured bullet points

   b. **Visual Diagram**:
   - Generates ASCII art visualization
   - Creates a "napkin sketch" representing core concepts
   - Includes title and description

3. **Data Storage**:
   - Creates a `ProcessedRecording` object with all generated content
   - Stores in Deno KV under `["processed", recordingId]`
   - Updates recording status to `"completed"`

4. **Response**:
   - Returns the complete processed recording to client

## Data Models

### Recording States

- `recording` - Active recording in progress
- `processing` - Recording ended, awaiting finalization
- `completed` - Successfully processed with AI-generated content
- `error` - Processing failed

### RecordingData (During Recording)

```typescript
{
  id: string;
  startTime: Date;
  endTime?: Date;
  transcript: string;
  segments: TranscriptSegment[];
  status: "recording" | "processing" | "completed" | "error";
  error?: string;
  audioSize?: number;
  duration?: number;
}
```

### ProcessedRecording (After Finalization)

```typescript
{
  id: string;
  transcript: string;
  duration: number;
  bulletSummary: string[];
  diagram: {
    title: string;
    description: string;
    content: string;  // ASCII art
  };
  createdAt: Date;
  audioSize?: number;
}
```

## Error Handling

The system includes fallbacks at each stage:

1. **WebSocket Errors**: Graceful cleanup of connections
2. **Transcription Errors**: Client notified via error messages
3. **AI Processing Errors**: Falls back to placeholder content
4. **Network Failures**: Individual AI calls can fail without breaking entire
   flow

## Testing

Use the test page at `/api/test` to:

- Test microphone access
- Verify WebSocket connection
- See live transcription in action
- Test the complete recording → transcription → AI processing flow

## API Endpoints

- `GET /api/recordings/:recordingId/stream` - WebSocket endpoint for streaming
- `POST /api/recordings/:recordingId/done` - Finalize and process recording
- `GET /api/admin` - View all recordings and their status
- `GET /api/test` - Interactive test page

## Configuration

Required environment variables:

- `DEEPGRAM_API_KEY` - For audio transcription
- `ANTHROPIC_API_KEY` - For AI summarization and diagram generation
- `PORT` - Server port (default: 8000)
- `CORS_ORIGIN` - Allowed CORS origin (default: *)
