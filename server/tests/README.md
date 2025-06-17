# Funnel API Tests

## Quick Start

1. Make sure the server is running:
   ```bash
   deno task dev
   ```

2. Run tests:
   ```bash
   # Test with the sample audio file
   deno task test:endpoint
   
   # Quick test with minimal audio
   deno task test:quick
   
   # Test error handling
   deno task test:errors
   
   # Run all tests
   deno task test:new-recording
   ```

## Test Audio File

The sample audio file is located at: `tests/fixtures/sample-audio-recording.m4a`

This file is used automatically when you run `deno task test:endpoint`.

## Manual Testing

### With curl:
```bash
./test-curl.sh tests/fixtures/sample-audio-recording.m4a
```

### With custom audio file:
```bash
TEST_AUDIO_PATH=/path/to/your/audio.m4a deno task test:endpoint
```

## What the Tests Check

- ✅ Successful audio transcription
- ✅ Bullet point summary generation  
- ✅ Diagram generation
- ✅ Proper error handling
- ✅ Response format validation