import { OpenAIClient } from "../lib/openai.ts";
import { AnthropicClient } from "../lib/anthropic.ts";

const MAX_FILE_SIZE = 25 * 1024 * 1024; // 25MB
const ALLOWED_TYPES = ["audio/mpeg", "audio/mp4", "audio/wav", "audio/m4a", "audio/x-m4a"];

export async function newRecordingHandler(req: Request): Promise<Response> {
  try {
    // Check content type
    const contentType = req.headers.get("content-type");
    if (!contentType || !contentType.includes("multipart/form-data")) {
      return new Response(
        JSON.stringify({ error: "Invalid content type. Expected multipart/form-data" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    // Parse multipart form data
    const formData = await req.formData();
    const audioFile = formData.get("audio") as File | null;
    const providedTranscript = formData.get("transcript") as string | null;
    const durationStr = formData.get("duration") as string | null;

    if (!audioFile) {
      return new Response(
        JSON.stringify({ error: "No audio file provided" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    // Validate file type
    if (!ALLOWED_TYPES.includes(audioFile.type)) {
      return new Response(
        JSON.stringify({ 
          error: `Invalid file type. Allowed types: ${ALLOWED_TYPES.join(", ")}` 
        }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    // Validate file size
    if (audioFile.size > MAX_FILE_SIZE) {
      return new Response(
        JSON.stringify({ error: "File too large. Maximum size is 25MB" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    console.log(`Processing audio file: ${audioFile.name}, size: ${audioFile.size}, type: ${audioFile.type}`);

    // Initialize clients
    const openaiApiKey = Deno.env.get("OPENAI_API_KEY");
    const anthropicApiKey = Deno.env.get("ANTHROPIC_API_KEY");
    
    if (!openaiApiKey || !anthropicApiKey) {
      return new Response(
        JSON.stringify({ error: "API keys not configured" }),
        { status: 500, headers: { "Content-Type": "application/json" } }
      );
    }
    
    const openaiClient = new OpenAIClient(openaiApiKey);
    const anthropicClient = new AnthropicClient(anthropicApiKey);

    // Step 1: Use provided transcript or transcribe audio using OpenAI Whisper
    let transcript: string;
    let duration: number;
    
    if (providedTranscript && durationStr) {
      // Use the provided transcript from live transcription
      console.log("Using provided transcript from live transcription");
      transcript = providedTranscript;
      duration = parseFloat(durationStr);
      console.log(`Provided transcript length: ${transcript.length} characters, duration: ${duration}s`);
    } else {
      // Transcribe audio using OpenAI Whisper
      console.log("Transcribing audio...");
      const transcriptionResponse = await openaiClient.transcribeAudio(audioFile);
      transcript = transcriptionResponse.transcript;
      duration = transcriptionResponse.duration;
      
      if (!transcript) {
        return new Response(
          JSON.stringify({ error: "Failed to transcribe audio" }),
          { status: 500, headers: { "Content-Type": "application/json" } }
        );
      }
      
      console.log(`Transcription complete. Length: ${transcript.length} characters`);
    }

    // Step 2: Generate bullet summary and diagram in parallel
    console.log("Generating bullet summary and diagram...");
    const [summaryResponse, diagramResponse] = await Promise.all([
      anthropicClient.summarizeTranscript(transcript),
      anthropicClient.generateDiagram(transcript),
    ]);
    
    const bulletSummary = summaryResponse.bulletSummary;
    const diagram = diagramResponse;

    // Duration is already provided by Whisper API

    const response = {
      transcript,
      duration,
      bulletSummary,
      diagram,
    };

    return new Response(
      JSON.stringify(response),
      { 
        status: 200, 
        headers: { "Content-Type": "application/json" } 
      }
    );

  } catch (error) {
    console.error("Error processing recording:", error);
    return new Response(
      JSON.stringify({ 
        error: "Failed to process recording",
        details: error instanceof Error ? error.message : "Unknown error"
      }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
}