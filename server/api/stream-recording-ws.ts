import { Context } from "@hono/hono";
import {
  DEFAULT_TRANSCRIPTION_OPTIONS,
  getDeepgramClient,
  LiveTranscriptionEvents,
  RecordingData,
  TranscriptSegment,
} from "../lib/deepgram.ts";

const kv = await Deno.openKv();

// In-memory storage for recording segments to prevent KV overwrite issues
const recordingSegments = new Map<string, TranscriptSegment[]>();

// In-memory storage for active Deepgram connections
export const activeDeepgramConnections = new Map<string, any>();

export function streamRecordingWsHandler(c: Context): Response {
  console.log(`WebSocket upgrade request for path: ${c.req.path}`);

  // Check for WebSocket upgrade
  const upgradeHeader = c.req.header("upgrade");
  if (!upgradeHeader || upgradeHeader !== "websocket") {
    return c.text("Expected websocket connection", 426);
  }

  const recordingId = c.req.param("recordingId");
  if (!recordingId) {
    return c.text("Recording ID is required", 400);
  }

  // Use native Deno WebSocket upgrade
  const { response, socket } = Deno.upgradeWebSocket(c.req.raw);

  handleWebSocketConnection(socket, recordingId);

  return response;
}

function handleWebSocketConnection(ws: WebSocket, recordingId: string) {
  let deepgramConnection: any = null;
  let audioBuffer: Uint8Array = new Uint8Array(0);
  let isClosing = false;
  let isConfigured = false;
  // let audioFormat = "auto"; // auto-detect by default

  ws.onopen = async () => {
    console.log(`Client WebSocket connected for recording ${recordingId}`);

    // Initialize in-memory segments array
    recordingSegments.set(recordingId, []);

    // Initialize recording in KV
    const recording: RecordingData = {
      id: recordingId,
      startTime: new Date(),
      transcript: "",
      segments: [],
      status: "recording",
      audioSize: 0,
    };

    await kv.set(["recordings", recordingId], recording);
  };

  // Helper function to initialize Deepgram with appropriate settings
  const initializeDeepgram = (options: any = {}) => {
    try {
      const deepgram = getDeepgramClient();
      console.log(
        `Initializing Deepgram connection for recording ${recordingId} with options:`,
        options,
      );

      // Merge with default options
      const transcriptionOptions = {
        ...DEFAULT_TRANSCRIPTION_OPTIONS,
        ...options,
      } as any;

      // Cast to any to avoid type mismatch with SDK
      deepgramConnection = deepgram.listen.live(transcriptionOptions);
      
      // Store the connection for access from finalize endpoint
      activeDeepgramConnections.set(recordingId, deepgramConnection);

      // Handle transcription events
      deepgramConnection.on(LiveTranscriptionEvents.Open, () => {
        console.log(
          `Deepgram connection opened for recording ${recordingId}`,
        );
        ws.send(JSON.stringify({
          type: "ready",
          message: "Live transcription ready",
        }));
      });

      deepgramConnection.on(
        LiveTranscriptionEvents.Transcript,
        async (data: any) => {
          console.log(
            `Deepgram transcript event for recording ${recordingId}:`,
            JSON.stringify(data, null, 2),
          );
          const transcript = data.channel?.alternatives?.[0];

          if (transcript && transcript.transcript) {
            console.log(
              `Got transcript text: "${transcript.transcript}" (final: ${data.is_final})`,
            );
            const segment: TranscriptSegment = {
              text: transcript.transcript,
              confidence: transcript.confidence || 0,
              start: data.start || 0,
              end: data.start + data.duration || 0,
              isFinal: data.is_final || false,
            };

            // Get in-memory segments array
            const segments = recordingSegments.get(recordingId) || [];
            segments.push(segment);
            recordingSegments.set(recordingId, segments);

            // Build full transcript from all final segments
            const fullTranscript = segments
              .filter((s) => s.isFinal)
              .map((s) => s.text)
              .join(" ");

            // Update recording in KV with the latest data
            const current = await kv.get<RecordingData>([
              "recordings",
              recordingId,
            ]);
            if (current.value) {
              // Update with all segments and the full transcript
              current.value.segments = segments;
              current.value.transcript = fullTranscript;
              await kv.set(["recordings", recordingId], current.value);
            }

            // Send transcript update to client
            ws.send(JSON.stringify({
              type: "transcript",
              segment,
              fullTranscript,
            }));
          }
        },
      );

      deepgramConnection.on(LiveTranscriptionEvents.Error, (error: any) => {
        console.error(`Deepgram error for recording ${recordingId}:`, error);
        ws.send(JSON.stringify({
          type: "error",
          message: "Transcription error occurred",
        }));
      });

      deepgramConnection.on(LiveTranscriptionEvents.Close, () => {
        console.log(
          `Deepgram connection closed for recording ${recordingId}`,
        );
        // Remove from active connections
        activeDeepgramConnections.delete(recordingId);
      });

      // Add metadata event handler to forward to client
      deepgramConnection.on(LiveTranscriptionEvents.Metadata, (data: any) => {
        console.log(`Deepgram metadata for recording ${recordingId}:`, data);
        
        // Forward metadata to client, especially the final one with duration: 0
        if (ws.readyState === WebSocket.OPEN) {
          ws.send(JSON.stringify({
            type: "Metadata",
            ...data
          }));
        }
      });

      // Add utterance end event handler
      deepgramConnection.on(
        LiveTranscriptionEvents.UtteranceEnd,
        (data: any) => {
          console.log(
            `Deepgram utterance end for recording ${recordingId}:`,
            data,
          );
        },
      );
    } catch (error) {
      console.error(
        `Failed to initialize Deepgram for recording ${recordingId}:`,
        error,
      );
      ws.send(JSON.stringify({
        type: "error",
        message: "Failed to initialize transcription",
        details: error instanceof Error ? error.message : String(error),
      }));
      ws.close();
    }
  };

  ws.onmessage = async (event) => {
    if (isClosing) return;

    try {
      // Handle string messages (config)
      if (typeof event.data === "string") {
        try {
          const message = JSON.parse(event.data);
          if (message.type === "config") {
            console.log(
              `Received config for recording ${recordingId}:`,
              message,
            );

            // Initialize Deepgram with PCM settings if specified
            if (message.format === "pcm16") {
              initializeDeepgram({
                encoding: "linear16",
                sample_rate: message.sampleRate || 44100,
                channels: message.channels || 1,
              });
            } else {
              // Default initialization for other formats
              initializeDeepgram();
            }
            isConfigured = true;
            return;
          }
        } catch (_e) {
          console.log(`Received non-JSON string message: ${event.data}`);
        }
      }

      // If not configured yet and receiving audio data, auto-configure
      if (!isConfigured && !deepgramConnection) {
        console.log(`Auto-configuring Deepgram for recording ${recordingId}`);
        initializeDeepgram(); // Use defaults for auto-detection
        isConfigured = true;
      }

      if (!deepgramConnection) return;

      console.log(
        `Received audio data for recording ${recordingId}, type: ${typeof event
          .data}, size: ${
          event.data instanceof ArrayBuffer
            ? event.data.byteLength
            : event.data instanceof Blob
            ? event.data.size
            : "unknown"
        }`,
      );

      // Handle audio data
      if (event.data instanceof ArrayBuffer) {
        const audioData = new Uint8Array(event.data);
        audioBuffer = concatUint8Arrays(audioBuffer, audioData) as Uint8Array;
      } else if (event.data instanceof Blob) {
        // Handle Blob data (convert to ArrayBuffer)
        const arrayBuffer = await event.data.arrayBuffer();
        const audioData = new Uint8Array(arrayBuffer);
        audioBuffer = concatUint8Arrays(audioBuffer, audioData) as Uint8Array;
      }

      // Update audio size in KV
      const current = await kv.get<RecordingData>([
        "recordings",
        recordingId,
      ]);
      if (current.value) {
        current.value.audioSize = audioBuffer.length;
        await kv.set(["recordings", recordingId], current.value);
      }

      // Send to Deepgram
      if (event.data instanceof ArrayBuffer) {
        console.log(
          `Sending ArrayBuffer to Deepgram, size: ${event.data.byteLength}`,
        );
        deepgramConnection.send(event.data);
      } else if (event.data instanceof Blob) {
        const arrayBuffer = await event.data.arrayBuffer();
        console.log(
          `Sending Blob (converted to ArrayBuffer) to Deepgram, size: ${arrayBuffer.byteLength}`,
        );
        deepgramConnection.send(arrayBuffer);
      }
    } catch (error) {
      console.error(
        `Error processing message for recording ${recordingId}:`,
        error,
      );
    }
  };

  ws.onclose = async () => {
    console.log(`Client WebSocket disconnected for recording ${recordingId}`);
    isClosing = true;

    if (deepgramConnection) {
      deepgramConnection.finish();
    }

    // Update recording status
    const current = await kv.get<RecordingData>(["recordings", recordingId]);
    if (current.value && current.value.status === "recording") {
      current.value.status = "processing";
      current.value.endTime = new Date();
      await kv.set(["recordings", recordingId], current.value);
    }

    // Clean up in-memory segments to prevent memory leaks
    recordingSegments.delete(recordingId);
    // Also remove from active connections if still there
    activeDeepgramConnections.delete(recordingId);
  };

  ws.onerror = (event) => {
    console.error(
      `Client WebSocket error for recording ${recordingId}:`,
      event,
    );
    isClosing = true;

    if (deepgramConnection) {
      deepgramConnection.finish();
    }

    // Clean up in-memory segments on error as well
    recordingSegments.delete(recordingId);
  };
}

function concatUint8Arrays(a: Uint8Array, b: Uint8Array): Uint8Array {
  const result = new Uint8Array(a.length + b.length);
  result.set(new Uint8Array(a), 0);
  result.set(new Uint8Array(b), a.length);
  return result;
}
