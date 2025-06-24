import { assertEquals, assertExists } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { delay } from "https://deno.land/std@0.224.0/async/delay.ts";
import { app } from "../main.ts";

Deno.test("Live transcription WebSocket connection", async () => {
  // Start server on random port
  const server = Deno.serve({ port: 0 }, app.fetch);
  const port = server.addr.port;

  // Wait a bit for server to start
  await delay(100);

  try {
    // Connect to WebSocket endpoint
    const ws = new WebSocket(`ws://localhost:${port}/api/live-transcription`);
    
    // Track messages received
    const messages: any[] = [];
    
    // Use promise to wait for connection
    await new Promise<void>((resolve, reject) => {
      ws.onopen = () => {
        resolve();
      };
      
      ws.onerror = (e) => {
        console.error("WebSocket error:", e);
        reject(e);
      };
      
      // Timeout after 5 seconds
      setTimeout(() => reject(new Error("Connection timeout")), 5000);
    });
    
    // Set up message handler
    ws.onmessage = (event) => {
      const data = JSON.parse(event.data);
      messages.push(data);
    };
    
    // Wait for ready message
    await delay(1000);
    
    // Should receive ready message
    const readyMessage = messages.find(m => m.type === "ready");
    assertExists(readyMessage, "Should receive ready message");
    assertEquals(readyMessage.message, "Live transcription ready");
    
    // Close connection
    ws.close();
    
  } finally {
    await server.shutdown();
  }
});

Deno.test("Live transcription with real audio", async () => {
  // This test requires Deepgram API key
  const deepgramKey = Deno.env.get("DEEPGRAM_API_KEY");
  if (!deepgramKey) {
    console.log("Skipping Deepgram test - no API key");
    return;
  }

  // Start server
  const server = Deno.serve({ port: 0 }, app.fetch);
  const port = server.addr.port;

  try {
    const ws = new WebSocket(`ws://localhost:${port}/api/live-transcription`);
    
    const messages: any[] = [];
    let isReady = false;
    
    ws.onmessage = (event) => {
      const data = JSON.parse(event.data);
      messages.push(data);
      if (data.type === "ready") {
        isReady = true;
      }
    };

    // Wait for ready
    let attempts = 0;
    while (!isReady && attempts < 50) {
      await delay(100);
      attempts++;
    }
    
    assertEquals(isReady, true, "Should be ready for transcription");

    // Read sample audio file
    const audioPath = new URL("./fixtures/sample-audio-recording.m4a", import.meta.url);
    const audioData = await Deno.readFile(audioPath);
    
    // Send audio in chunks (simulate streaming)
    const chunkSize = 16384; // 16KB chunks
    for (let i = 0; i < audioData.length; i += chunkSize) {
      const chunk = audioData.slice(i, Math.min(i + chunkSize, audioData.length));
      ws.send(chunk);
      await delay(50); // Simulate real-time streaming
    }
    
    // Wait for transcripts
    await delay(2000);
    
    // Check we received transcript messages
    const transcripts = messages.filter(m => m.type === "transcript");
    assertExists(transcripts.length > 0, "Should receive transcript messages");
    
    // Verify transcript structure
    const transcript = transcripts[0];
    assertExists(transcript.transcript, "Transcript should have text");
    assertExists(transcript.confidence !== undefined, "Should have confidence score");
    assertExists(transcript.is_final !== undefined, "Should have is_final flag");
    
    ws.close();
    
  } finally {
    await server.shutdown();
  }
});