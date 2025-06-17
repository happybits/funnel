import {
  assertEquals,
  assertExists,
} from "https://deno.land/std@0.215.0/assert/mod.ts";
import type { NewRecordingResponse, ErrorResponse } from "../types/api.ts";

// Skip these tests if API keys are not available
const OPENAI_API_KEY = Deno.env.get("OPENAI_API_KEY");
const ANTHROPIC_API_KEY = Deno.env.get("ANTHROPIC_API_KEY");
const skipIntegration = !OPENAI_API_KEY || !ANTHROPIC_API_KEY;

// Helper function to create a test audio file
async function createTestAudioFile(): Promise<File> {
  // Create a minimal valid WAV file (44 bytes)
  // This is a valid WAV file with no audio data
  const wavHeader = new Uint8Array([
    // "RIFF" chunk descriptor
    0x52, 0x49, 0x46, 0x46, // "RIFF"
    0x24, 0x00, 0x00, 0x00, // ChunkSize (36 bytes)
    0x57, 0x41, 0x56, 0x45, // "WAVE"
    
    // "fmt " sub-chunk
    0x66, 0x6D, 0x74, 0x20, // "fmt "
    0x10, 0x00, 0x00, 0x00, // Subchunk1Size (16 bytes)
    0x01, 0x00,             // AudioFormat (PCM)
    0x01, 0x00,             // NumChannels (1)
    0x44, 0xAC, 0x00, 0x00, // SampleRate (44100)
    0x88, 0x58, 0x01, 0x00, // ByteRate (88200)
    0x02, 0x00,             // BlockAlign (2)
    0x10, 0x00,             // BitsPerSample (16)
    
    // "data" sub-chunk
    0x64, 0x61, 0x74, 0x61, // "data"
    0x00, 0x00, 0x00, 0x00, // Subchunk2Size (0 bytes - no audio data)
  ]);
  
  const blob = new Blob([wavHeader], { type: "audio/wav" });
  return new File([blob], "test-audio.wav", { type: "audio/wav" });
}

Deno.test({
  name: "POST /api/new-recording - integration test with test audio file",
  ignore: skipIntegration,
  async fn() {
    console.log("\n🎤 Testing /api/new-recording endpoint...");
    
    // Create a test audio file
    const audioFile = await createTestAudioFile();
    
    // Create form data
    const formData = new FormData();
    formData.append("audio", audioFile);
    
    // Make request to the endpoint
    const res = await fetch("http://localhost:8000/api/new-recording", {
      method: "POST",
      body: formData,
    });
    
    // Check response status
    assertEquals(res.status, 200, "Expected 200 OK response");
    
    // Parse response body
    const body: NewRecordingResponse = await res.json();
    
    // Validate response structure
    assertExists(body.transcript, "Response should have transcript");
    assertExists(body.duration, "Response should have duration");
    assertExists(body.bulletSummary, "Response should have bulletSummary");
    assertExists(body.diagram, "Response should have diagram");
    assertExists(body.diagram.title, "Diagram should have title");
    assertExists(body.diagram.description, "Diagram should have description");
    assertExists(body.diagram.content, "Diagram should have content");
    
    // Validate types
    assertEquals(typeof body.transcript, "string", "Transcript should be string");
    assertEquals(typeof body.duration, "number", "Duration should be number");
    assertEquals(Array.isArray(body.bulletSummary), true, "BulletSummary should be array");
    assertEquals(typeof body.diagram.title, "string", "Diagram title should be string");
    assertEquals(typeof body.diagram.description, "string", "Diagram description should be string");
    assertEquals(typeof body.diagram.content, "string", "Diagram content should be string");
    
    // Log the results
    console.log("\n✅ Response received successfully!");
    console.log("\n📝 Transcript:", body.transcript || "(empty)");
    console.log("\n⏱️  Duration:", body.duration, "seconds");
    
    console.log("\n📋 Bullet Summary:");
    if (body.bulletSummary.length > 0) {
      body.bulletSummary.forEach((bullet, i) => {
        console.log(`  ${i + 1}. ${bullet}`);
      });
    } else {
      console.log("  (no bullet points)");
    }
    
    console.log("\n📊 Diagram:");
    console.log("  Title:", body.diagram.title);
    console.log("  Description:", body.diagram.description);
    console.log("  Content Preview:", body.diagram.content.substring(0, 100) + "...");
  },
});

