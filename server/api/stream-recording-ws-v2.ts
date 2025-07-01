import type { Context } from "@hono/hono";

/**
 * Simplified WebSocket streaming endpoint that receives audio chunks from iOS client
 * and streams them to Deepgram. No partial transcripts are sent back to the client.
 * 
 * URL: /api/v2/recordings/:recordingId/stream
 */

// Store active Deepgram connections
export const activeDeepgramConnections = new Map<string, {
  deepgramWs: WebSocket;
  transcriptSegments: Array<{
    text: string;
    isFinal: boolean;
    start: number;
    end: number;
  }>;
  metadata?: any;
  isFinalized: boolean;
}>();

export const streamRecordingWsV2Handler = (c: Context) => {
  const recordingId = c.req.param("recordingId");
  
  // Check if this is a WebSocket upgrade request
  const upgradeHeader = c.req.header("upgrade");
  if (!upgradeHeader || upgradeHeader.toLowerCase() !== "websocket") {
    return c.json({ error: "WebSocket upgrade required" }, 400);
  }

  // Get the raw request to upgrade to WebSocket
  const { response, socket } = Deno.upgradeWebSocket(c.req.raw);
  const clientWs = socket;

  // Initialize Deepgram connection
  const deepgramUrl = new URL("wss://api.deepgram.com/v1/listen");
  deepgramUrl.searchParams.set("punctuate", "true");
  deepgramUrl.searchParams.set("interim_results", "false"); // Only final results
  deepgramUrl.searchParams.set("model", "nova-2");
  deepgramUrl.searchParams.set("language", "en-US");
  deepgramUrl.searchParams.set("encoding", "linear16");
  deepgramUrl.searchParams.set("sample_rate", "16000");
  deepgramUrl.searchParams.set("channels", "1");

  const deepgramApiKey = Deno.env.get("DEEPGRAM_API_KEY");
  if (!deepgramApiKey) {
    clientWs.send(JSON.stringify({ type: "error", message: "Deepgram API key not configured" }));
    return response;
  }

  const deepgramWs = new WebSocket(deepgramUrl.href, {
    headers: {
      Authorization: `Token ${deepgramApiKey}`,
    },
  });

  const connectionData = {
    deepgramWs,
    transcriptSegments: [] as Array<{
      text: string;
      isFinal: boolean;
      start: number;
      end: number;
    }>,
    metadata: undefined,
    isFinalized: false,
  };

  activeDeepgramConnections.set(recordingId, connectionData);

  // Handle Deepgram connection open
  deepgramWs.addEventListener("open", () => {
    console.log(`Deepgram connected for recording ${recordingId}`);
    // Notify client that streaming is ready
    clientWs.send(JSON.stringify({ type: "ready" }));
  });

  // Handle Deepgram messages
  deepgramWs.addEventListener("message", (event) => {
    try {
      const data = JSON.parse(event.data);
      
      if (data.type === "Results" && data.channel?.alternatives?.[0]) {
        const alternative = data.channel.alternatives[0];
        if (alternative.transcript && data.is_final) {
          // Store only final transcript segments
          connectionData.transcriptSegments.push({
            text: alternative.transcript,
            isFinal: true,
            start: data.start || 0,
            end: data.start + data.duration || 0,
          });
        }
      } else if (data.type === "Metadata") {
        console.log(`Received metadata for recording ${recordingId}:`, data);
        connectionData.metadata = data;
        
        // Notify client that processing is complete
        clientWs.send(JSON.stringify({ 
          type: "processingComplete",
          duration: data.duration 
        }));
      }
    } catch (error) {
      console.error("Error parsing Deepgram response:", error);
    }
  });

  // Handle Deepgram errors
  deepgramWs.addEventListener("error", (error) => {
    console.error(`Deepgram error for recording ${recordingId}:`, error);
    clientWs.send(JSON.stringify({ 
      type: "error", 
      message: "Transcription service error" 
    }));
  });

  // Handle Deepgram close
  deepgramWs.addEventListener("close", () => {
    console.log(`Deepgram connection closed for recording ${recordingId}`);
  });

  // Handle client messages (audio chunks)
  clientWs.addEventListener("message", (event) => {
    if (event.data instanceof ArrayBuffer || event.data instanceof Blob) {
      // Forward audio data to Deepgram
      if (deepgramWs.readyState === WebSocket.OPEN) {
        deepgramWs.send(event.data);
      }
    } else {
      try {
        const message = JSON.parse(event.data);
        console.log(`Received message from client:`, message);
      } catch {
        // Not JSON, ignore
      }
    }
  });

  // Handle client disconnect
  clientWs.addEventListener("close", () => {
    console.log(`Client disconnected for recording ${recordingId}`);
    
    // Clean up Deepgram connection if not finalized
    if (!connectionData.isFinalized && deepgramWs.readyState === WebSocket.OPEN) {
      deepgramWs.close();
    }
    
    // Remove from active connections after a delay to allow finalization
    setTimeout(() => {
      if (!connectionData.isFinalized) {
        activeDeepgramConnections.delete(recordingId);
      }
    }, 30000); // Keep for 30 seconds
  });

  // Handle client errors
  clientWs.addEventListener("error", (error) => {
    console.error(`Client WebSocket error for recording ${recordingId}:`, error);
  });

  return response;
};