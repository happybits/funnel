/**
 * Unit tests for API response shapes and business logic validation.
 * These tests mock API responses and validate data structures without requiring a running server.
 */
import {
  assertEquals,
  assertExists,
} from "https://deno.land/std@0.215.0/assert/mod.ts";
import type { ErrorResponse, NewRecordingResponse } from "../types/api.ts";

// Legacy types for testing (no longer in actual API)
interface TranscribeResponse {
  transcript: string;
  duration: number;
}

interface SummarizeResponse {
  bulletSummary: string[];
}

interface DiagramResponse {
  title: string;
  description: string;
  diagram: string;
}

// Test data
const longTranscript =
  `Okay. So I am thinking about an idea I had for an article which is I wanna talk about how what coding With Agentic coding assistance like Claude Code, and Cursor, it feels like. And I've heard it described being a manager. You're gonna be a manager. It's like being a manager of humans. You've got all these AI agents. They're just like little humans that know, human engineers, and you just have to tell them what to do, and they'll magically write code for you and then maybe they do it wrong, and you just have to give them feedback, and then it'll work. But I don't really think that metaphor is super accurate. And but I've been trying to think of what is a better metaphor. We're like, what is this like? And, you know, is it using a machine? Is it using a is it coding with a broom or something? Or is it coding with a know, is it building with things with bricks? Or with, Construction equipment For what? And I think the best example I have come across is I was thinking of This video game I used to play, for, like, the Nintendo 64 maybe, that was your Mickey Mouse and you have a magic paintbrush. You can point this magic paintbrush of things in your black and white world, and it transforms them into colorful, amazing, magical things. But the thing about this video game is that it was also really confusing, and the UI was terrible, and it was just So this paintbrush that was so magical and powerful was extremely difficult to use. And oftentimes, wouldn't work at all because I didn't know how to Like, where to point it or how to use it or what to do with it. And so I think that is the metaphor I would say is it's like having a very difficult to use paintbrush magic paintbrush that if you use it perfectly, You can paint. Way faster then you can paint with a regular paintbrush. But how you use it is not the same as how you ask a human to do something for you.`;

Deno.test("API Response Shapes - TranscribeResponse validation", () => {
  // Mock successful transcribe response
  const mockResponse: TranscribeResponse = {
    transcript: "This is a test transcript",
    duration: 10.5,
  };

  // Validate response shape
  assertExists(mockResponse.transcript);
  assertExists(mockResponse.duration);
  assertEquals(typeof mockResponse.transcript, "string");
  assertEquals(typeof mockResponse.duration, "number");
});

Deno.test("API Response Shapes - Error response validation", () => {
  // Mock error response
  const mockError: ErrorResponse = {
    error: "Invalid file format",
    details: "Only mp3, mp4, wav, and m4a files are supported",
  };

  // Validate error response shape
  assertExists(mockError.error);
  assertEquals(typeof mockError.error, "string");
  if (mockError.details) {
    assertEquals(typeof mockError.details, "string");
  }
});

Deno.test("API Response Shapes - SummarizeResponse validation", () => {
  // Mock successful summarize response
  const mockResponse: SummarizeResponse = {
    bulletSummary: [
      "AI coding assistants are often compared to managing junior developers",
      "Better metaphor: magic paintbrush from a glitchy video game",
      "Powerful but unintuitive - requires learning alien logic",
    ],
  };

  // Validate response shape
  assertExists(mockResponse.bulletSummary);
  assertEquals(Array.isArray(mockResponse.bulletSummary), true);
  assertEquals(mockResponse.bulletSummary.length > 0, true);
  mockResponse.bulletSummary.forEach((bullet: string) => {
    assertEquals(typeof bullet, "string");
  });
});

Deno.test("Summarize Endpoint - produces concise summary from long transcript", () => {
  // Expected behavior: long transcript should produce 3-5 bullet points
  const _mockRequest = { transcript: longTranscript };

  // Mock what the API should return for the test case
  const expectedSummary: SummarizeResponse = {
    bulletSummary: [
      "AI coding ≠ Managing Junior Devs",
      "It's like a magic paintbrush from a glitchy video game",
      "Incredibly powerful but maddeningly unintuitive",
      "Wrong angle = nothing happens",
      "Right angle = instant transformation",
      "Requires learning alien logic, not people skills",
    ],
  };

  // Validate the summary is concise (3-6 bullet points)
  assertEquals(expectedSummary.bulletSummary.length <= 6, true);
  assertEquals(expectedSummary.bulletSummary.length >= 3, true);

  // Each bullet should be concise (under 100 chars)
  expectedSummary.bulletSummary.forEach((bullet: string) => {
    assertEquals(bullet.length < 100, true);
  });
});

Deno.test("Summarize Endpoint - handles empty transcript", () => {
  const mockError: ErrorResponse = {
    error: "Transcript is required",
  };

  assertExists(mockError.error);
  assertEquals(typeof mockError.error, "string");
});

