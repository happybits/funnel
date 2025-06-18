import {
  assertEquals,
  assertExists,
} from "https://deno.land/std@0.215.0/assert/mod.ts";
import type { ErrorResponse, NewRecordingResponse } from "../types/api.ts";

// Skip these tests if API keys are not available
const OPENAI_API_KEY = Deno.env.get("OPENAI_API_KEY");
const ANTHROPIC_API_KEY = Deno.env.get("ANTHROPIC_API_KEY");
const skipIntegration = !OPENAI_API_KEY || !ANTHROPIC_API_KEY;

// Helper function to create a test audio file
function _createTestAudioFile(): File {
  // Create a WAV file with 1 second of silence (44100 samples * 2 bytes per sample)
  const sampleRate = 44100;
  const duration = 1; // 1 second
  const numSamples = sampleRate * duration;
  const dataSize = numSamples * 2; // 16-bit samples = 2 bytes per sample

  // Create WAV header with proper size
  const chunkSize = 36 + dataSize;
  const header = new ArrayBuffer(44);
  const view = new DataView(header);

  // "RIFF" chunk descriptor
  view.setUint8(0, 0x52);
  view.setUint8(1, 0x49);
  view.setUint8(2, 0x46);
  view.setUint8(3, 0x46); // "RIFF"
  view.setUint32(4, chunkSize, true); // ChunkSize
  view.setUint8(8, 0x57);
  view.setUint8(9, 0x41);
  view.setUint8(10, 0x56);
  view.setUint8(11, 0x45); // "WAVE"

  // "fmt " sub-chunk
  view.setUint8(12, 0x66);
  view.setUint8(13, 0x6D);
  view.setUint8(14, 0x74);
  view.setUint8(15, 0x20); // "fmt "
  view.setUint32(16, 16, true); // Subchunk1Size
  view.setUint16(20, 1, true); // AudioFormat (PCM)
  view.setUint16(22, 1, true); // NumChannels
  view.setUint32(24, sampleRate, true); // SampleRate
  view.setUint32(28, sampleRate * 2, true); // ByteRate
  view.setUint16(32, 2, true); // BlockAlign
  view.setUint16(34, 16, true); // BitsPerSample

  // "data" sub-chunk
  view.setUint8(36, 0x64);
  view.setUint8(37, 0x61);
  view.setUint8(38, 0x74);
  view.setUint8(39, 0x61); // "data"
  view.setUint32(40, dataSize, true); // Subchunk2Size

  // Create silent audio data (zeros)
  const audioData = new Uint8Array(dataSize);

  // Combine header and data
  const wavFile = new Uint8Array(44 + dataSize);
  wavFile.set(new Uint8Array(header), 0);
  wavFile.set(audioData, 44);

  const blob = new Blob([wavFile], { type: "audio/wav" });
  return new File([blob], "test-audio.wav", { type: "audio/wav" });
}

// Removed the test audio file test - only using real audio files

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
    const textFile = new File(["hello world"], "test.txt", {
      type: "text/plain",
    });

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

// Test with a real audio file - use fixture or environment variable
const defaultFixturePath =
  new URL("./fixtures/sample-audio-recording.m4a", import.meta.url).pathname;
const TEST_AUDIO_PATH = Deno.env.get("TEST_AUDIO_PATH") || defaultFixturePath;

// Check if fixture exists - try to get file info
let fixtureExists = false;
try {
  const fileInfo = await Deno.stat(TEST_AUDIO_PATH);
  fixtureExists = fileInfo.isFile;
  if (fixtureExists) {
    console.log(
      `📂 Found audio file: ${TEST_AUDIO_PATH} (${fileInfo.size} bytes)`,
    );
  }
} catch {
  console.log(`⚠️  Audio file not found: ${TEST_AUDIO_PATH}`);
}

if (fixtureExists) {
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
      assertEquals(
        body.transcript.length > 0,
        true,
        "Should have non-empty transcript",
      );
      assertEquals(body.duration > 0, true, "Should have positive duration");

      // Bullet summary might be empty for very short/simple recordings
      if (body.bulletSummary.length === 0) {
        console.log("  Note: No bullet points generated for this recording");
      }
    },
  });
}

function getMimeType(filename: string): string {
  const ext = filename.split(".").pop()?.toLowerCase();
  switch (ext) {
    case "mp3":
      return "audio/mpeg";
    case "mp4":
      return "audio/mp4";
    case "m4a":
      return "audio/m4a";
    case "wav":
      return "audio/wav";
    default:
      return "audio/mpeg";
  }
}

if (skipIntegration) {
  console.log(
    "\n⚠️  Integration tests skipped - set OPENAI_API_KEY and ANTHROPIC_API_KEY to run them",
  );
} else {
  console.log("\n🚀 Running integration tests...");
  console.log("Make sure the server is running: deno task dev");

  if (TEST_AUDIO_PATH) {
    console.log(`\n🎵 Will test with real audio file: ${TEST_AUDIO_PATH}`);
  } else {
    console.log(
      "\n💡 Tip: Set TEST_AUDIO_PATH environment variable to test with a real audio file",
    );
    console.log(
      "   Example: TEST_AUDIO_PATH=/path/to/audio.m4a deno test tests/new-recording-test.ts",
    );
  }
}
