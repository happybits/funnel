# Promptfoo Setup and Usage Guide

This guide documents how to set up and use promptfoo for testing LLM prompts, based on the official documentation and practical experience.

## What is Promptfoo?

Promptfoo is a testing framework for LLM prompts that allows you to:
- Test prompts across multiple providers
- Validate outputs with assertions
- Track performance and cost metrics
- Ensure consistency in LLM responses

## Installation

```bash
npm install -D promptfoo
```

## Basic Configuration Structure

Create a `promptfooconfig.yaml` file:

```yaml
# Description of your test suite
description: "Your test suite description"

# Define prompts to test
prompts:
  # Option 1: Direct file reference (recommended)
  - file://./path/to/prompt.txt
  
  # Option 2: With ID (avoid if causing issues)
  - id: prompt-name
    file: file://./path/to/prompt.txt

# Define providers to test against
providers:
  - openai:gpt-4
  - anthropic:claude-3-5-sonnet-20241022
  
# Define test cases
tests:
  - description: "Test case description"
    vars:
      variable1: "value1"
      variable2: "value2"
```

## Prompt Files and Variables

### Using Variables in Prompts

Promptfoo uses Nunjucks templating. In your prompt files:

```text
You are an assistant helping with {{task}}.

User input: {{userInput}}

Please provide {{outputFormat}}.
```

### File References

Always use the `file://` prefix when referencing prompt files:
- ✅ `file://./prompts/summarize.txt`
- ❌ `./prompts/summarize.txt`

## Common Issues and Solutions

### Issue 1: Variables Not Being Substituted

**Problem**: Prompt shows `{{variable}}` instead of actual value.

**Solution**: 
1. Use `file://` prefix for prompt files
2. Remove `id` field if it's causing conflicts
3. Ensure variables are defined in test `vars` section

### Issue 2: "Unknown assertion type" Errors

**Problem**: Assertions like `not-empty` or `is-not-empty` fail.

**Solution**: Use simpler assertion types or remove default assertions:
```yaml
# Instead of:
defaultTest:
  assert:
    - type: not-empty

# Just use specific assertions per test
```

### Issue 3: Prompts Not Loading

**Problem**: Only prompt ID shows instead of content.

**Solution**: Use direct file references without IDs:
```yaml
prompts:
  - file://./prompts/prompt1.txt
  - file://./prompts/prompt2.txt
```

## Best Practices

### 1. Use Symlinks for Single Source of Truth

If your application uses prompts, create symlinks in your promptfoo directory:

```bash
mkdir prompts
ln -s ../lib/prompts/actual-prompt.txt prompts/prompt.txt
```

### 2. Keep Configuration Simple

Start with a minimal configuration:
```yaml
description: "Basic prompt testing"

prompts:
  - file://./prompts/my-prompt.txt

providers:
  - anthropic:claude-3-5-sonnet-20241022

tests:
  - vars:
      input: "test input"
```

### 3. Use Environment Variables for API Keys

```bash
export OPENAI_API_KEY=your-key
export ANTHROPIC_API_KEY=your-key
```

### 4. Test Incrementally

Run with limited tests first:
```bash
promptfoo eval --filter-first-n 1
```

## Running Tests

### Basic Commands

```bash
# Run all tests
promptfoo eval

# Run without cache
promptfoo eval --no-cache

# Run specific number of tests
promptfoo eval --filter-first-n 2

# Output to file
promptfoo eval -o results.json

# View results in web UI
promptfoo view
```

### Useful Flags

- `--no-cache`: Force fresh API calls
- `--no-table`: Skip table output
- `-o <file>`: Save results to file
- `--filter-pattern <regex>`: Run specific tests
- `-j <number>`: Set concurrency level

## Assertions

### Simple Assertions

```yaml
tests:
  - vars:
      transcript: "..."
    assert:
      # JavaScript assertions (most flexible)
      - type: javascript
        value: |
          output.includes('keyword')
      
      # Contains JSON
      - type: contains-json
      
      # Semantic similarity
      - type: similar
        value: "expected output"
        threshold: 0.8
```

### Complex Assertions

```yaml
assert:
  - type: javascript
    value: |
      // Check multiple conditions
      const lines = output.split('\n');
      return lines.length >= 3 && 
             lines.every(line => line.length < 80);
```

## Project Structure Example

```
project/
├── promptfoo/
│   ├── promptfooconfig.yaml
│   ├── package.json
│   └── prompts/
│       ├── summarize.txt -> ../../lib/prompts/summarize-prompt.txt
│       └── diagram.txt -> ../../lib/prompts/diagram-prompt.txt
├── lib/
│   └── prompts/
│       ├── summarize-prompt.txt
│       └── diagram-prompt.txt
└── package.json
```

## Debugging Tips

1. **Check what's being sent**: Use `-o debug.json` and examine the output
2. **Verbose mode**: Add `-v` flag for more details
3. **Test prompt loading**: Check if `prompt.raw` contains full prompt or just ID
4. **API errors**: Ensure API keys are set correctly

## Integration with CI/CD

```yaml
# .github/workflows/test-prompts.yml
name: Test Prompts
on: [push]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
      - run: npm install
      - run: npx promptfoo eval
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
```

## Cost Optimization

- Use `--filter-first-n` during development
- Cache results when possible (remove `--no-cache`)
- Test with smaller models first
- Use `--filter-pattern` to test specific cases

## Troubleshooting Checklist

- [ ] API keys are set in environment
- [ ] Prompt files use `file://` prefix
- [ ] Variables are defined in test `vars`
- [ ] Symlinks point to correct files
- [ ] No conflicting `id` fields in prompts
- [ ] Simple configuration without complex assertions

Remember: Start simple, test one thing at a time, and gradually add complexity.