interface SummarizeResponse {
  bulletSummary: string[];
}

interface DiagramResponse {
  diagram: string;
  title: string;
  description: string;
}

interface EditTranscriptResponse {
  editedTranscript: string;
}

interface ThingsToThinkAboutResponse {
  thingsToThinkAbout: string[];
}

export class AnthropicClient {
  private apiKey: string;
  private baseUrl = "https://api.anthropic.com/v1";

  constructor(apiKey: string) {
    this.apiKey = apiKey;
  }

  async summarizeTranscript(transcript: string): Promise<SummarizeResponse> {
    // Handle empty transcript
    if (!transcript || transcript.trim() === "") {
      return {
        bulletSummary: ["Ah, the recording is empty!"],
      };
    }

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

    // If no bullet points found or very short transcript, create a simple one
    if (bulletPoints.length === 0) {
      return {
        bulletSummary: [transcript.trim()],
      };
    }

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

    console.log("Diagram generation response:", content);

    // Parse the response with more flexible regex
    const titleMatch = content.match(/TITLE:\s*(.+)/i);
    const descriptionMatch = content.match(/DESCRIPTION:\s*(.+)/i);
    const diagramMatch = content.match(/DIAGRAM:\s*\n([\s\S]+)/i);

    if (!titleMatch || !descriptionMatch || !diagramMatch) {
      console.error("Failed to parse diagram response. Content:", content);
      throw new Error(
        `Failed to parse diagram response. Missing: ${
          !titleMatch ? "title" : ""
        } ${!descriptionMatch ? "description" : ""} ${
          !diagramMatch ? "diagram" : ""
        }`,
      );
    }

    return {
      title: titleMatch[1].trim(),
      description: descriptionMatch[1].trim(),
      diagram: diagramMatch[1].trim(),
    };
  }

  async editTranscript(transcript: string): Promise<EditTranscriptResponse> {
    // Handle empty transcript
    if (!transcript || transcript.trim() === "") {
      return {
        editedTranscript: "## Empty Recording\n\nAh, the recording is empty!",
      };
    }

    // For very short transcripts, add a simple header
    const wordCount = transcript.trim().split(/\s+/).length;
    if (wordCount <= 5) {
      return {
        editedTranscript: `## Quick Note\n\n${transcript.trim()}.`,
      };
    }

    // Read prompt from file
    const promptTemplate = await Deno.readTextFile(
      new URL("./prompts/edit-transcript-prompt.txt", import.meta.url),
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
        max_tokens: 2048,
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
    const editedTranscript = data.content[0].text;

    return {
      editedTranscript,
    };
  }

  async generateThingsToThinkAbout(
    transcript: string,
  ): Promise<ThingsToThinkAboutResponse> {
    // Handle empty transcript
    if (!transcript || transcript.trim() === "") {
      return {
        thingsToThinkAbout: ["What idea would you like to explore today?"],
      };
    }

    // For very short transcripts, provide generic reflection questions
    const wordCount = transcript.trim().split(/\s+/).length;
    if (wordCount <= 5) {
      return {
        thingsToThinkAbout: [
          "What inspired this thought?",
          "How might you expand on this idea?",
        ],
      };
    }

    // Read prompt from file
    const promptTemplate = await Deno.readTextFile(
      new URL("./prompts/things-to-think-about-prompt.txt", import.meta.url),
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
    const questions = content
      .split("\n")
      .filter((line: string) => line.trim().startsWith("•"))
      .map((line: string) => line.trim().substring(1).trim());

    // If no questions found, return a default
    if (questions.length === 0) {
      return {
        thingsToThinkAbout: [
          "What aspects of this idea excite you the most?",
          "What would need to be true for this to succeed?",
        ],
      };
    }

    return {
      thingsToThinkAbout: questions,
    };
  }
}
