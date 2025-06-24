import { DeepgramSDKClient, type LiveSchema } from "../lib/deepgram-sdk.ts";
import { TranscriptResponse } from "../lib/deepgram.ts";

interface LiveTranscriptionMessage {
  type: "audio" | "config" | "stop";
  data?: ArrayBuffer | string;
  config?: {
    model?: string;
    language?: string;
  };
}

export function liveTranscriptionHandler(req: Request): Response {
  const { socket: clientWs, response } = Deno.upgradeWebSocket(req);
  
  let deepgramWs: WebSocket | null = null;
  let keepAliveInterval: number | null = null;

  clientWs.onopen = () => {
    console.log("Client WebSocket connected");
    
    // Send immediate acknowledgment
    clientWs.send(JSON.stringify({
      type: "connected",
      message: "Connected to server, initializing Deepgram...",
    }));
    
    initializeDeepgramConnection(req);
  };

  clientWs.onmessage = async (event) => {
    // Log the type of data received
    const dataType = event.data instanceof Blob ? "Blob" : 
                     event.data instanceof ArrayBuffer ? "ArrayBuffer" : 
                     typeof event.data;
    console.log("Received data type:", dataType, "size:", event.data?.size || event.data?.byteLength || event.data?.length);
    
    if (!deepgramWs || deepgramWs.readyState !== WebSocket.OPEN) {
      console.warn("Deepgram WebSocket not ready");
      return;
    }

    // Handle different message types
    if (event.data instanceof Blob) {
      // Audio data as Blob - common from browsers
      console.log("Processing Blob data, size:", event.data.size);
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
        // If not JSON, might be base64 audio data
        console.log("Received string data, attempting to send to Deepgram");
        deepgramWs.send(event.data);
      }
    } else if (event.data instanceof ArrayBuffer) {
      // Audio data as ArrayBuffer
      console.log("Processing ArrayBuffer data, size:", event.data.byteLength);
      deepgramWs.send(event.data);
    } else {
      console.warn("Unknown data type received:", event.data);
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

  async function initializeDeepgramConnection(request: Request) {
    const deepgramApiKey = Deno.env.get("DEEPGRAM_API_KEY");
    console.log("Deepgram API key found:", deepgramApiKey ? `${deepgramApiKey.substring(0, 8)}...` : "NOT FOUND");
    
    if (!deepgramApiKey) {
      console.error("DEEPGRAM_API_KEY not found in environment");
      clientWs.send(JSON.stringify({
        type: "error",
        message: "Deepgram API key not configured",
      }));
      return;
    }

    try {
      const deepgramClient = new DeepgramSDKClient(deepgramApiKey);
      
      // Check if this is a browser client (they send WebM/Opus)
      // iOS app sends PCM (linear16)
      const userAgent = request.headers.get("user-agent") || "";
      const isBrowser = userAgent.includes("Mozilla");
      console.log("User agent:", userAgent);
      console.log("Is browser?", isBrowser, "- Using encoding:", isBrowser ? "webm-opus" : "linear16");
      
      // For browsers, we need to omit encoding and let Deepgram auto-detect
      // Deepgram can handle WebM/Opus without specifying the encoding
      const options: LiveSchema = {
        model: "nova-2",
        language: "en-US",
        smart_format: true,
        punctuate: true,
        profanity_filter: false,
        interim_results: true,
        utterance_end_ms: 1000,
        vad_events: true,
        endpointing: 300,
      };
      
      // Only specify encoding for iOS (PCM data)
      if (!isBrowser) {
        options.encoding = "linear16";
        options.sample_rate = 16000;
      }
      
      deepgramWs = await deepgramClient.connectLive(options);

      deepgramWs.onopen = () => {
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

      deepgramWs.onmessage = (event) => {
        console.log("Received Deepgram response:", event.data);
        try {
          const response: TranscriptResponse = JSON.parse(event.data as string);
          
          // Only send transcripts with actual content
          if (response.channel?.alternatives?.[0]?.transcript) {
            console.log("Sending transcript to client:", response.channel.alternatives[0].transcript);
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

      deepgramWs.onclose = () => {
        console.log("Deepgram WebSocket closed");
        if (keepAliveInterval) {
          clearInterval(keepAliveInterval);
        }
        
        clientWs.send(JSON.stringify({
          type: "deepgram_closed",
          message: "Deepgram connection closed",
        }));
      };

      deepgramWs.onerror = (error) => {
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

  return response;
}