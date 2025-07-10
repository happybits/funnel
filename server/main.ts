import { Hono } from "@hono/hono";
import { cors } from "@hono/hono/cors";
import { logger } from "@hono/hono/logger";
// Removed unused import - upgradeWebSocket
import { load } from "@std/dotenv";
import { newRecordingHandler } from "./api/new-recording.ts";
import { liveTranscriptionHandler } from "./api/live-transcription.ts";
import { streamRecordingWsHandler } from "./api/stream-recording-ws.ts";
import { finalizeRecordingHandler } from "./api/finalize-recording.ts";
import { adminHandler } from "./api/admin.ts";
import { testPageHandler } from "./api/test-page.ts";

// Load environment variables
await load({ export: true });

const app = new Hono();

// Middleware - exclude WebSocket routes from CORS to avoid header conflicts
app.use("*", logger());
app.use(
  "*",
  (c, next) => {
    // Skip CORS for WebSocket upgrade requests
    if (c.req.header("upgrade") === "websocket") {
      return next();
    }
    return cors({
      origin: Deno.env.get("CORS_ORIGIN") || "*",
      allowMethods: ["GET", "POST", "OPTIONS"],
      allowHeaders: ["Content-Type"],
    })(c, next);
  },
);

// Health check endpoint
app.get("/", (c) => {
  return c.json({
    status: "ok",
    service: "Funnel API",
    version: "1.0.0",
    endpoints: [
      "POST /api/new-recording",
      "WebSocket /api/live-transcription",
      "WebSocket /api/recordings/:recordingId/stream",
      "POST /api/recordings/:recordingId/done",
    ],
  });
});

// API endpoints
app.post("/api/new-recording", newRecordingHandler);
app.get("/api/live-transcription", liveTranscriptionHandler);
app.get("/api/recordings/:recordingId/stream", streamRecordingWsHandler);
app.post("/api/recordings/:recordingId/done", finalizeRecordingHandler);

// Admin and test pages
app.get("/api/admin", adminHandler);
app.get("/api/test", testPageHandler);

// 404 handler
app.notFound((c) => {
  return c.json({ error: "Not found" }, 404);
});

// Error handler
app.onError((err, c) => {
  console.error("Server error:", err);
  return c.json({ error: "Internal server error" }, 500);
});

const port = 9000;
console.log(`Server starting on port ${port}...`);
console.log(`Health check: http://localhost:${port}/`);
console.log(`\nAvailable endpoints:`);
console.log(`POST http://localhost:${port}/api/new-recording`);
console.log(`WebSocket ws://localhost:${port}/api/live-transcription`);
console.log(
  `WebSocket ws://localhost:${port}/api/recordings/:recordingId/stream`,
);
console.log(`POST http://localhost:${port}/api/recordings/:recordingId/done`);

export { app };

Deno.serve({ port }, app.fetch);
