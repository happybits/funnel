#!/usr/bin/env -S deno run --allow-read --allow-env --allow-net

import { load } from "@std/dotenv";
import { AnthropicClient } from "./lib/anthropic.ts";

// Load environment variables
await load({ export: true });

const testCases = [
  {
    name: "Empty recording",
    transcript: "",
  },
  {
    name: "Very short reminder",
    transcript: "Buy milk",
  },
  {
    name: "Short reminder with context",
    transcript: "Remember to email Sarah about the design mockups",
  },
  {
    name: "Rambling startup idea",
    transcript:
      "So I've been thinking about this idea for like the past week and it's been keeping me up at night. What if we created an app that helps people, you know, actually stick to their habits? I know there's a million habit trackers out there but hear me out. The problem with all of them is that they're too complicated or they make you feel guilty when you miss a day. So what if instead of tracking streaks, we focused on, um, momentum? Like, the app would understand that life happens and missing a day doesn't mean you failed. It would be more like a supportive friend rather than a strict teacher. Oh and another thing - it could use AI to suggest the best time to do your habit based on your calendar and past behavior. Like if you usually go for runs in the morning but you have an early meeting, it could suggest doing it at lunch instead. And maybe it could even connect with your friends so you could have accountability buddies but in a fun way, not a judgmental way. I don't know, maybe this is stupid but I really think there's something here.",
  },
  {
    name: "Technical brainstorm",
    transcript:
      "Okay so I'm trying to figure out the best way to architect this new feature. We need real-time updates but I'm not sure if we should use websockets or just poll every few seconds. Websockets would be better for performance but they're harder to implement and we'd need to handle reconnection logic and all that stuff. Actually wait, what about using Server-Sent Events? That might be a good middle ground. Oh but then we'd need to think about scalability. If we have thousands of users all connected at once, that could get expensive. Maybe we should start with polling and then upgrade to websockets later if we need to? But then we'd be building technical debt from the start. Ugh, architectural decisions are hard. Actually, you know what, let me think about this differently. What's the actual user requirement here? They need updates within, let's say, 5 seconds. So polling every 3 seconds would probably be fine for MVP. We can always optimize later.",
  },
];

async function testPrompts() {
  const anthropicKey = Deno.env.get("ANTHROPIC_API_KEY");
  if (!anthropicKey) {
    console.error("Error: ANTHROPIC_API_KEY not set");
    Deno.exit(1);
  }

  const client = new AnthropicClient(anthropicKey);

  for (const testCase of testCases) {
    console.log(`\n${"=".repeat(80)}`);
    console.log(`Test Case: ${testCase.name}`);
    console.log(`${"=".repeat(80)}`);
    console.log(`\nTranscript: "${testCase.transcript}"\n`);

    try {
      // Test bullet summary
      console.log("Generating bullet summary...");
      const summaryResult = await client.summarizeTranscript(
        testCase.transcript,
      );
      console.log("\nBullet Summary:");
      summaryResult.bulletSummary.forEach((bullet) => {
        console.log(`  • ${bullet}`);
      });

      // Test edited transcript
      console.log("\nGenerating edited transcript...");
      const editResult = await client.editTranscript(testCase.transcript);
      console.log("\nEdited Transcript:");
      console.log(editResult.editedTranscript);
    } catch (error) {
      console.error(`Error: ${error.message}`);
    }
  }
}

// Run the tests
await testPrompts();
