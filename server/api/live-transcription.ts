import { Context } from "@hono/hono";
import { DeepgramClient, TranscriptResponse } from "../lib/deepgram.ts";

interface LiveTranscriptionMessage {
  type: "audio" | "config" | "stop";
  data?: ArrayBuffer | string;
  config?: {
    model?: string;
    language?: string;
  };
}

export async function liveTranscriptionHandler(
  c: Context,
): Promise<Response | void> {
  const upgradeHeader = c.req.header("upgrade");
  if (!upgradeHeader || upgradeHeader !== "websocket") {
    return c.text("Expected websocket connection", 426);
  }

  const { response, socket } = Deno.upgradeWebSocket(c.req.raw);

  handleWebSocketConnection(socket);

  return response;
}

function handleWebSocketConnection(clientWs: WebSocket) {
  let deepgramWs: WebSocket | null = null;
  let keepAliveInterval: number | null = null;

  clientWs.onopen = () => {
    console.log("Client WebSocket connected");
    initializeDeepgramConnection();
  };

  clientWs.onmessage = async (event) => {
    if (!deepgramWs || deepgramWs.readyState !== WebSocket.OPEN) {
      console.warn("Deepgram WebSocket not ready");
      return;
    }

    // Handle different message types
    if (event.data instanceof Blob) {
      // Audio data as Blob
      const arrayBuffer = await event.data.arrayBuffer();
      deepgramWs.send(arrayBuffer);
    } else if (typeof event.data === "string") {
      // Control messages
      try {
        const message: LiveTranscriptionMessage = JSON.parse(event.data);
        if (message.type === "stop") {
          closeDeepgramConnection();
        }
      } catch {
        // If not JSON, assume it's raw audio data
        deepgramWs.send(event.data);
      }
    } else if (event.data instanceof ArrayBuffer) {
      // Audio data as ArrayBuffer
      deepgramWs.send(event.data);
    }
  };

  clientWs.onclose = () => {
    console.log("Client WebSocket disconnected");
    closeDeepgramConnection();
  };

  clientWs.onerror = (error) => {
    console.error("Client WebSocket error:", error);
    closeDeepgramConnection();
  };

  async function initializeDeepgramConnection() {
    const deepgramApiKey = Deno.env.get("DEEPGRAM_API_KEY");
    if (!deepgramApiKey) {
      clientWs.send(JSON.stringify({
        type: "error",
        message: "Deepgram API key not configured",
      }));
      clientWs.close();
      return;
    }

    try {
      const deepgramClient = new DeepgramClient({ apiKey: deepgramApiKey });
      deepgramWs = await deepgramClient.connectLive({
        model: "nova-3",
        language: "en-US",
        smart_format: true,
        punctuate: true,
        profanity_filter: false,
        encoding: "linear16",
        sample_rate: 16000,
      });

      deepgramWs!.onopen = () => {
        console.log("Deepgram WebSocket connected");

        // Send keep-alive every 10 seconds
        keepAliveInterval = setInterval(() => {
          if (deepgramWs && deepgramWs.readyState === WebSocket.OPEN) {
            deepgramWs.send(JSON.stringify({ type: "KeepAlive" }));
          }
        }, 10000);

        clientWs.send(JSON.stringify({
          type: "ready",
          message: "Live transcription ready",
        }));
      };

      deepgramWs!.onmessage = (event) => {
        try {
          const response: TranscriptResponse = JSON.parse(event.data as string);

          // Only send transcripts with actual content
          if (response.channel?.alternatives?.[0]?.transcript) {
            clientWs.send(JSON.stringify({
              type: "transcript",
              transcript: response.channel.alternatives[0].transcript,
              is_final: response.is_final,
              speech_final: response.speech_final,
              confidence: response.channel.alternatives[0].confidence,
              duration: response.duration,
              start: response.start,
            }));
          }
        } catch (error) {
          console.error("Error parsing Deepgram response:", error);
        }
      };

      deepgramWs!.onclose = () => {
        console.log("Deepgram WebSocket closed");
        if (keepAliveInterval) {
          clearInterval(keepAliveInterval);
        }

        clientWs.send(JSON.stringify({
          type: "deepgram_closed",
          message: "Deepgram connection closed",
        }));
      };

      deepgramWs!.onerror = (error) => {
        console.error("Deepgram WebSocket error:", error);
        clientWs.send(JSON.stringify({
          type: "error",
          message: "Deepgram connection error",
        }));
      };
    } catch (error) {
      console.error("Failed to connect to Deepgram:", error);
      clientWs.send(JSON.stringify({
        type: "error",
        message: "Failed to initialize Deepgram connection",
      }));
      clientWs.close();
    }
  }

  function closeDeepgramConnection() {
    if (keepAliveInterval) {
      clearInterval(keepAliveInterval);
      keepAliveInterval = null;
    }

    if (deepgramWs) {
      deepgramWs.close();
      deepgramWs = null;
    }
  }
}
