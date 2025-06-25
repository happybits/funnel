# Changelog

All notable changes to the Funnel API server will be documented in this file.

## [Unreleased] - 2024-12-25

### Added

#### Live Transcription with Deepgram

- Integrated Deepgram SDK (`@deepgram/sdk@^3.10.1`) for real-time audio
  transcription
- Added WebSocket endpoint `/api/recordings/:recordingId/stream` for streaming
  audio chunks
- Added POST endpoint `/api/recordings/:recordingId/done` for finalizing
  recordings
- Implemented Deno KV storage for managing recording sessions and transcripts
- Added support for live transcript segments during recording

#### Admin Interface

- Created admin dashboard at `/api/admin` showing all recordings
- Displays recording status (recording, processing, completed, failed)
- Shows duration, transcript preview, and timestamps
- Auto-refreshes every 5 seconds to show real-time updates

#### API Test Page

- Built interactive test page at `/api/test` for WebSocket testing
- Features audio visualization, live transcript display, and recording controls
- Supports both Chrome and Safari with proper audio format handling
- Includes WebSocket connection status and error handling

### Changed

#### Server Architecture

- Updated Deno configuration to use `nodeModulesDir: "auto"` for npm packages
- Added `--unstable-kv` flag to enable Deno KV functionality
- Migrated WebSocket handling from native Deno to Hono's WebSocket helper for
  better compatibility
- Updated all API responses to use consistent error handling patterns

#### iOS Client Updates

- Created `StreamingAudioRecorderManager` for real-time audio streaming
- Updated `RecordingManager` with streaming mode toggle (`isStreamingMode`)
- Added streaming methods: `startStreamingRecording()` and
  `finalizeStreamingRecording()`
- Modified `NewRecordingView` to support both streaming and file-based recording
  modes
- Extended `FunnelAPIService` with `finalizeStreamingRecording()` method
- Added WebSocket base URL configuration to `APIClient`

### Technical Details

#### WebSocket Protocol

- Client connects to `/api/recordings/:recordingId/stream`
- Server initializes Deepgram connection with `nova-2-general` model
- Audio chunks are sent as binary data (ArrayBuffer)
- Server responds with JSON messages:
  - `{"type": "ready"}` - Connection established
  - `{"type": "transcript", "segment": {...}}` - Live transcript updates
  - `{"type": "error", "message": "..."}` - Error notifications

#### Audio Configuration

- Sample rate: 16,000 Hz (optimized for speech)
- Channels: 1 (mono)
- Format: PCM 16-bit linear
- Encoding: `linear16` for Deepgram compatibility

#### Data Flow

1. iOS client generates UUID for recording session
2. Client establishes WebSocket connection with recording ID
3. Audio chunks stream to server in real-time
4. Server forwards audio to Deepgram for transcription
5. Transcript segments stored in Deno KV with recording ID
6. Client calls `/done` endpoint to finalize and generate AI summaries
7. Server returns complete transcript, bullet points, and diagram

### Developer Notes

#### Environment Variables

- `DEEPGRAM_API_KEY` - Required for live transcription (add to `.env`)
- Existing: `OPENAI_API_KEY`, `ANTHROPIC_API_KEY` still used for
  `/api/new-recording`

#### Deno KV Structure

```typescript
// Recording data stored at ["recordings", recordingId]
{
  id: string,
  startTime: Date,
  endTime?: Date,
  transcript: string,
  segments: TranscriptSegment[],
  status: "recording" | "processing" | "completed" | "error",
  audioSize?: number,
  duration?: number
}

// Processed data stored at ["processed", recordingId]
{
  id: string,
  transcript: string,
  duration: number,
  bulletSummary: string[],
  diagram: { title, description, content },
  createdAt: Date,
  audioSize?: number
}
```

#### WebSocket with Hono

- Use `upgradeWebSocket` from `@hono/hono/deno` for proper WebSocket handling
- Native `Deno.upgradeWebSocket()` doesn't work well with Hono's request
  handling
- Return WebSocket handlers object with `onOpen`, `onMessage`, `onClose`,
  `onError`

#### iOS Streaming Implementation

- `AVAudioEngine` captures audio in real-time
- Audio converted to PCM format matching Deepgram requirements
- WebSocket connection managed with `URLSessionWebSocketTask`
- Placeholder recording created in SwiftData during streaming
- Recording finalized with full data after processing

### Known Issues

- WebSocket connections may timeout after extended periods (implement
  reconnection logic)
- Large recordings may exceed Deno KV size limits (consider chunking strategy)
- iOS background audio recording permissions need proper configuration

### Future Improvements

- Add WebSocket reconnection logic with exponential backoff
- Implement audio chunk buffering for network interruptions
- Add progress indicators for processing stages
- Support multiple concurrent recordings per user
- Add audio compression before streaming to reduce bandwidth
- Implement partial transcript caching for resume functionality
