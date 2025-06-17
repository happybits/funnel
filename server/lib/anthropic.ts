interface SummarizeResponse {
  bulletSummary: string[];
}

interface DiagramResponse {
  diagram: string;
  title: string;
  description: string;
}

export class AnthropicClient {
  private apiKey: string;
  private baseUrl = "https://api.anthropic.com/v1";

  constructor(apiKey: string) {
    this.apiKey = apiKey;
  }

  async summarizeTranscript(transcript: string): Promise<SummarizeResponse> {
    // Read prompt from file
    const promptTemplate = await Deno.readTextFile(
      new URL("./prompts/summarize-prompt.txt", import.meta.url),
    );
    const prompt = promptTemplate.replace("{{transcript}}", transcript);

    const response = await fetch(`${this.baseUrl}/messages`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-api-key": this.apiKey,
        "anthropic-version": "2023-06-01",
      },
      body: JSON.stringify({
        model: "claude-3-5-sonnet-20241022",
        max_tokens: 1024,
        messages: [
          {
            role: "user",
            content: prompt,
          },
        ],
      }),
    });

    if (!response.ok) {
      const error = await response.text();
      throw new Error(`Anthropic API error: ${response.status} - ${error}`);
    }

    const data = await response.json();
    const content = data.content[0].text;

    // Parse bullet points from the response
    const bulletPoints = content
      .split("\n")
      .filter((line: string) => line.trim().startsWith("•"))
      .map((line: string) => line.trim().substring(1).trim());

    return {
      bulletSummary: bulletPoints,
    };
  }

  async generateDiagram(transcript: string): Promise<DiagramResponse> {
    // Read prompt from file
    const promptTemplate = await Deno.readTextFile(
      new URL("./prompts/diagram-prompt.txt", import.meta.url),
    );
    const prompt = promptTemplate.replace("{{transcript}}", transcript);

    const response = await fetch(`${this.baseUrl}/messages`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-api-key": this.apiKey,
        "anthropic-version": "2023-06-01",
      },
      body: JSON.stringify({
        model: "claude-3-5-sonnet-20241022",
        max_tokens: 1024,
        messages: [
          {
            role: "user",
            content: prompt,
          },
        ],
      }),
    });

    if (!response.ok) {
      const error = await response.text();
      throw new Error(`Anthropic API error: ${response.status} - ${error}`);
    }

    const data = await response.json();
    const content = data.content[0].text;

    // Parse the response
    const titleMatch = content.match(/TITLE:\s*(.+)/);
    const descriptionMatch = content.match(/DESCRIPTION:\s*(.+)/);
    const diagramMatch = content.match(/DIAGRAM:\s*\n([\s\S]+?)$/);

    if (!titleMatch || !descriptionMatch || !diagramMatch) {
      throw new Error("Failed to parse diagram response");
    }

    return {
      title: titleMatch[1].trim(),
      description: descriptionMatch[1].trim(),
      diagram: diagramMatch[1].trim(),
    };
  }
}
