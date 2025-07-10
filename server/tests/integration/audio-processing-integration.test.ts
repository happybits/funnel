/**
 * Full pipeline integration test for audio processing
 * Tests the complete flow from audio upload to final processed result
 * Requires a running development server
 */

import {
  assert,
  assertEquals,
  assertExists,
} from "https://deno.land/std@0.215.0/assert/mod.ts";
import type { NewRecordingResponse } from "../../types/api.ts";

const SERVER_URL = "http://localhost:8000";
const TEST_AUDIO_PATH = "./tests/fixtures/sample-audio-recording.m4a";

Deno.test("Full audio processing pipeline - file upload", async () => {
  // Check if server is running
  try {
    const healthCheck = await fetch(SERVER_URL);
    await healthCheck.text();
  } catch {
    console.log("⚠️  Skipping integration test - server not running");
    return;
  }

  // Read test audio file
  const audioFile = await Deno.readFile(TEST_AUDIO_PATH);
  const blob = new Blob([audioFile], { type: "audio/m4a" });

  // Create form data
  const formData = new FormData();
  formData.append("audio", blob, "test-recording.m4a");

  // Upload and process
  const response = await fetch(`${SERVER_URL}/api/new-recording`, {
    method: "POST",
    body: formData,
  });

  assertEquals(response.status, 200);

  const result: NewRecordingResponse = await response.json();

  // Validate complete response structure
  assertExists(result.transcript);
  assertExists(result.lightlyEditedTranscript);
  assertExists(result.duration);
  assertExists(result.bulletSummary);
  assertExists(result.diagram);
  assertExists(result.thoughtProvokingQuestions);

  // Validate transcript processing
  assert(result.transcript.length > 0, "Transcript should not be empty");
  assert(
    result.lightlyEditedTranscript.length > 0,
    "Edited transcript should not be empty",
  );

  // Validate duration is reasonable
  assert(result.duration > 0, "Duration should be positive");
  assert(result.duration < 3600, "Duration should be less than 1 hour");

  // Validate bullet summary
  assert(
    result.bulletSummary.length >= 1,
    "Should have at least one summary point",
  );
  result.bulletSummary.forEach((bullet) => {
    assert(bullet.length > 0, "Bullet points should not be empty");
  });

  // Validate diagram
  assert(result.diagram.title.length > 0, "Diagram should have a title");
  assert(
    result.diagram.description.length > 0,
    "Diagram should have a description",
  );
  assert(
    result.diagram.content.includes("graph") ||
      result.diagram.content.includes("flowchart"),
    "Diagram should contain mermaid syntax",
  );

  // Validate questions
  assert(
    result.thoughtProvokingQuestions.length >= 1,
    "Should have at least one question",
  );
  result.thoughtProvokingQuestions.forEach((question) => {
    assert(
      question.endsWith("?"),
      "Questions should end with question mark",
    );
  });
});

Deno.test("Full audio processing pipeline - streaming", async () => {
  // Check if server is running
  try {
    const healthCheck = await fetch(SERVER_URL);
    await healthCheck.text();
  } catch {
    console.log("⚠️  Skipping integration test - server not running");
    return;
  }

  const recordingId = crypto.randomUUID();

  // Connect WebSocket
  const ws = new WebSocket(
    `${SERVER_URL.replace("http", "ws")}/api/recordings/${recordingId}/stream`,
  );

  const messages: unknown[] = [];

  ws.onmessage = (event) => {
    messages.push(JSON.parse(event.data));
  };

  await new Promise((resolve) => {
    ws.onopen = resolve;
  });

  // Send configuration
  ws.send(JSON.stringify({
    type: "config",
    format: "pcm16",
    sampleRate: 16000,
    channels: 1,
  }));

  // Send some test audio data (silence)
  const silenceBuffer = new ArrayBuffer(16000); // 1 second of silence
  ws.send(silenceBuffer);

  // Wait a bit for processing
  await new Promise((resolve) => setTimeout(resolve, 1000));

  // Close connection
  ws.close();

  // Finalize recording
  const finalizeResponse = await fetch(
    `${SERVER_URL}/api/recordings/${recordingId}/done`,
    { method: "POST" },
  );

  assertEquals(finalizeResponse.status, 200);

  const result: NewRecordingResponse = await finalizeResponse.json();

  // Basic validation (streaming might produce minimal results with silence)
  assertExists(result.transcript);
  assertExists(result.lightlyEditedTranscript);
  assertExists(result.duration);
  assertExists(result.bulletSummary);
  assertExists(result.diagram);
  assertExists(result.thoughtProvokingQuestions);
});

Deno.test("Audio processing error handling - invalid file type", async () => {
  // Check if server is running
  try {
    const healthCheck = await fetch(SERVER_URL);
    await healthCheck.text();
  } catch {
    console.log("⚠️  Skipping integration test - server not running");
    return;
  }

  // Create invalid file type
  const textFile = new Blob(["This is not audio"], { type: "text/plain" });

  const formData = new FormData();
  formData.append("audio", textFile, "not-audio.txt");

  const response = await fetch(`${SERVER_URL}/api/new-recording`, {
    method: "POST",
    body: formData,
  });

  assertEquals(response.status, 400);

  const error = await response.json();
  assertExists(error.error);
  assert(
    error.error.toLowerCase().includes("invalid") ||
      error.error.toLowerCase().includes("file type"),
    "Error should mention invalid file type",
  );
});

Deno.test("Audio processing error handling - missing audio file", async () => {
  // Check if server is running
  try {
    const healthCheck = await fetch(SERVER_URL);
    await healthCheck.text();
  } catch {
    console.log("⚠️  Skipping integration test - server not running");
    return;
  }

  const formData = new FormData();
  // Don't append any audio file

  const response = await fetch(`${SERVER_URL}/api/new-recording`, {
    method: "POST",
    body: formData,
  });

  assertEquals(response.status, 400);

  const error = await response.json();
  assertExists(error.error);
  assert(
    error.error.toLowerCase().includes("no audio") ||
      error.error.toLowerCase().includes("missing"),
    "Error should mention missing audio",
  );
});
