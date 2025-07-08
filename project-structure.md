# Funnel Project Structure

## Overview
Funnel is an audio note summarizer with an iOS client and Deno server that processes audio recordings through AI services for transcription and summarization.

## Tech Stack
- **Server**: Deno + Hono framework (TypeScript)
- **Client**: SwiftUI + SwiftData
- **AI Services**: OpenAI Whisper, Anthropic Claude, Deepgram

## Server Structure (`/server`)

### API Endpoints
- `POST /api/new-recording` - Upload complete audio files for processing
- `WS /api/live-transcription` - WebSocket for real-time transcription
- `WS /api/stream-recording-ws` - Stream audio chunks during recording
- `POST /api/finalize-recording/:sessionId` - Finalize streamed recordings
- `GET /admin` - Admin interface
- `GET /test-page` - Testing interface

### Core Libraries (`/lib`)
- `openai.ts` - Whisper transcription client
- `anthropic.ts` - Claude summarization client
- `deepgram.ts` - Real-time transcription client
- `ai-processing.ts` - Orchestrates AI pipeline
- `/prompts/` - AI prompt templates

### Types
- `types/api.ts` - TypeScript interfaces for API contracts

## iOS Client Structure (`/Funnel`)

### Core Components
- `FunnelApp.swift` - App entry with SwiftData setup
- `ContentView.swift` - Root navigation

### Models
- `Recording.swift` - SwiftData model
- `APIModels.swift` - API response types
- `FunnelError.swift` - Error handling

### Views
- `NewRecordingView.swift` - Recording interface
- `SwipeableCardsView.swift` - Card UI for recordings
- `Components/` - Reusable UI components

### Services
- `APIClient.swift` - Network layer
- `DeepgramClient.swift` - WebSocket client
- `AudioRecorderManager.swift` - Audio recording orchestration

### Audio Sources
- `MicrophoneAudioSource.swift` - Live recording
- `FilePlaybackAudioSource.swift` - File playback

## Key Workflows

### Recording Modes
1. **File Upload**: Record → Upload → Transcribe → Summarize
2. **Live Stream**: Stream while recording → Real-time transcription → Finalize

### AI Processing Pipeline
```
Audio → Whisper (transcription) → Claude (summary + diagram)
```

### Development Commands
Both iOS and server use Makefiles:
- `make dev` - Start development server
- `make test` - Run tests
- `make format` - Format code
- `make lint` - Run linters
- `make build` - Build project

## Data Flow
1. iOS client records audio
2. Sends to server via HTTP/WebSocket
3. Server processes through AI services
4. Returns transcription and summary
5. iOS client stores in SwiftData

## Configuration
- Server: `deno.json` for Deno config
- iOS: Xcode project with multiple schemes
- Both: Makefile for development workflow