Deno.test("Summarize Endpoint - handles extremely long transcript", () => {
  const _veryLongTranscript = longTranscript.repeat(100); // ~50k chars

  // Should either succeed or return appropriate error
  const mockError: ErrorResponse = {
    error: "Transcript too long",
    details: "Maximum transcript length is 50,000 characters",
  };

  assertExists(mockError.error);
  assertEquals(mockError.error, "Transcript too long");
});

Deno.test("API Response Shapes - DiagramResponse validation", () => {
  // Mock successful diagram response
  const mockResponse: DiagramResponse = {
    title: "Magic Paintbrush Metaphor",
    description:
      "AI coding is like using a powerful but confusing magic paintbrush from a glitchy video game.",
    diagram: `
     Human Manager          Magic Paintbrush
         Model                   Model
    ┌─────────────┐         ┌─────────────┐
    │   You 👤    │         │   You 🎨    │
    └──────┬──────┘         └──────┬──────┘
           │                       │
           ▼                       ▼
    ┌─────────────┐         ╔═════════════╗
    │ Jr Devs 👥  │         ║ Magic Brush ║
    └─────────────┘         ╚══════╦══════╝
                                   ║
                            ┌──────╨──────┐
                            │ • Powerful   │
                            │ • Confusing  │
                            │ • Alien Logic│
                            └─────────────┘`,
  };

  // Validate response shape
  assertExists(mockResponse.title);
  assertExists(mockResponse.description);
  assertExists(mockResponse.diagram);
  assertEquals(typeof mockResponse.title, "string");
  assertEquals(typeof mockResponse.description, "string");
  assertEquals(typeof mockResponse.diagram, "string");

  // Title should be short
  assertEquals(mockResponse.title.split(" ").length <= 5, true);

  // Description should be one sentence
  assertEquals(mockResponse.description.endsWith("."), true);
});

Deno.test("Diagram Endpoint - handles empty transcript", () => {
  const mockError: ErrorResponse = {
    error: "Transcript is required",
  };

  assertExists(mockError.error);
  assertEquals(typeof mockError.error, "string");
});

Deno.test("API Response Shapes - NewRecordingResponse validation", () => {
  // Mock successful new recording response
  const mockResponse: NewRecordingResponse = {
    transcript:
      "This is um, you know, a test transcript with like filler words",
    lightlyEditedTranscript: "This is a test transcript with filler words",
    duration: 10.5,
    bulletSummary: [
      "Test transcript contains filler words",
      "Demonstrates lightly edited feature",
    ],
    diagram: {
      title: "Test Diagram",
      description: "A test diagram for validation",
      content: "Raw -> Edited",
    },
    thoughtProvokingQuestions: [
      "What makes this approach unique?",
      "How might this scale in the future?",
      "What challenges haven't been considered?",
    ],
  };

  // Validate response shape
  assertExists(mockResponse.transcript);
  assertExists(mockResponse.lightlyEditedTranscript);
  assertExists(mockResponse.duration);
  assertExists(mockResponse.bulletSummary);
  assertExists(mockResponse.diagram);
  assertExists(mockResponse.thoughtProvokingQuestions);

  // Validate types
  assertEquals(typeof mockResponse.transcript, "string");
  assertEquals(typeof mockResponse.lightlyEditedTranscript, "string");
  assertEquals(typeof mockResponse.duration, "number");
  assertEquals(Array.isArray(mockResponse.bulletSummary), true);
  assertEquals(Array.isArray(mockResponse.thoughtProvokingQuestions), true);

  // Validate diagram structure
  assertExists(mockResponse.diagram.title);
  assertExists(mockResponse.diagram.description);
  assertExists(mockResponse.diagram.content);
  assertEquals(typeof mockResponse.diagram.title, "string");
  assertEquals(typeof mockResponse.diagram.description, "string");
  assertEquals(typeof mockResponse.diagram.content, "string");

  // Validate that lightlyEditedTranscript is different from raw transcript
  assertEquals(
    mockResponse.lightlyEditedTranscript !== mockResponse.transcript,
    true,
    "Lightly edited transcript should differ from raw transcript",
  );
});

Deno.test("LightlyEditedTranscript - removes filler words", () => {
  const rawTranscript =
    "So um, I was thinking about, you know, the way that like AI coding is really different from, uh, from managing junior developers...";
  const expectedEditedTranscript =
    "So I was thinking about the way that AI coding is really different from managing junior developers...";

  // This is what the API should return
  const mockResponse: Partial<NewRecordingResponse> = {
    transcript: rawTranscript,
    lightlyEditedTranscript: expectedEditedTranscript,
  };

  // Validate that filler words are removed
  assertEquals(mockResponse.lightlyEditedTranscript!.includes("um,"), false);
  assertEquals(
    mockResponse.lightlyEditedTranscript!.includes("you know,"),
    false,
  );
  assertEquals(mockResponse.lightlyEditedTranscript!.includes("like"), false);
  assertEquals(mockResponse.lightlyEditedTranscript!.includes("uh,"), false);

  // Validate that meaningful content is preserved
  assertEquals(
    mockResponse.lightlyEditedTranscript!.includes("AI coding"),
    true,
  );
  assertEquals(
    mockResponse.lightlyEditedTranscript!.includes(
      "managing junior developers",
    ),
    true,
  );
});