Deno.test({
  name: "POST /api/new-recording - error handling for missing audio file",
  ignore: skipIntegration,
  async fn() {
    const formData = new FormData();
    // Don't append any audio file
    
    const res = await fetch("http://localhost:8000/api/new-recording", {
      method: "POST",
      body: formData,
    });
    
    assertEquals(res.status, 400, "Expected 400 Bad Request");
    
    const body: ErrorResponse = await res.json();
    assertExists(body.error);
    assertEquals(body.error, "No audio file provided");
  },
});

Deno.test({
  name: "POST /api/new-recording - error handling for invalid file type",
  ignore: skipIntegration,
  async fn() {
    const textFile = new File(["hello world"], "test.txt", { type: "text/plain" });
    
    const formData = new FormData();
    formData.append("audio", textFile);
    
    const res = await fetch("http://localhost:8000/api/new-recording", {
      method: "POST",
      body: formData,
    });
    
    assertEquals(res.status, 400, "Expected 400 Bad Request");
    
    const body: ErrorResponse = await res.json();
    assertExists(body.error);
    assertEquals(body.error, "Invalid file type");
    assertExists(body.details);
  },
});

// Test with a real audio file if provided via environment variable
const TEST_AUDIO_PATH = Deno.env.get("TEST_AUDIO_PATH");

if (TEST_AUDIO_PATH) {
  Deno.test({
    name: "POST /api/new-recording - integration test with real audio file",
    ignore: skipIntegration,
    async fn() {
      console.log(`\n🎵 Testing with real audio file: ${TEST_AUDIO_PATH}`);
      
      // Read the audio file
      const audioData = await Deno.readFile(TEST_AUDIO_PATH);
      const fileName = TEST_AUDIO_PATH.split("/").pop() || "audio.m4a";
      const mimeType = getMimeType(fileName);
      
      const audioFile = new File([audioData], fileName, { type: mimeType });
      
      // Create form data
      const formData = new FormData();
      formData.append("audio", audioFile);
      
      // Make request
      const res = await fetch("http://localhost:8000/api/new-recording", {
        method: "POST",
        body: formData,
      });
      
      assertEquals(res.status, 200, "Expected 200 OK response");
      
      const body: NewRecordingResponse = await res.json();
      
      // Real audio should produce meaningful results
      console.log("\n📝 Real Transcript:", body.transcript);
      console.log("\n⏱️  Real Duration:", body.duration, "seconds");
      
      console.log("\n📋 Real Bullet Summary:");
      body.bulletSummary.forEach((bullet, i) => {
        console.log(`  ${i + 1}. ${bullet}`);
      });
      
      console.log("\n📊 Real Diagram:");
      console.log("  Title:", body.diagram.title);
      console.log("  Description:", body.diagram.description);
      console.log("  Content:\n", body.diagram.content);
      
      // Validate real content
      assertEquals(body.transcript.length > 0, true, "Should have non-empty transcript");
      assertEquals(body.duration > 0, true, "Should have positive duration");
      assertEquals(body.bulletSummary.length > 0, true, "Should have bullet points");
    },
  });
}

function getMimeType(filename: string): string {
  const ext = filename.split(".").pop()?.toLowerCase();
  switch (ext) {
    case "mp3": return "audio/mpeg";
    case "mp4": return "audio/mp4";
    case "m4a": return "audio/m4a";
    case "wav": return "audio/wav";
    default: return "audio/mpeg";
  }
}

if (skipIntegration) {
  console.log("\n⚠️  Integration tests skipped - set OPENAI_API_KEY and ANTHROPIC_API_KEY to run them");
} else {
  console.log("\n🚀 Running integration tests...");
  console.log("Make sure the server is running: deno task dev");
  
  if (TEST_AUDIO_PATH) {
    console.log(`\n🎵 Will test with real audio file: ${TEST_AUDIO_PATH}`);
  } else {
    console.log("\n💡 Tip: Set TEST_AUDIO_PATH environment variable to test with a real audio file");
    console.log("   Example: TEST_AUDIO_PATH=/path/to/audio.m4a deno test tests/new-recording-test.ts");
  }
}