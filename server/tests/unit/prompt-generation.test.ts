/**
 * Unit tests for prompt construction logic
 * Verifies that prompts are properly formatted and include all required elements
 */

import {
  assertEquals,
  assertStringIncludes,
} from "https://deno.land/std@0.208.0/assert/mod.ts";
import {
  afterEach,
  beforeEach,
  describe,
  it,
} from "https://deno.land/std@0.208.0/testing/bdd.ts";
import { restore, stub } from "https://deno.land/std@0.208.0/testing/mock.ts";
import { AnthropicClient } from "../../lib/anthropic.ts";

describe("Prompt Generation Tests", () => {
  let _readTextFileStub: ReturnType<typeof stub>;
  let fetchStub: ReturnType<typeof stub>;
  let client: AnthropicClient;

  beforeEach(() => {
    client = new AnthropicClient("test-api-key");

    // Mock Deno.readTextFile to return test prompts
    _readTextFileStub = stub(Deno, "readTextFile", (path: string) => {
      if (path.includes("summarize-transcript.txt")) {
        return "Summarize this transcript: {{TRANSCRIPT}}";
      } else if (path.includes("generate-diagram.txt")) {
        return "Create a diagram for: {{TRANSCRIPT}}";
      } else if (path.includes("lightly-edit-transcript.txt")) {
        return "Edit this transcript: {{TRANSCRIPT}}";
      } else if (path.includes("thought-provoking-questions.txt")) {
        return "Generate questions for: {{TRANSCRIPT}}";
      }
      throw new Error(`Unexpected file path: ${path}`);
    });

    // Mock fetch to capture the request
    fetchStub = stub(
      globalThis,
      "fetch",
      (_url: string, init?: RequestInit) => {
        const body = JSON.parse(init?.body as string);

        // Return different responses based on the prompt content
        let response = { content: [{ text: "Default response" }] };

        if (body.messages[0].content.includes("Summarize")) {
          response = {
            content: [{ text: "- Summary point 1\n- Summary point 2" }],
          };
        } else if (body.messages[0].content.includes("diagram")) {
          response = {
            content: [{
              text:
                "Title: Test Diagram\nDescription: Test Description\n\n```mermaid\ngraph TD\n  A[Start] --> B[End]\n```",
            }],
          };
        } else if (body.messages[0].content.includes("Edit")) {
          response = {
            content: [{ text: "Edited transcript without filler words" }],
          };
        } else if (body.messages[0].content.includes("questions")) {
          response = {
            content: [{
              text:
                "1. What is the main idea?\n2. How does this apply?\n3. What are the implications?",
            }],
          };
        }

        return new Response(JSON.stringify(response), {
          status: 200,
          headers: { "Content-Type": "application/json" },
        });
      },
    );
  });

  afterEach(() => {
    restore();
  });

  it("should include transcript in summarize prompt", async () => {
    const transcript = "This is a test transcript with important content.";
    await client.summarizeTranscript(transcript);

    const fetchCall = fetchStub.calls[0];
    const requestBody = JSON.parse(fetchCall.args[1].body);
    const prompt = requestBody.messages[0].content;

    assertStringIncludes(prompt, "Summarize this transcript:");
    assertStringIncludes(prompt, transcript);
  });

  it("should include transcript in diagram generation prompt", async () => {
    const transcript =
      "We have a process that starts with input and ends with output.";
    await client.generateDiagram(transcript);

    const fetchCall = fetchStub.calls[0];
    const requestBody = JSON.parse(fetchCall.args[1].body);
    const prompt = requestBody.messages[0].content;

    assertStringIncludes(prompt, "Create a diagram for:");
    assertStringIncludes(prompt, transcript);
  });

  it("should include transcript in edit prompt", async () => {
    const transcript = "Um, so like, this is, you know, a test.";
    await client.generateLightlyEditedTranscript(transcript);

    const fetchCall = fetchStub.calls[0];
    const requestBody = JSON.parse(fetchCall.args[1].body);
    const prompt = requestBody.messages[0].content;

    assertStringIncludes(prompt, "Edit this transcript:");
    assertStringIncludes(prompt, transcript);
  });

  it("should include transcript in questions prompt", async () => {
    const transcript =
      "The key insight is that complexity emerges from simple rules.";
    await client.generateThoughtProvokingQuestions(transcript);

    const fetchCall = fetchStub.calls[0];
    const requestBody = JSON.parse(fetchCall.args[1].body);
    const prompt = requestBody.messages[0].content;

    assertStringIncludes(prompt, "Generate questions for:");
    assertStringIncludes(prompt, transcript);
  });

  it("should use correct model and parameters", async () => {
    await client.summarizeTranscript("Test transcript");

    const fetchCall = fetchStub.calls[0];
    const requestBody = JSON.parse(fetchCall.args[1].body);

    assertEquals(requestBody.model, "claude-3-haiku-20240307");
    assertEquals(requestBody.max_tokens, 8192);
    assertEquals(requestBody.messages[0].role, "user");
  });

  it("should include proper headers", async () => {
    await client.generateDiagram("Test content");

    const fetchCall = fetchStub.calls[0];
    const headers = fetchCall.args[1].headers;

    assertEquals(headers["x-api-key"], "test-api-key");
    assertEquals(headers["anthropic-version"], "2023-06-01");
    assertEquals(headers["content-type"], "application/json");
  });

  it("should handle long transcripts", async () => {
    const longTranscript = "This is a very long transcript. ".repeat(100);
    await client.summarizeTranscript(longTranscript);

    const fetchCall = fetchStub.calls[0];
    const requestBody = JSON.parse(fetchCall.args[1].body);
    const prompt = requestBody.messages[0].content;

    // Ensure the full transcript is included
    assertStringIncludes(prompt, longTranscript);
  });

  it("should properly escape special characters in transcript", async () => {
    const transcript = 'This has "quotes" and \nnewlines and \\backslashes';
    await client.generateLightlyEditedTranscript(transcript);

    const fetchCall = fetchStub.calls[0];
    const requestBody = JSON.parse(fetchCall.args[1].body);
    const prompt = requestBody.messages[0].content;

    // The transcript should be included as-is after template replacement
    assertStringIncludes(prompt, transcript);
  });
});
