#!/usr/bin/env -S deno run --allow-read --allow-write

/**
 * Script to optionally update prompt files to use improved versions
 * Run with --apply flag to actually make changes
 */

const apply = Deno.args.includes("--apply");

async function updatePrompts() {
  console.log("Prompt Update Tool");
  console.log("==================\n");

  if (!apply) {
    console.log("Running in preview mode. Use --apply to make changes.\n");
  }

  // Check if improved prompt exists
  const improvedPromptPath = "./lib/prompts/summarize-prompt-improved.txt";
  const currentPromptPath = "./lib/prompts/summarize-prompt.txt";
  
  try {
    const improvedContent = await Deno.readTextFile(improvedPromptPath);
    const currentContent = await Deno.readTextFile(currentPromptPath);
    
    console.log("Current summarize prompt:");
    console.log("-".repeat(40));
    console.log(currentContent.substring(0, 200) + "...");
    console.log("\nImproved summarize prompt:");
    console.log("-".repeat(40));
    console.log(improvedContent.substring(0, 200) + "...");
    
    if (apply) {
      // Backup current prompt
      await Deno.writeTextFile(currentPromptPath + ".backup", currentContent);
      console.log(`\n✓ Created backup at ${currentPromptPath}.backup`);
      
      // You can uncomment this to replace the current prompt with improved version
      // await Deno.writeTextFile(currentPromptPath, improvedContent);
      // console.log(`✓ Updated ${currentPromptPath} with improved version`);
      
      console.log("\nNote: The improved prompt focuses more on actionable insights and handles edge cases better.");
      console.log("The current prompt is more focused on ultra-concise summaries with emojis.");
      console.log("Choose based on your users' preferences.");
    } else {
      console.log("\n→ Run with --apply to update the prompts");
    }
  } catch (error) {
    console.error("Error:", error.message);
  }
}

await updatePrompts();