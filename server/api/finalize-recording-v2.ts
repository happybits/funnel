import type { Context } from "@hono/hono";
import { activeDeepgramConnections } from "./stream-recording-ws-v2.ts";

const kv = await Deno.openKv();

/**
 * Simplified finalization endpoint that:
 * 1. Sends CloseStream to Deepgram
 * 2. Waits for Metadata confirmation
 * 3. Saves the complete transcript to Deno KV
 * 
 * URL: POST /api/v2/recordings/:recordingId/finalize
 */
export const finalizeRecordingV2Handler = async (c: Context) => {
  const recordingId = c.req.param("recordingId");
  const startTime = Date.now();
  
  console.log(`Finalizing recording ${recordingId}`);
  
  const connectionData = activeDeepgramConnections.get(recordingId);
  
  if (!connectionData) {
    return c.json({ 
      error: "Recording not found or connection already closed",
      recordingId 
    }, 404);
  }

  try {
    // Mark as finalized to prevent cleanup
    connectionData.isFinalized = true;

    // Send CloseStream to Deepgram
    if (connectionData.deepgramWs.readyState === WebSocket.OPEN) {
      console.log(`Sending CloseStream to Deepgram for recording ${recordingId}`);
      connectionData.deepgramWs.send(JSON.stringify({ type: "CloseStream" }));
      
      // Wait for metadata with timeout
      const metadataTimeout = 30000; // 30 seconds
      const checkInterval = 100; // Check every 100ms
      let elapsed = 0;
      
      while (!connectionData.metadata && elapsed < metadataTimeout) {
        await new Promise(resolve => setTimeout(resolve, checkInterval));
        elapsed += checkInterval;
      }
      
      if (!connectionData.metadata) {
        console.warn(`Timeout waiting for Deepgram metadata for recording ${recordingId}`);
      } else {
        console.log(`Received metadata after ${elapsed}ms for recording ${recordingId}`);
      }
    }

    // Combine all transcript segments
    const fullTranscript = connectionData.transcriptSegments
      .sort((a, b) => a.start - b.start)
      .map(segment => segment.text)
      .join(" ")
      .trim();

    const duration = connectionData.metadata?.duration || 0;
    
    // Save to Deno KV
    const recordingData = {
      id: recordingId,
      transcript: fullTranscript,
      duration,
      createdAt: new Date().toISOString(),
      status: "transcribed",
      segmentCount: connectionData.transcriptSegments.length,
    };

    await kv.set(["recordings", recordingId], recordingData);
    
    console.log(`Saved recording ${recordingId} to KV with ${recordingData.segmentCount} segments`);
    
    // Clean up
    if (connectionData.deepgramWs.readyState === WebSocket.OPEN) {
      connectionData.deepgramWs.close();
    }
    activeDeepgramConnections.delete(recordingId);
    
    const processingTime = Date.now() - startTime;
    
    return c.json({
      success: true,
      recordingId,
      duration,
      transcriptLength: fullTranscript.length,
      segmentCount: connectionData.transcriptSegments.length,
      processingTime,
    });
    
  } catch (error) {
    console.error(`Error finalizing recording ${recordingId}:`, error);
    
    // Clean up on error
    activeDeepgramConnections.delete(recordingId);
    
    return c.json({ 
      error: "Failed to finalize recording",
      message: error.message,
      recordingId 
    }, 500);
  }
};