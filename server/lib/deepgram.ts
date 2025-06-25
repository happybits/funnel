import {
  createClient,
  DeepgramClient as SDKDeepgramClient,
  LiveTranscriptionEvents,
} from "@deepgram/sdk";

// Re-export types from SDK
export { LiveTranscriptionEvents } from "@deepgram/sdk";
export type { DeepgramClient as SDKDeepgramClient } from "@deepgram/sdk";

// Initialize Deepgram client
export function getDeepgramClient(): SDKDeepgramClient {
  const apiKey = Deno.env.get("DEEPGRAM_API_KEY");
  if (!apiKey) {
    throw new Error("DEEPGRAM_API_KEY not configured");
  }
  return createClient(apiKey);
}

// Live transcription options matching Deepgram SDK
export interface LiveTranscriptionOptions {
  model?: string;
  language?: string;
  smart_format?: boolean;
  punctuate?: boolean;
  profanity_filter?: boolean;
  redact?: boolean;
  diarize?: boolean;
  encoding?: string;
  channels?: number;
  sample_rate?: number;
  endpointing?: number | false;
  interim_results?: boolean;
  utterance_end_ms?: number;
  vad_events?: boolean;
}

// Legacy export for compatibility with existing code
export class DeepgramClient {
  private apiKey: string;
  private baseUrl = "wss://api.deepgram.com/v1/listen";

  constructor(config: { apiKey: string }) {
    this.apiKey = config.apiKey;
  }

  async connectLive(
    options: LiveTranscriptionOptions = {},
  ): Promise<WebSocket> {
    const defaultOptions: LiveTranscriptionOptions = {
      model: "nova-2",
      language: "en-US",
      smart_format: true,
      punctuate: true,
      ...options,
    };

    // Build query string
    const params = new URLSearchParams();
    Object.entries(defaultOptions).forEach(([key, value]) => {
      if (value !== undefined) {
        params.append(key, String(value));
      }
    });

    // Add API key to URL params for WebSocket auth
    const url = `${this.baseUrl}?${params.toString()}&token=${this.apiKey}`;

    // Create WebSocket connection
    const ws = new WebSocket(url);

    return ws;
  }
}

// Legacy TranscriptResponse type
export interface TranscriptResponse {
  type: string;
  channel_index: number[];
  duration: number;
  start: number;
  is_final: boolean;
  speech_final: boolean;
  channel: {
    alternatives: {
      transcript: string;
      confidence: number;
      words?: Array<{
        word: string;
        start: number;
        end: number;
        confidence: number;
      }>;
    }[];
  };
}

// Default options for live transcription
export const DEFAULT_TRANSCRIPTION_OPTIONS: LiveTranscriptionOptions = {
  model: "nova-2-general", // Using latest model as requested
  language: "en-US",
  smart_format: true,
  punctuate: true,
  profanity_filter: false,
  // Remove encoding and sample_rate to let Deepgram auto-detect from WebM/Opus
  // encoding: "linear16",
  // sample_rate: 16000,
  endpointing: 500,
  interim_results: true,
  utterance_end_ms: 1000,
  vad_events: false,
};

// Recording data structure for Deno KV
export interface RecordingData {
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

export interface TranscriptSegment {
  text: string;
  confidence: number;
  start: number;
  end: number;
  isFinal: boolean;
}
