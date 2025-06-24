export interface DeepgramConfig {
  apiKey: string;
}

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
}

export interface TranscriptAlternative {
  transcript: string;
  confidence: number;
  words?: Array<{
    word: string;
    start: number;
    end: number;
    confidence: number;
  }>;
}

export interface TranscriptResponse {
  type: string;
  channel_index: number[];
  duration: number;
  start: number;
  is_final: boolean;
  speech_final: boolean;
  channel: {
    alternatives: TranscriptAlternative[];
  };
}

export class DeepgramClient {
  private apiKey: string;
  private baseUrl = "wss://api.deepgram.com/v1/listen";

  constructor(config: DeepgramConfig) {
    this.apiKey = config.apiKey;
  }

  connectLive(
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

    const url = `${this.baseUrl}?${params.toString()}`;

    console.log("Deepgram WebSocket URL:", url);

    // Create WebSocket connection using Sec-WebSocket-Protocol
    // Pass two separate protocol values: "token" and the API key
    const ws = new WebSocket(url, ["token", this.apiKey]);

    return Promise.resolve(ws);
  }
}
