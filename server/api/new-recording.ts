import { Context } from "@hono/hono";
import { OpenAIClient } from "../lib/openai.ts";
import { AnthropicClient } from "../lib/anthropic.ts";
import type { ErrorResponse, NewRecordingResponse } from "../types/api.ts";

export async function newRecordingHandler(c: Context): Promise<Response> {
  try {
    // Check API keys
    const openaiKey = Deno.env.get("OPENAI_API_KEY");
    const anthropicKey = Deno.env.get("ANTHROPIC_API_KEY");

    if (!openaiKey || !anthropicKey) {
      return c.json<ErrorResponse>(
        { error: "API keys not configured" },
        500,
      );
    }

    // Get audio file from form data
    const formData = await c.req.formData();
    const audioFile = formData.get("audio") as File;

    if (!audioFile) {
      return c.json<ErrorResponse>(
        { error: "No audio file provided" },
        400,
      );
    }

    // Validate file type
    const allowedTypes = [
      "audio/mpeg",
      "audio/mp3",
      "audio/mp4",
      "audio/wav",
      "audio/m4a",
    ];
    if (!allowedTypes.includes(audioFile.type)) {
      return c.json<ErrorResponse>(
        {
          error: "Invalid file type",
          details: `Allowed types: ${allowedTypes.join(", ")}`,
        },
        400,
      );
    }

    // Check file size (25MB limit for Whisper API)
    const maxSize = 25 * 1024 * 1024; // 25MB
    if (audioFile.size > maxSize) {
      return c.json<ErrorResponse>(
        {
          error: "File too large",
          details: "Maximum file size is 25MB",
        },
        400,
      );
    }

    // Step 1: Transcribe audio
    console.log("Transcribing audio...");
    const openaiClient = new OpenAIClient(openaiKey);
    const transcribeResult = await openaiClient.transcribeAudio(audioFile);

    if (!transcribeResult.transcript) {
      return c.json<ErrorResponse>(
        { error: "Transcription failed - empty transcript" },
        500,
      );
    }

    // Step 2: Generate summary, diagram, and lightly edited transcript in parallel
    console.log("Generating summary, diagram, and lightly edited transcript...");
    const anthropicClient = new AnthropicClient(anthropicKey);

    const [summaryResult, diagramResult, editedTranscriptResult] =
      await Promise.all([
        anthropicClient.summarizeTranscript(transcribeResult.transcript),
        anthropicClient.generateDiagram(transcribeResult.transcript),
        anthropicClient.generateLightlyEditedTranscript(
          transcribeResult.transcript,
        ),
      ]);

    // Combine all results
    const response: NewRecordingResponse = {
      transcript: transcribeResult.transcript,
      lightlyEditedTranscript: editedTranscriptResult.lightlyEditedTranscript,
      duration: transcribeResult.duration,
      bulletSummary: summaryResult.bulletSummary,
      diagram: {
        title: diagramResult.title,
        description: diagramResult.description,
        content: diagramResult.diagram,
      },
    };

    return c.json<NewRecordingResponse>(response);
  } catch (error) {
    console.error("Processing error:", error);
    return c.json<ErrorResponse>(
      {
        error: "Processing failed",
        details: error instanceof Error ? error.message : "Unknown error",
      },
      500,
    );
  }
}
