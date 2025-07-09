# Funnel - Audio Note Summarizer

## Project Structure
For a detailed overview of the codebase architecture, see `project-structure.md`. This includes:
- Complete directory structure
- API endpoint reference
- Tech stack details
- Development workflows

## Development Commands - ALWAYS Use Makefile

**ALWAYS prefer using Makefile commands over writing your own CLI commands.** The project includes comprehensive Makefiles for both iOS and server development. Only write custom commands if the Makefile doesn't have what you need.

## Debugging Test Failures
When iOS tests fail, check `server/logs/latest.log` for API errors or server issues.

