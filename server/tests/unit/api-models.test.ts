/**
 * Unit tests for API response models
 * Tests model validation and structure without making network calls
 */

import {
  assertEquals,
  assertExists,
} from "https://deno.land/std@0.215.0/assert/mod.ts";
import type { ErrorResponse, NewRecordingResponse } from "../../types/api.ts";

Deno.test("NewRecordingResponse - validates complete response structure", () => {
  const mockResponse: NewRecordingResponse = {
    transcript:
      "This is the original transcript with um, you know, filler words",
    lightlyEditedTranscript:
      "This is the original transcript with filler words",
    duration: 45.5,
    bulletSummary: [
      "First key point from the recording",
      "Second important insight discussed",
      "Third takeaway or conclusion",
    ],
    diagram: {
      title: "Recording Overview",
      description: "Visual representation of the key concepts",
      content: "graph TD\n  A[Start] --> B[Main Point]\n  B --> C[Conclusion]",
    },
    thoughtProvokingQuestions: [
      "What are the broader implications of this idea?",
      "How might this apply in different contexts?",
      "What challenges might arise from implementation?",
    ],
  };

  // Validate all required fields exist
  assertExists(mockResponse.transcript);
  assertExists(mockResponse.lightlyEditedTranscript);
  assertExists(mockResponse.duration);
  assertExists(mockResponse.bulletSummary);
  assertExists(mockResponse.diagram);
  assertExists(mockResponse.thoughtProvokingQuestions);

  // Validate field types
  assertEquals(typeof mockResponse.transcript, "string");
  assertEquals(typeof mockResponse.lightlyEditedTranscript, "string");
  assertEquals(typeof mockResponse.duration, "number");
  assertEquals(Array.isArray(mockResponse.bulletSummary), true);
  assertEquals(typeof mockResponse.diagram, "object");
  assertEquals(Array.isArray(mockResponse.thoughtProvokingQuestions), true);

  // Validate diagram structure
  assertExists(mockResponse.diagram.title);
  assertExists(mockResponse.diagram.description);
  assertExists(mockResponse.diagram.content);
  assertEquals(typeof mockResponse.diagram.title, "string");
  assertEquals(typeof mockResponse.diagram.description, "string");
  assertEquals(typeof mockResponse.diagram.content, "string");

  // Validate arrays contain strings
  mockResponse.bulletSummary.forEach((bullet) => {
    assertEquals(typeof bullet, "string");
  });
  mockResponse.thoughtProvokingQuestions.forEach((question) => {
    assertEquals(typeof question, "string");
  });
});

Deno.test("NewRecordingResponse - validates minimum array lengths", () => {
  const mockResponse: NewRecordingResponse = {
    transcript: "Short test",
    lightlyEditedTranscript: "Short test",
    duration: 5.0,
    bulletSummary: ["Single point"],
    diagram: {
      title: "Test",
      description: "Test diagram",
      content: "graph TD\n  A[Test]",
    },
    thoughtProvokingQuestions: ["One question?"],
  };

  // Arrays should have at least one item
  assertEquals(mockResponse.bulletSummary.length >= 1, true);
  assertEquals(mockResponse.thoughtProvokingQuestions.length >= 1, true);
});

Deno.test("ErrorResponse - validates error structure", () => {
  const mockError: ErrorResponse = {
    error: "Processing failed",
    details: "Invalid audio format provided",
  };

  // Validate required field
  assertExists(mockError.error);
  assertEquals(typeof mockError.error, "string");

  // Validate optional field when present
  if (mockError.details) {
    assertEquals(typeof mockError.details, "string");
  }
});

Deno.test("ErrorResponse - validates minimal error", () => {
  const mockError: ErrorResponse = {
    error: "Unknown error",
  };

  // Should work with just error field
  assertExists(mockError.error);
  assertEquals(mockError.details, undefined);
});

Deno.test("NewRecordingResponse - validates realistic response", () => {
  const mockResponse: NewRecordingResponse = {
    transcript:
      "So, um, I've been thinking about, you know, how AI is changing the way we code. It's like, uh, really different from what we're used to.",
    lightlyEditedTranscript:
      "So, I've been thinking about how AI is changing the way we code. It's really different from what we're used to.",
    duration: 120.5,
    bulletSummary: [
      "AI is fundamentally changing coding practices",
      "The experience differs from traditional programming",
      "Adaptation to new workflows is necessary",
    ],
    diagram: {
      title: "AI Impact on Coding",
      description: "How AI tools transform the development process",
      content: `graph LR
    A[Traditional Coding] --> B[AI-Assisted Coding]
    B --> C[New Workflows]
    B --> D[Different Skills]
    C --> E[Productivity Gains]
    D --> E`,
    },
    thoughtProvokingQuestions: [
      "How will this change the skills developers need?",
      "What are the long-term implications for software quality?",
      "How should education adapt to these changes?",
    ],
  };

  // Validate transcript was edited (should be shorter)
  assertEquals(
    mockResponse.lightlyEditedTranscript.length <
      mockResponse.transcript.length,
    true,
  );

  // Validate diagram contains mermaid syntax
  assertEquals(mockResponse.diagram.content.includes("graph"), true);

  // Validate questions end with question marks
  mockResponse.thoughtProvokingQuestions.forEach((question) => {
    assertEquals(question.endsWith("?"), true);
  });
});

Deno.test("NewRecordingResponse - handles long content", () => {
  const longTranscript = "This is a very long transcript. ".repeat(100);

  const mockResponse: NewRecordingResponse = {
    transcript: longTranscript,
    lightlyEditedTranscript: longTranscript.replace(/\. /g, ". ").trim(),
    duration: 600.0,
    bulletSummary: [
      "Point 1 from a long recording",
      "Point 2 from extensive content",
      "Point 3 summarizing key themes",
      "Point 4 highlighting important details",
      "Point 5 concluding the main ideas",
    ],
    diagram: {
      title: "Complex Topic Overview",
      description: "Comprehensive diagram of discussed concepts",
      content: "graph TD\n" + "  A[Concept] --> B[Detail]\n".repeat(10),
    },
    thoughtProvokingQuestions: [
      "Question 1 about the content?",
      "Question 2 exploring implications?",
      "Question 3 considering applications?",
      "Question 4 examining challenges?",
      "Question 5 looking at future directions?",
    ],
  };

  // Long content should still validate
  assertExists(mockResponse.transcript);
  assertEquals(mockResponse.transcript.length > 1000, true);
  assertEquals(mockResponse.bulletSummary.length, 5);
  assertEquals(mockResponse.thoughtProvokingQuestions.length, 5);
});
