# Promptfoo Testing for Funnel API Prompts

This directory contains promptfoo configuration for testing the LLM prompts used
in the Funnel API.

## Setup

1. Install dependencies:
   ```bash
   npm install
   ```

2. Set up environment variables:
   ```bash
   export ANTHROPIC_API_KEY=your_key_here
   # or create a .env file
   ```

## Running Tests

Run all promptfoo tests:

```bash
npm run promptfoo:eval
```

View test results in the web UI:

```bash
npm run promptfoo:view
```

## Structure

- **promptfooconfig.yaml**: Main configuration file with test cases
- **lib/prompts/**: Actual prompt files used by the server
  - `summarize-prompt.txt`: Prompt for generating bullet summaries
  - `diagram-prompt.txt`: Prompt for generating ASCII diagrams
- **prompts/**: Symlinks to the actual prompts for promptfoo to use

## Test Cases

### Summarize Prompt Tests

1. **Joel's AI coding metaphor**: Tests conciseness, bullet count, and key
   concept extraction
2. **Startup pivot decision**: Tests extraction of key metrics and decision
   points

### Diagram Prompt Tests

1. **AI coding metaphor diagram**: Tests proper formatting and size constraints
2. **Software architecture decision**: Tests architectural concept visualization

## Assertions

### Summarize Tests

- Bullet count (3-6 bullets)
- Bullet length (< 80 chars each)
- Key concept inclusion
- No unnecessary introductions

### Diagram Tests

- Required sections (TITLE, DESCRIPTION, DIAGRAM)
- Title conciseness (3-5 words)
- Diagram size (≤ 15 lines, ≤ 60 chars wide)
- Relevant concept representation

## Modifying Prompts

To modify prompts:

1. Edit the files in `lib/prompts/`
2. The symlinks in `prompts/` will automatically reflect changes
3. Run `npm run promptfoo:eval` to test the updated prompts

The server reads prompts from the same `lib/prompts/` files, ensuring
consistency between testing and production.
