import {
  assertEquals,
  assertRejects,
} from "https://deno.land/std@0.210.0/assert/mod.ts";
import { Stub, stub } from "https://deno.land/std@0.210.0/testing/mock.ts";
import { AnthropicClient } from "./anthropic.ts";

Deno.test("AnthropicClient - generateLightlyEditedTranscript", async (t) => {
  const client = new AnthropicClient("test-api-key");

  // Mock the prompt template
  const mockPrompt =
    `You are an expert editor who cleans up raw transcripts for readability while preserving the speaker's authentic voice and meaning.

Given this raw transcript, create a lightly edited version that:
- Removes filler words (um, uh, like, you know) when they don't add meaning
- Fixes obvious grammatical errors and incomplete sentences
- Adds light punctuation for clarity
- Preserves the speaker's natural tone and personality
- Keeps meaningful pauses or repetitions that add emphasis
- Does NOT change the meaning or add new content
- Does NOT make it overly formal or remove all conversational elements

Transcript:
{{transcript}}

Please provide only the edited transcript, no introduction or explanation.`;

  // Setup mock for readTextFile that will be used by all tests
  let mockReadTextFile: Stub;

  // Run before each test step
  const setupMocks = () => {
    mockReadTextFile = stub(
      Deno,
      "readTextFile",
      () => Promise.resolve(mockPrompt),
    );
  };

  // Clean up after each test step
  const cleanupMocks = () => {
    mockReadTextFile?.restore();
  };

  await t.step("removes common filler words", async () => {
    setupMocks();

    const mockFetch = stub(
      globalThis,
      "fetch",
      () =>
        Promise.resolve(
          new Response(
            JSON.stringify({
              content: [{
                text:
                  "So I was thinking about the way that AI coding is really different from managing junior developers...",
              }],
            }),
            { status: 200 },
          ),
        ),
    );

    try {
      const result = await client.generateLightlyEditedTranscript(
        "So um, I was thinking about, you know, the way that like AI coding is really different from, uh, from managing junior developers...",
      );

      assertEquals(
        result.lightlyEditedTranscript,
        "So I was thinking about the way that AI coding is really different from managing junior developers...",
      );
    } finally {
      mockFetch.restore();
      cleanupMocks();
    }
  });

  await t.step("preserves meaningful pauses and repetitions", async () => {
    setupMocks();

    const mockFetch = stub(
      globalThis,
      "fetch",
      () =>
        Promise.resolve(
          new Response(
            JSON.stringify({
              content: [{
                text:
                  "This is really, really important. We need to... pause and think about this carefully.",
              }],
            }),
            { status: 200 },
          ),
        ),
    );

    try {
      const result = await client.generateLightlyEditedTranscript(
        "This is really, really important. We need to like... pause and think about this carefully.",
      );

      assertEquals(
        result.lightlyEditedTranscript,
        "This is really, really important. We need to... pause and think about this carefully.",
      );
    } finally {
      mockFetch.restore();
      cleanupMocks();
    }
  });

  await t.step(
    "fixes grammatical errors and incomplete sentences",
    async () => {
      setupMocks();

      const mockFetch = stub(
        globalThis,
        "fetch",
        () =>
          Promise.resolve(
            new Response(
              JSON.stringify({
                content: [{
                  text:
                    "I think the best approach is to refactor the code and then run the tests.",
                }],
              }),
              { status: 200 },
            ),
          ),
      );

      try {
        const result = await client.generateLightlyEditedTranscript(
          "I think the best approach are to refactor the code and then, um, you know, run the test.",
        );

        assertEquals(
          result.lightlyEditedTranscript,
          "I think the best approach is to refactor the code and then run the tests.",
        );
      } finally {
        mockFetch.restore();
        cleanupMocks();
      }
    },
  );

  await t.step("handles transcripts with multiple filler types", async () => {
    setupMocks();

    const mockFetch = stub(
      globalThis,
      "fetch",
      () =>
        Promise.resolve(
          new Response(
            JSON.stringify({
              content: [{
                text:
                  "Actually, I was wondering if we could discuss the architecture before we start coding.",
              }],
            }),
            { status: 200 },
          ),
        ),
    );

    try {
      const result = await client.generateLightlyEditedTranscript(
        "So, uh, actually, um, I was like wondering if we could, you know, discuss the architecture before we, uh, start coding.",
      );

      assertEquals(
        result.lightlyEditedTranscript,
        "Actually, I was wondering if we could discuss the architecture before we start coding.",
      );
    } finally {
      mockFetch.restore();
      cleanupMocks();
    }
  });

  await t.step("preserves conversational tone", async () => {
    setupMocks();

    const mockFetch = stub(
      globalThis,
      "fetch",
      () =>
        Promise.resolve(
          new Response(
            JSON.stringify({
              content: [{
                text:
                  "Yeah, I totally agree! That's exactly what I was thinking too.",
              }],
            }),
            { status: 200 },
          ),
        ),
    );

    try {
      const result = await client.generateLightlyEditedTranscript(
        "Yeah, um, I totally agree! That's like exactly what I was thinking too.",
      );

      assertEquals(
        result.lightlyEditedTranscript,
        "Yeah, I totally agree! That's exactly what I was thinking too.",
      );
    } finally {
      mockFetch.restore();
      cleanupMocks();
    }
  });

  await t.step("handles empty transcript", async () => {
    setupMocks();

    const mockFetch = stub(
      globalThis,
      "fetch",
      () =>
        Promise.resolve(
          new Response(
            JSON.stringify({
              content: [{ text: "" }],
            }),
            { status: 200 },
          ),
        ),
    );

    try {
      const result = await client.generateLightlyEditedTranscript("");

      assertEquals(result.lightlyEditedTranscript, "");
    } finally {
      mockFetch.restore();
      cleanupMocks();
    }
  });

  await t.step("handles transcript without filler words", async () => {
    setupMocks();

    const mockFetch = stub(
      globalThis,
      "fetch",
      () =>
        Promise.resolve(
          new Response(
            JSON.stringify({
              content: [{
                text:
                  "This transcript is already clean and doesn't need any editing.",
              }],
            }),
            { status: 200 },
          ),
        ),
    );

    try {
      const result = await client.generateLightlyEditedTranscript(
        "This transcript is already clean and doesn't need any editing.",
      );

      assertEquals(
        result.lightlyEditedTranscript,
        "This transcript is already clean and doesn't need any editing.",
      );
    } finally {
      mockFetch.restore();
      cleanupMocks();
    }
  });

  await t.step("handles API error responses", async () => {
    setupMocks();

    const mockFetch = stub(
      globalThis,
      "fetch",
      () =>
        Promise.resolve(
          new Response("API rate limit exceeded", { status: 429 }),
        ),
    );

    try {
      await assertRejects(
        () => client.generateLightlyEditedTranscript("Some transcript"),
        Error,
        "Anthropic API error: 429 - API rate limit exceeded",
      );
    } finally {
      mockFetch.restore();
      cleanupMocks();
    }
  });

  await t.step("trims whitespace from response", async () => {
    setupMocks();

    const mockFetch = stub(
      globalThis,
      "fetch",
      () =>
        Promise.resolve(
          new Response(
            JSON.stringify({
              content: [{ text: "  This is the edited transcript.  \n\n" }],
            }),
            { status: 200 },
          ),
        ),
    );

    try {
      const result = await client.generateLightlyEditedTranscript(
        "Um, this is like the edited transcript.",
      );

      assertEquals(
        result.lightlyEditedTranscript,
        "This is the edited transcript.",
      );
    } finally {
      mockFetch.restore();
      cleanupMocks();
    }
  });

  await t.step("handles complex real-world example", async () => {
    setupMocks();

    const mockFetch = stub(
      globalThis,
      "fetch",
      () =>
        Promise.resolve(
          new Response(
            JSON.stringify({
              content: [{
                text:
                  "So I've been thinking about our deployment strategy, and I believe we should consider using Kubernetes. " +
                  "It's more complex than our current setup, but it would give us better scalability and... well, " +
                  "it's basically the industry standard at this point. What do you think?",
              }],
            }),
            { status: 200 },
          ),
        ),
    );

    try {
      const result = await client.generateLightlyEditedTranscript(
        "So, um, I've been thinking about our, you know, deployment strategy, and I, uh, believe we should " +
          "consider using, like, Kubernetes. It's, um, more complex than our current setup, but it would give us " +
          "better scalability and, uh... well, it's basically the, you know, industry standard at this point. " +
          "What do you think?",
      );

      assertEquals(
        result.lightlyEditedTranscript,
        "So I've been thinking about our deployment strategy, and I believe we should consider using Kubernetes. " +
          "It's more complex than our current setup, but it would give us better scalability and... well, " +
          "it's basically the industry standard at this point. What do you think?",
      );
    } finally {
      mockFetch.restore();
      cleanupMocks();
    }
  });

  await t.step("verifies API request format", async () => {
    setupMocks();

    let capturedRequest: {
      url: string;
      method?: string;
      headers?: HeadersInit;
      body?: unknown;
    };
    const mockFetch = stub(
      globalThis,
      "fetch",
      (url: string | URL | Request, init?: RequestInit) => {
        capturedRequest = {
          url: url.toString(),
          method: init?.method,
          headers: init?.headers,
          body: init?.body ? JSON.parse(init.body as string) : undefined,
        };
        return Promise.resolve(
          new Response(
            JSON.stringify({
              content: [{ text: "Edited transcript" }],
            }),
            { status: 200 },
          ),
        );
      },
    );

    try {
      const testTranscript = "Um, test transcript";
      await client.generateLightlyEditedTranscript(testTranscript);

      // Verify the request was made correctly
      assertEquals(
        capturedRequest.url,
        "https://api.anthropic.com/v1/messages",
      );
      assertEquals(capturedRequest.method, "POST");
      assertEquals(capturedRequest.headers["Content-Type"], "application/json");
      assertEquals(capturedRequest.headers["x-api-key"], "test-api-key");
      assertEquals(capturedRequest.headers["anthropic-version"], "2023-06-01");
      assertEquals(capturedRequest.body.model, "claude-3-5-sonnet-20241022");
      assertEquals(capturedRequest.body.max_tokens, 4096);
      assertEquals(capturedRequest.body.messages[0].role, "user");
      // Verify the prompt contains the transcript
      assert(capturedRequest.body.messages[0].content.includes(testTranscript));
    } finally {
      mockFetch.restore();
      cleanupMocks();
    }
  });
});

// Helper function to check if string contains substring
function assert(condition: boolean, message?: string): asserts condition {
  if (!condition) {
    throw new Error(message || "Assertion failed");
  }
}
