# Promptfoo Testing for Funnel

This directory contains prompt testing configurations for the Funnel API using promptfoo.

## Prompts Being Tested

### Original Prompts
1. **Summarize** - Creates bullet point summaries from transcripts
2. **Diagram** - Generates ASCII art diagrams from concepts

### New Prompts
3. **Lightly Edited Transcript** - Formats raw transcripts for readability without changing wording
4. **Things to Think About** - Generates 2-3 thought-provoking questions based on the user's ideas

## Running Tests

### Test the new prompts only:
```bash
npm run promptfoo:eval:new
```

### Test all prompts (original + new):
```bash
npm run promptfoo:eval:all
```

### View results in web browser:
```bash
npm run promptfoo:view
```

## What the New Prompts Do

### Lightly Edited Transcript
- Adds section headers (##) for major topic shifts
- Removes filler words (um, uh, like, you know)
- Fixes punctuation and adds paragraph breaks
- **DOES NOT** change wording or rephrase sentences
- **DOES NOT** summarize or condense content
- Preserves the speaker's exact words and voice

### Things to Think About
- Generates 2-3 thought-provoking questions
- Questions are specific to the user's idea (not generic)
- Balances challenging assumptions with inspiring new thinking
- Helps users explore practical, emotional, and strategic aspects
- Avoids yes/no questions - all questions are open-ended

## Test Cases

1. **AI Coding Metaphor** - Tests section organization and filler removal
2. **Startup Pivot** - Tests question generation for business decisions
3. **Bike Shop Dream** - Tests both prompts on a concrete business idea
4. **Short Reminder** - Edge case: very brief transcript
5. **Technical Discussion** - Tests multiple section headers and technical term preservation

## Assertions

The tests include assertions to verify:
- Edited transcripts have section headers and remove filler words
- Original wording and key phrases are preserved
- Questions follow the bullet format and end with "?"
- 2-3 questions are generated (not more, not less)
- Questions are specific to the content, not generic

## Environment Setup

Make sure you have your Anthropic API key set:
```bash
export ANTHROPIC_API_KEY=your_key_here
```