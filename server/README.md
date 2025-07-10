# Funnel API Server

Backend API for the Funnel audio note summarizer app built with Deno.

## Documentation

- [Deepgram Integration Guide](./docs/deepgram-integration.md) - How we use
  Deepgram for real-time transcription
- [Deepgram Sequence Diagram](./docs/deepgram-sequence-diagram.md) - Visual flow
  of the transcription process
- [Recording Flow](./docs/recording-flow.md) - Overall recording and processing
  flow

## Setup

1. Copy `.env.example` to `.env` and add your API keys:
   ```bash
   cp .env.example .env
   ```

2. Add your API keys to `.env`:
   - `OPENAI_API_KEY` - For Whisper audio transcription
   - `ANTHROPIC_API_KEY` - For Claude text summarization

## Development

Run the development server with auto-reload:

```bash
deno task dev
```

## API Endpoints

### POST /api/transcribe

Transcribes audio files using OpenAI Whisper.

**Request:**

- Method: `POST`
- Content-Type: `multipart/form-data`
- Body: `audio` field with audio file (mp3, mp4, wav, m4a)
- Max file size: 25MB

**Response:**

```json
{
  "transcript": "The transcribed text...",
  "duration": 123.45
}
```

### POST /api/summarize

Generates bullet point summary using Anthropic Claude.

**Request:**

- Method: `POST`
- Content-Type: `application/json`
- Body:

```json
{
  "transcript": "The text to summarize..."
}
```

**Response:**

```json
{
  "bulletSummary": [
    "First key point",
    "Second key point",
    "Action item or task"
  ]
}
```

## Deployment

### Deno Deploy

1. Create a new project on [Deno Deploy](https://deno.com/deploy)
2. Set environment variables in the project settings:
   - `OPENAI_API_KEY`
   - `ANTHROPIC_API_KEY`
3. Deploy using GitHub integration or Deno Deploy CLI

### Self-hosting

Run in production:

```bash
deno task start
```

## Scripts

- `deno task dev` - Run development server with watch mode
- `deno task start` - Run production server
- `deno task fmt` - Format code
- `deno task lint` - Lint code
- `deno task check` - Type check
- `deno task precommit` - Run all checks before committing
