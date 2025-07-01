import { Context } from "@hono/hono";
import { RecordingData, LiveTranscriptionEvents } from "../lib/deepgram.ts";
import {
  generateBulletSummary,
  generateDiagram,
  ProcessedRecording,
} from "../lib/ai-processing.ts";
import { activeDeepgramConnections } from "./stream-recording-ws.ts";

const kv = await Deno.openKv();

export async function finalizeRecordingHandler(c: Context): Promise<Response> {
  const recordingId = c.req.param("recordingId");

  if (!recordingId) {
    return c.json({ error: "Recording ID is required" }, 400);
  }

  try {
    // Check if there's an active Deepgram connection
    const deepgramConnection = activeDeepgramConnections.get(recordingId);
    if (deepgramConnection) {
      console.log(`Found active Deepgram connection for ${recordingId}, sending CloseStream`);
      
      // Set up promise to wait for metadata response
      // According to Deepgram docs, any Metadata response after CloseStream indicates completion
      // See: https://developers.deepgram.com/docs/close-stream
      const metadataPromise = new Promise<void>((resolve, reject) => {
        const metadataHandler = (data: any) => {
          console.log(`Received metadata for ${recordingId}:`, data);
          console.log(`Received metadata confirmation for ${recordingId} - transcription complete`);
          deepgramConnection.removeListener(LiveTranscriptionEvents.Metadata, metadataHandler);
          resolve();
        };
        deepgramConnection.on(LiveTranscriptionEvents.Metadata, metadataHandler);
        
        // Set timeout
        setTimeout(() => {
          deepgramConnection.removeListener(LiveTranscriptionEvents.Metadata, metadataHandler);
          reject(new Error("Timeout waiting for metadata"));
        }, 30000); // 30 second timeout
      });
      
      // Send CloseStream message
      console.log(`Sending CloseStream to Deepgram for ${recordingId}`);
      deepgramConnection.send(JSON.stringify({ type: "CloseStream" }));
      
      // Wait for metadata response
      try {
        await metadataPromise;
        console.log(`Deepgram confirmed all transcripts processed for ${recordingId}`);
      } catch (error) {
        console.error(`Error waiting for Deepgram confirmation: ${error instanceof Error ? error.message : String(error)}`);
        // Continue anyway, but log the error
      }
    }

    // Get recording from KV
    const recordingEntry = await kv.get<RecordingData>([
      "recordings",
      recordingId,
    ]);

    if (!recordingEntry.value) {
      return c.json({ error: "Recording not found" }, 404);
    }

    const recording = recordingEntry.value;

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

    // Update status to processing
    recording.status = "processing";
    recording.endTime = recording.endTime || new Date();
    await kv.set(["recordings", recordingId], recording);

    // Calculate duration
    const duration = recording.endTime
      ? (recording.endTime.getTime() - recording.startTime.getTime()) / 1000
      : 0;

    // Generate final transcript from all final segments
    const finalTranscript = recording.segments
      .filter((s) => s.isFinal)
      .map((s) => s.text)
      .join(" ")
      .trim();

    if (!finalTranscript) {
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
