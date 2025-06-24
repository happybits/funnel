import { createClient, LiveTranscriptionEvents, type DeepgramClient, type LiveSchema } from "npm:@deepgram/sdk@3.9.0";

export class DeepgramSDKClient {
  private client: DeepgramClient;

  constructor(apiKey: string) {
    this.client = createClient(apiKey);
  }

  async connectLive(options: LiveSchema) {
    // Get the live transcription connection
    const connection = this.client.listen.live(options);

    // Return a wrapper that matches our existing WebSocket-like interface
    return new Promise<WebSocket>((resolve, reject) => {
      const wsWrapper = {
        readyState: WebSocket.CONNECTING,
        send: (data: string | ArrayBuffer) => {
          if (data instanceof ArrayBuffer || typeof data === "string") {
            connection.send(data);
          }
        },
        close: () => {
          connection.finish();
        },
        // Event handlers will be set by the caller
        onopen: null as ((event: Event) => void) | null,
        onmessage: null as ((event: MessageEvent) => void) | null,
        onclose: null as ((event: CloseEvent) => void) | null,
        onerror: null as ((event: Event) => void) | null,
      } as unknown as WebSocket;

      connection.on(LiveTranscriptionEvents.Open, () => {
        wsWrapper.readyState = WebSocket.OPEN;
        if (wsWrapper.onopen) {
          wsWrapper.onopen(new Event("open"));
        }
        resolve(wsWrapper);
      });

      connection.on(LiveTranscriptionEvents.Transcript, (data) => {
        if (wsWrapper.onmessage) {
          wsWrapper.onmessage(new MessageEvent("message", { 
            data: JSON.stringify(data) 
          }));
        }
      });

      connection.on(LiveTranscriptionEvents.Close, () => {
        wsWrapper.readyState = WebSocket.CLOSED;
        if (wsWrapper.onclose) {
          wsWrapper.onclose(new CloseEvent("close"));
        }
      });

      connection.on(LiveTranscriptionEvents.Error, (error) => {
        if (wsWrapper.onerror) {
          const errorEvent = new Event("error");
          (errorEvent as any).error = error;
          wsWrapper.onerror(errorEvent);
        }
        reject(error);
      });
    });
  }
}

export { LiveTranscriptionEvents, type LiveSchema };