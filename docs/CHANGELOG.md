# Funnel Project Changelog

## [Unreleased] - 2025-06-25

### Added
- Comprehensive iOS integration test suite using XCUITest with real audio recording functionality
- AudioTestEnvironment class for virtual audio routing through BlackHole audio driver
- MockWebSocketServer for verifying real-time audio streaming during tests
- LLMContentVerifier utility for pattern-based validation of dynamic AI-generated content
- Test runner script (run-ui-tests.sh) for easy test execution and reporting
- Support for synthetic audio generation (tones and speech patterns) in tests
- Multiple test scenarios including error handling, network failures, and UI navigation

### Fixed
- Fixed WebSocket connection error in stream-recording endpoint by replacing Hono's upgradeWebSocket with native Deno.upgradeWebSocket
- Fixed CORS middleware interference with WebSocket upgrade requests by skipping CORS for WebSocket connections
- Improved WebSocket error handling with proper request validation before upgrade
- Fixed audio data handling to support both ArrayBuffer and Blob types from browser MediaRecorder

### Changed
- Refactored stream-recording-ws.ts to use native WebSocket event handlers instead of Hono's wrapper
- Added explicit WebSocket upgrade header checking for better error messages
