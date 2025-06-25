import { AnthropicClient } from "./anthropic.ts";

export interface ProcessedRecording {
  id: string;
  transcript: string;
  duration: number;
  bulletSummary: string[];
  diagram: {
    title: string;
    description: string;
    content: string;
  };
  createdAt: Date;
  audioSize?: number;
}

export async function generateBulletSummary(
  transcript: string,
): Promise<string[]> {
  const anthropicKey = Deno.env.get("ANTHROPIC_API_KEY");
  if (!anthropicKey) {
    throw new Error("ANTHROPIC_API_KEY not configured");
  }

  const client = new AnthropicClient(anthropicKey);
  const result = await client.summarizeTranscript(transcript);
  return result.bulletSummary;
}

export async function generateDiagram(transcript: string): Promise<{
  title: string;
  description: string;
  content: string;
}> {
  const anthropicKey = Deno.env.get("ANTHROPIC_API_KEY");
  if (!anthropicKey) {
    throw new Error("ANTHROPIC_API_KEY not configured");
  }

  const client = new AnthropicClient(anthropicKey);
  const result = await client.generateDiagram(transcript);
  return {
    title: result.title,
    description: result.description,
    content: result.diagram,
  };
}
