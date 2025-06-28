import { Context } from "@hono/hono";
import { computeTranscriptFromEvents, RecordingData } from "../lib/deepgram.ts";
import {
  generateBulletSummary,
  generateDiagram,
  ProcessedRecording,
} from "../lib/ai-processing.ts";

const kv = await Deno.openKv();

export async function finalizeRecordingHandler(c: Context): Promise<Response> {
  const recordingId = c.req.param("recordingId");

  if (!recordingId) {
    return c.json({ error: "Recording ID is required" }, 400);
  }

  try {
    // Get recording from KV
    const recordingEntry = await kv.get<RecordingData>([
      "recordings",
      recordingId,
    ]);

    if (!recordingEntry.value) {
      return c.json({ error: "Recording not found" }, 404);
    }

    let recording = recordingEntry.value;

    // Check if already processed
    if (recording.status === "completed") {
      const processedEntry = await kv.get<ProcessedRecording>([
        "processed",
        recordingId,
      ]);
      if (processedEntry.value) {
        return c.json(processedEntry.value);
      }
    }

    // If status is finalizing, wait for it to complete
    if (recording.status === "finalizing") {
      console.log(`Recording ${recordingId} is still finalizing, waiting...`);
      let attempts = 0;
      const maxAttempts = 10; // Wait up to 2 seconds (10 * 200ms)

      while (recording.status === "finalizing" && attempts < maxAttempts) {
        await new Promise((resolve) => setTimeout(resolve, 200));
        const updated = await kv.get<RecordingData>([
          "recordings",
          recordingId,
        ]);
        if (updated.value) {
          recording = updated.value;
        }
        attempts++;
      }

      if (recording.status === "finalizing") {
        console.warn(
          `Recording ${recordingId} stuck in finalizing status after ${attempts} attempts`,
        );
      }
    }

    // Update status to processing
    recording.status = "processing";
    recording.endTime = recording.endTime || new Date();
    await kv.set(["recordings", recordingId], recording);

    // Calculate duration
    const duration = recording.endTime
      ? (recording.endTime.getTime() - recording.startTime.getTime()) / 1000
      : 0;

    // Generate final transcript from independently stored events
    let finalTranscript = "";

    // Fetch all transcript events for this recording from KV
    const eventIterator = kv.list<TranscriptEvent>({
      prefix: ["transcript_event", recordingId],
    });
    const events: TranscriptEvent[] = [];
    for await (const entry of eventIterator) {
      events.push(entry.value);
    }

    console.log(
      `Found ${events.length} transcript events for recording ${recordingId}`,
    );

    if (events.length > 0) {
      finalTranscript = computeTranscriptFromEvents(events);
      console.log(
        `Computed transcript from ${events.length} events: "${finalTranscript}"`,
      );
    }

    // Fall back to recording transcript field if no events
    if (!finalTranscript && recording.transcript) {
      finalTranscript = recording.transcript;
      console.log(
        `Using recording transcript field as fallback for recording ${recordingId}`,
      );
    }

    if (!finalTranscript) {
      // Log detailed debugging info
      console.error(`No transcript available for recording ${recordingId}:`, {
        eventsCount: recording.events?.length || 0,
        segmentsCount: recording.segments?.length || 0,
        transcriptLength: recording.transcript?.length || 0,
        status: recording.status,
      });
      throw new Error("No transcript available");
    }

    console.log(
      `Processing recording ${recordingId} with transcript length: ${finalTranscript.length}`,
    );

    // Generate AI properties in parallel
    let bulletSummary: string[];
    let diagram: { title: string; description: string; content: string };

    try {
      [bulletSummary, diagram] = await Promise.all([
        generateBulletSummary(finalTranscript),
        generateDiagram(finalTranscript),
      ]);
    } catch (error) {
      console.error("Error generating AI content:", error);

      // Try generating individually with fallbacks
      try {
        bulletSummary = await generateBulletSummary(finalTranscript);
      } catch (e) {
        console.error("Failed to generate bullet summary:", e);
        bulletSummary = ["Failed to generate summary"];
      }

      try {
        diagram = await generateDiagram(finalTranscript);
      } catch (e) {
        console.error("Failed to generate diagram:", e);
        diagram = {
          title: "Visualization",
          description: "Unable to generate diagram",
          content: "[Diagram generation failed]",
        };
      }
    }

    // Create processed recording
    const processedRecording: ProcessedRecording = {
      id: recordingId,
      transcript: finalTranscript,
      duration: Math.round(duration),
      bulletSummary,
      diagram,
      createdAt: recording.startTime,
      audioSize: recording.audioSize,
    };

    // Update recording status
    recording.status = "completed";
    recording.transcript = finalTranscript;
    recording.duration = duration;
    await kv.set(["recordings", recordingId], recording);

    // Store processed recording
    await kv.set(["processed", recordingId], processedRecording);

    // Return the processed recording
    return c.json(processedRecording);
  } catch (error) {
    console.error(`Error finalizing recording ${recordingId}:`, error);

    const errorMessage = error instanceof Error ? error.message : String(error);

    // Update recording status to error
    const recordingEntry = await kv.get<RecordingData>([
      "recordings",
      recordingId,
    ]);
    if (recordingEntry.value) {
      recordingEntry.value.status = "error";
      recordingEntry.value.error = errorMessage;
      await kv.set(["recordings", recordingId], recordingEntry.value);
    }

    return c.json({
      error: "Failed to process recording",
      details: errorMessage,
    }, 500);
  }
}
