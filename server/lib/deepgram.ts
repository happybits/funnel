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
      model: "nova-3",
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
  model: "nova-3", // Using latest Nova 3 model
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

// Raw transcript event from Deepgram (stored verbatim)
export interface TranscriptEvent {
  type: string;
  channel_index: number[];
  duration: number;
  start: number;
  is_final: boolean;
  speech_final: boolean;
  channel: {
    alternatives: Array<{
      transcript: string;
      confidence: number;
      words?: Array<{
        word: string;
        start: number;
        end: number;
        confidence: number;
        punctuated_word?: string;
      }>;
    }>;
  };
  metadata?: any;
  from_finalize?: boolean;
  // Store when we received this event
  receivedAt: Date;
}

// Recording data structure for Deno KV
export interface RecordingData {
  id: string;
  startTime: Date;
  endTime?: Date;
  transcript: string;
  segments: TranscriptSegment[]; // Keep for backward compatibility
  events: TranscriptEvent[]; // Store raw events
  status: "recording" | "finalizing" | "processing" | "completed" | "error";
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

// Compute full transcript from events
export function computeTranscriptFromEvents(events: TranscriptEvent[]): string {
  // Filter for final events with non-empty transcripts
  const finalEvents = events
    .filter((e) =>
      e.is_final &&
      e.channel?.alternatives?.[0]?.transcript?.trim()
    )
    .sort((a, b) => a.start - b.start);

  // Build transcript from non-overlapping segments
  const segments: { start: number; end: number; text: string }[] = [];

  for (const event of finalEvents) {
    const transcript = event.channel.alternatives[0].transcript.trim();
    if (!transcript) continue;

    const start = event.start;
    const end = event.start + event.duration;

    // Check if this segment overlaps with the last one
    if (segments.length > 0) {
      const lastSegment = segments[segments.length - 1];
      if (start < lastSegment.end) {
        // Overlapping segment - skip or merge based on which is longer
        if (end > lastSegment.end) {
          // This segment extends beyond the last one, update it
          lastSegment.text = transcript;
          lastSegment.end = end;
        }
        // Otherwise skip this segment as it's fully contained
        continue;
      }
    }

    segments.push({ start, end, text: transcript });
  }

  // Join all segments with spaces
  return segments.map((s) => s.text).join(" ").trim();
}
