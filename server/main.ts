import { Hono } from "@hono/hono";
import { cors } from "@hono/hono/cors";
import { logger } from "@hono/hono/logger";
import { load } from "@std/dotenv";
import { newRecordingHandler } from "./api/new-recording.ts";
import { liveTranscriptionHandler } from "./api/live-transcription.ts";

// Load environment variables
await load({ export: true });

const app = new Hono();

// Middleware
app.use("*", logger());
app.use(
  "*",
  cors({
    origin: Deno.env.get("CORS_ORIGIN") || "*",
    allowMethods: ["GET", "POST", "OPTIONS"],
    allowHeaders: ["Content-Type"],
  }),
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
    ],
  });
});

// API endpoints
app.post("/api/new-recording", newRecordingHandler);
app.get("/api/live-transcription", liveTranscriptionHandler);

// 404 handler
app.notFound((c) => {
  return c.json({ error: "Not found" }, 404);
});

// Error handler
app.onError((err, c) => {
  console.error("Server error:", err);
  return c.json({ error: "Internal server error" }, 500);
});

const port = parseInt(Deno.env.get("PORT") || "8000");

console.log(`Server starting on port ${port}...`);
console.log(`Health check: http://localhost:${port}/`);
console.log(`\nAvailable endpoints:`);
console.log(`POST http://localhost:${port}/api/new-recording`);
console.log(`WebSocket ws://localhost:${port}/api/live-transcription`);

export { app };

Deno.serve({ port }, app.fetch);
