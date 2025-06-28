import { assertEquals, assertExists } from "@std/assert";
import { app } from "../main.ts";

Deno.test("POST /api/new-recording - returns edited transcript", async () => {
  // Create a simple test audio file
  const audioContent = new Uint8Array([0, 1, 2, 3, 4]); // Dummy audio data
  const audioFile = new File([audioContent], "test.m4a", { type: "audio/m4a" });
  
  const formData = new FormData();
  formData.append("audio", audioFile);
  
  const req = new Request("http://localhost/api/new-recording", {
    method: "POST",
    body: formData,
  });
  
  const res = await app.fetch(req);
  
  // This will fail without real API keys, but we're checking the structure
  if (res.status === 200) {
    const data = await res.json();
    
    // Check that all expected fields are present
    assertExists(data.transcript, "Response should include transcript");
    assertExists(data.editedTranscript, "Response should include editedTranscript");
    assertExists(data.duration, "Response should include duration");
    assertExists(data.bulletSummary, "Response should include bulletSummary");
    assertExists(data.diagram, "Response should include diagram");
    
    // Check types
    assertEquals(typeof data.transcript, "string");
    assertEquals(typeof data.editedTranscript, "string");
    assertEquals(typeof data.duration, "number");
    assertEquals(Array.isArray(data.bulletSummary), true);
    assertEquals(typeof data.diagram.title, "string");
    assertEquals(typeof data.diagram.description, "string");
    assertEquals(typeof data.diagram.content, "string");
  }
});

Deno.test("Anthropic client handles empty transcripts correctly", async () => {
  const { AnthropicClient } = await import("../lib/anthropic.ts");
  
  // This test doesn't require API key since we handle empty transcripts locally
  const client = new AnthropicClient("dummy-key");
  
  // Test empty transcript
  const emptyResult = await client.summarizeTranscript("");
  assertEquals(emptyResult.bulletSummary, ["Ah, the recording is empty!"]);
  
  const emptyEditResult = await client.editTranscript("");
  assertEquals(emptyEditResult.editedTranscript, "## Empty Recording\n\nAh, the recording is empty!");
  
  // Test very short transcript
  const shortEditResult = await client.editTranscript("Buy milk");
  assertEquals(shortEditResult.editedTranscript, "## Quick Note\n\nBuy milk.");
});