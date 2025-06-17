import {
  assertEquals,
  assertExists,
} from "https://deno.land/std@0.215.0/assert/mod.ts";
import type { SummarizeResponse } from "../types/api.ts";

// Test data - Joel's word vomit example
const joelWordVomit =
  `Okay. So I am thinking about an idea I had for an article which is I wanna talk about how what coding With Agentic coding assistance like Claude Code, and Cursor, it feels like. And I've heard it described being a manager. You're gonna be a manager. It's like being a manager of humans. You've got all these AI agents. They're just like little humans that know, human engineers, and you just have to tell them what to do, and they'll magically write code for you and then maybe they do it wrong, and you just have to give them feedback, and then it'll work. But I don't really think that metaphor is super accurate. And but I've been trying to think of what is a better metaphor. We're like, what is this like? And, you know, is it using a machine? Is it using a is it coding with a broom or something? Or is it coding with a know, is it building with things with bricks? Or with, Construction equipment For what? And I think the best example I have come across is I was thinking of This video game I used to play, for, like, the Nintendo 64 maybe, that was your Mickey Mouse and you have a magic paintbrush. You can point this magic paintbrush of things in your black and white world, and it transforms them into colorful, amazing, magical things. But the thing about this video game is that it was also really confusing, and the UI was terrible, and it was just So this paintbrush that was so magical and powerful was extremely difficult to use. And oftentimes, wouldn't work at all because I didn't know how to Like, where to point it or how to use it or what to do with it. And so I think that is the metaphor I would say is it's like having a very difficult to use paintbrush magic paintbrush that if you use it perfectly, You can paint. Way faster then you can paint with a regular paintbrush. But how you use it is not the same as how you ask a human to do something for you.`;

// Skip these tests if API key is not available
const ANTHROPIC_API_KEY = Deno.env.get("ANTHROPIC_API_KEY");
const skipIntegration = !ANTHROPIC_API_KEY;

Deno.test({
  name: "POST /api/summarize - integration test with real API",
  ignore: skipIntegration,
  async fn() {
    // This test requires the server to be running
    // Start the server with: deno run --allow-all server/main.ts
    const res = await fetch("http://localhost:8000/api/summarize", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        transcript: joelWordVomit,
      }),
    });
    assertEquals(res.status, 200);

    const body: SummarizeResponse = await res.json();
    assertExists(body.bulletSummary);
    assertEquals(Array.isArray(body.bulletSummary), true);

    // Should produce 3-6 concise bullet points
    assertEquals(body.bulletSummary.length >= 3, true);
    assertEquals(body.bulletSummary.length <= 6, true);

    // Each bullet should be concise
    body.bulletSummary.forEach((bullet, index) => {
      console.log(`Bullet ${index + 1}: ${bullet} (${bullet.length} chars)`);
      assertEquals(bullet.length < 80, true); // Allow slightly more than 60 for flexibility
    });

    console.log("\nFull summary:");
    body.bulletSummary.forEach((bullet) => console.log(`• ${bullet}`));
  },
});

if (skipIntegration) {
  console.log(
    "\n⚠️  Integration tests skipped - set ANTHROPIC_API_KEY to run them",
  );
}
