import { load } from "@std/dotenv";
import { newRecordingHandler } from "./api/new-recording-pure.ts";
import { liveTranscriptionHandler } from "./api/live-transcription-pure.ts";

// Load environment variables
console.log("Loading .env file...");
await load({ export: true });
console.log("Environment variables loaded");

// Debug: Check if API keys are loaded
console.log(
  "DEEPGRAM_API_KEY:",
  Deno.env.get("DEEPGRAM_API_KEY") ? "Found" : "Not found",
);
console.log(
  "OPENAI_API_KEY:",
  Deno.env.get("OPENAI_API_KEY") ? "Found" : "Not found",
);
console.log(
  "ANTHROPIC_API_KEY:",
  Deno.env.get("ANTHROPIC_API_KEY") ? "Found" : "Not found",
);

const port = parseInt(Deno.env.get("PORT") || "8000");
const corsOrigin = Deno.env.get("CORS_ORIGIN") || "*";

console.log(`Server starting on port ${port}...`);
console.log(`Health check: http://localhost:${port}/`);
console.log(`\nAvailable endpoints:`);
console.log(`POST http://localhost:${port}/api/new-recording`);
console.log(`WebSocket ws://localhost:${port}/api/live-transcription`);

Deno.serve({ port }, async (req) => {
  const url = new URL(req.url);
  const method = req.method;

  // CORS headers
  const corsHeaders = {
    "Access-Control-Allow-Origin": corsOrigin,
    "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type",
  };

  // Handle preflight requests
  if (method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }

  // Log request
  console.log(`<-- ${method} ${url.pathname}`);
  const startTime = Date.now();

  try {
    // Health check endpoint
    if (url.pathname === "/" && method === "GET") {
      const response = new Response(
        JSON.stringify({
          status: "ok",
          service: "Funnel API",
          version: "1.0.0",
          endpoints: [
            "POST /api/new-recording",
            "WebSocket /api/live-transcription",
          ],
        }),
        {
          status: 200,
          headers: {
            "Content-Type": "application/json",
            ...corsHeaders,
          },
        },
      );
      console.log(
        `--> ${method} ${url.pathname} 200 ${Date.now() - startTime}ms`,
      );
      return response;
    }

    // POST /api/new-recording
    if (url.pathname === "/api/new-recording" && method === "POST") {
      const response = await newRecordingHandler(req);
      console.log(
        `--> ${method} ${url.pathname} ${response.status} ${
          Date.now() - startTime
        }ms`,
      );
      return new Response(response.body, {
        status: response.status,
        headers: {
          ...response.headers,
          ...corsHeaders,
        },
      });
    }

    // WebSocket /api/live-transcription
    if (url.pathname === "/api/live-transcription" && method === "GET") {
      const upgrade = req.headers.get("upgrade") || "";
      if (upgrade.toLowerCase() !== "websocket") {
        return new Response("Expected WebSocket", {
          status: 400,
          headers: corsHeaders,
        });
      }

      const response = liveTranscriptionHandler(req);
      console.log(
        `--> ${method} ${url.pathname} 101 ${Date.now() - startTime}ms`,
      );
      return response;
    }

    // Test page for live transcription
    if (url.pathname === "/test-live-transcription.html" && method === "GET") {
      try {
        const html = await Deno.readTextFile("./test-live-transcription.html");
        const response = new Response(html, {
          status: 200,
          headers: {
            "Content-Type": "text/html",
            ...corsHeaders,
          },
        });
        console.log(
          `--> ${method} ${url.pathname} 200 ${Date.now() - startTime}ms`,
        );
        return response;
      } catch {
        const response = new Response("Test file not found", {
          status: 404,
          headers: corsHeaders,
        });
        console.log(
          `--> ${method} ${url.pathname} 404 ${Date.now() - startTime}ms`,
        );
        return response;
      }
    }

    // 404 handler
    const notFoundResponse = new Response(
      JSON.stringify({ error: "Not found" }),
      {
        status: 404,
        headers: {
          "Content-Type": "application/json",
          ...corsHeaders,
        },
      },
    );
    console.log(
      `--> ${method} ${url.pathname} 404 ${Date.now() - startTime}ms`,
    );
    return notFoundResponse;
  } catch (error) {
    console.error("Server error:", error);
    const errorResponse = new Response(
      JSON.stringify({ error: "Internal server error" }),
      {
        status: 500,
        headers: {
          "Content-Type": "application/json",
          ...corsHeaders,
        },
      },
    );
    console.log(
      `--> ${method} ${url.pathname} 500 ${Date.now() - startTime}ms`,
    );
    return errorResponse;
  }
});
