# Funnel Project Changelog

## [Unreleased] - 2025-06-25

### Fixed
- Fixed WebSocket connection error in stream-recording endpoint by replacing Hono's upgradeWebSocket with native Deno.upgradeWebSocket
- Fixed CORS middleware interference with WebSocket upgrade requests by skipping CORS for WebSocket connections
- Improved WebSocket error handling with proper request validation before upgrade
- Fixed audio data handling to support both ArrayBuffer and Blob types from browser MediaRecorder

### Changed
- Refactored stream-recording-ws.ts to use native WebSocket event handlers instead of Hono's wrapper
- Added explicit WebSocket upgrade header checking for better error messages
