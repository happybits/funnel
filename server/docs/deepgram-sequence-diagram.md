# Deepgram Integration Sequence Diagram

```mermaid
sequenceDiagram
    participant iOS as iOS Client
    participant Server as Deno Server
    participant DG as Deepgram API
    participant KV as Deno KV

    Note over iOS,DG: Connection Setup
    iOS->>Server: WebSocket Connect /api/recordings/{id}/stream
    Server->>KV: Initialize recording
    Server->>DG: WebSocket Connect (with transcription options)
    DG->>Server: Connection Open
    Server->>iOS: {"type": "ready"}

    Note over iOS,DG: Audio Streaming
    loop For each audio chunk
        iOS->>Server: Audio chunk (PCM 16-bit, 16kHz)
        Server->>DG: Forward audio chunk
        DG->>Server: Transcript (interim/final)
        Server->>KV: Store transcript segment
        Server->>iOS: Forward transcript
    end

    Note over iOS,DG: Finalization Process
    iOS->>Server: POST /api/recordings/{id}/done
    Server->>DG: {"type": "CloseStream"}
    Note over DG: Process remaining audio
    DG->>Server: Final transcripts
    Server->>iOS: Forward transcripts
    DG->>Server: {"type": "Metadata", "duration": 32.5}
    Server->>iOS: Forward Metadata
    Server->>KV: Update recording status
    Server->>iOS: ProcessedRecording response
    
    Note over iOS: Wait for Metadata before closing
    iOS->>Server: WebSocket Close
    Server->>DG: Connection cleanup
```

## Key Points Illustrated

1. **Parallel Communication**: The server forwards transcripts to the client while still receiving audio
2. **Finalization Trigger**: The client initiates finalization via REST endpoint, not WebSocket
3. **CloseStream Flow**: Server sends CloseStream and waits for Metadata confirmation
4. **Client Patience**: Client waits for Metadata before closing WebSocket
5. **Complete Transcript**: The ProcessedRecording includes all segments received before Metadata

## Timing Considerations

- Audio streaming: ~100ms between chunks
- Transcript latency: ~500ms from audio to transcript
- Finalization: Can take several seconds depending on buffered audio
- Metadata response: Arrives after all transcripts are sent