import type { Context } from "@hono/hono";
import { generateBulletSummary, generateDiagram } from "../lib/ai-processing.ts";

const kv = await Deno.openKv();

/**
 * GET endpoint that retrieves the saved transcript from Deno KV
 * and generates AI summaries and diagrams on-demand.
 * 
 * URL: GET /api/v2/recordings/:recordingId
 */
export const getRecordingV2Handler = async (c: Context) => {
  const recordingId = c.req.param("recordingId");
  
  console.log(`Retrieving recording ${recordingId}`);
  
  try {
    // Get recording from KV
    const recordingEntry = await kv.get(["recordings", recordingId]);
    
    if (!recordingEntry.value) {
      return c.json({ 
        error: "Recording not found",
        recordingId 
      }, 404);
    }
    
    const recording = recordingEntry.value as {
      id: string;
      transcript: string;
      duration: number;
      createdAt: string;
      status: string;
      segmentCount: number;
    };
    
    if (!recording.transcript) {
      return c.json({ 
        error: "Recording has no transcript",
        recordingId 
      }, 400);
    }
    
    console.log(`Generating AI content for recording ${recordingId}`);
    
    // Generate AI content in parallel
    const [bulletSummary, diagram] = await Promise.all([
      generateBulletSummary(recording.transcript),
      generateDiagram(recording.transcript),
    ]);
    
    // Return complete processed recording (matching the iOS ProcessedRecording struct)
    const processedRecording = {
      transcript: recording.transcript,
      duration: recording.duration,
      bulletSummary,
      diagram,
    };
    
    return c.json(processedRecording);
    
  } catch (error) {
    console.error(`Error retrieving recording ${recordingId}:`, error);
    
    return c.json({ 
      error: "Failed to retrieve recording",
      message: error.message,
      recordingId 
    }, 500);
  }
};