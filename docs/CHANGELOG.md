# Changelog

All notable changes to the Funnel project will be documented in this file.

## [Unreleased]

### Changed
- **Updated StreamingVsFileUploadTests** (2025-07-02)
  - Now uses `APIClient.shared.processAudio()` instead of manual URLSession multipart form construction
  - Simplified test code by leveraging existing API client infrastructure
- **Consolidated API layer** (2025-07-02)
  - Removed redundant `FunnelAPIService` class
  - Moved `processAudio()` method directly into `APIClient`
  - Updated all references to use `APIClient.shared` directly

### Added
- **New simplified V2 API endpoints for audio streaming** (2025-01-01)
  - `WebSocket /api/v2/recordings/:recordingId/stream` - Stream audio without receiving partial transcripts
  - `POST /api/v2/recordings/:recordingId/finalize` - Finalize recording and save transcript to KV
  - `GET /api/v2/recordings/:recordingId` - Retrieve transcript and generate AI summaries on-demand
- **Comprehensive iOS integration tests for V2 APIs**
  - `AudioStreamingServerV2Tests` - Tests with generated sine wave audio
  - `AudioStreamingServerV2RealAudioTests` - Tests with real audio files and speech synthesis

### Changed
- **V2 API simplified flow**:
  - V2 WebSocket endpoint only sends `ready` and `processingComplete` messages (no partial transcripts)
  - V2 finalization saves complete transcript to Deno KV for later retrieval
  - V2 GET endpoint generates AI summaries on-demand instead of during finalization
  - Client no longer needs to handle partial transcripts or maintain transcript state

### Changed
- **Improved transcription finalization flow** (2025-01-07)
  - Server: Removed premature `transcription_complete` WebSocket message
  - Server: Updated finalize endpoint to send Deepgram `CloseStream` message when called
  - Server: Finalize endpoint waits for Deepgram metadata response confirming all audio processed
  - Server: Added in-memory storage of active Deepgram connections for access during finalization
  - Test: Added `testSimpleStreamAudioToServer` for testing the complete audio streaming flow
  - Test: Streams all audio chunks, then calls finalize endpoint (no arbitrary waits)
  - Test: Finalize endpoint blocks until Deepgram confirms completion, ensuring full transcript

### Added
- **Two-tier integration testing strategy** (2025-01-07)
  - Tier 1: WebSocket Integration Test - Tests server API contracts without hardware dependencies
  - Tier 2: Audio Pipeline Integration Test - Tests complete audio processing with file input
  - DirectWebSocketStreamer for isolated WebSocket testing
  - Integration with xctesthtmlreport for visual test results
- **Dependency injection for AudioRecorderManager**
  - Created AudioSourceProtocol for abstracting audio input sources
  - Implemented MicrophoneAudioSource for production use
  - Implemented FilePlaybackAudioSource for testing with audio files
  - Modified AudioRecorderManager to accept audio source via dependency injection

### Changed
- **Enhanced Makefile test command**: Now automatically generates HTML test reports
  - Runs xctesthtmlreport after test execution
  - Shows clickable file:// URL for viewing results
  - Added test-results to .gitignore and clean-tests target

### Technical Details
- Tests can run on simulator without microphone hardware
- File playback flows through the exact same audio pipeline as microphone input
- Tests verify: audio format conversion, WebSocket streaming, live transcription, bullet summaries, and diagram generation
- Comprehensive test coverage for both API integration and audio processing pipeline

### Added
- **Testing Infrastructure** (2025-06-30)
  - Added comprehensive iOS testing guide (`docs/ios-testing-guide.md`)
  - Enhanced Makefile with improved test commands:
    - `make test` - Run all tests with result bundle
    - `make test-class CLASS=Name` - Run specific test class
    - `make test-method TEST=Class/method` - Run specific test method
    - `make test-results` - Show test results summary
    - `make test-failures` - Show test failures with details
    - `make clean-tests` - Clean test result bundles
  - Documented best practices for making test output visible to automated tools
  - Added examples of using assertions for test visibility instead of print statements

### Fixed
- **iOS app now properly saves transcripts**: Fixed issue where iOS live streaming wasn't saving transcripts
  - Added finalize endpoint call after recording stops (matching web client behavior)
  - Updated RecordingManager to handle live streaming recordings differently
  - Exposed recording ID from AudioRecorderManager for finalization
  - iOS now calls POST `/api/recordings/{recordingId}/done` to finalize and save transcripts

### Changed
- **Upgraded Deepgram model to Nova 3**: Updated transcription model from nova-2 to nova-3
  - 53.4% reduction in word error rate for streaming transcription
  - Enhanced comprehension of domain-specific terminology
  - Support for real-time multilingual conversation transcription
  - Updated both live transcription endpoints and default configuration

### Added
- **Live audio transcription with Deepgram**: Real-time transcription during recording
  - WebSocket endpoint `/api/live-transcription` for streaming audio
  - Deepgram integration using WebSocket API for minimal latency
  - Client receives transcripts as user speaks with interim and final results
  - Keep-alive mechanism to maintain connection during pauses
  - Support for WebM/Opus audio streaming from browser clients
  - Test HTML client included for validating WebSocket functionality
  - New endpoints: `/api/stream-recording-ws` for WebSocket streaming
  - Test page at `/test` for browser-based testing of real-time transcription
- **Deepgram client library**: Custom Deno implementation for Deepgram WebSocket API
  - Type-safe interfaces for transcription options and responses
  - Configurable model, language, and formatting options
  - Built-in error handling and connection management
- **Admin interface**: Added `/admin` endpoint for monitoring and testing
  - Real-time view of active WebSocket connections
  - Audio streaming and transcription testing capabilities

### Fixed
- Fixed WebSocket connection error in stream-recording endpoint by replacing Hono's upgradeWebSocket with native Deno.upgradeWebSocket
- Fixed CORS middleware interference with WebSocket upgrade requests by skipping CORS for WebSocket connections
- Improved WebSocket error handling with proper request validation before upgrade
- Fixed audio data handling to support both ArrayBuffer and Blob types from browser MediaRecorder

### Changed
- Refactored stream-recording-ws.ts to use native WebSocket event handlers instead of Hono's wrapper
- Added explicit WebSocket upgrade header checking for better error messages
- Enhanced AI processing to pass transcripts to Claude for better context in summaries
- Updated server documentation with recording flow diagrams

### Added
- **Custom live glassmorphism implementation** with performance optimizations
  - LiveBlurView using UIVisualEffectView for efficient real-time blur
  - LiveGlassmorphicModifier for easy application of glass effects  
  - Debug toggle to enable/disable blur effects globally
  - GlassRecord component demonstrating glassmorphic record button with Figma-accurate design
- **DebugSettings environment object** for global debug preferences
- **CheckboxToggleStyle component** for consistent toggle UI across the app

### Changed
- **Glassmorphic blur implementation**: Replaced CADisplayLink-based blur with UIVisualEffectView
  - Significantly improved performance by using native iOS blur
  - Forces light mode on blur view with .systemUltraThinMaterialLight for minimal frosting
  - Blur can now be toggled on/off for performance testing
- **NewRecordingView**: Added blur toggle checkbox in header for debugging
- **Selective blur application**: Blur effects now only apply to recording controls
  - Created separate `liveGlassmorphicCell` modifier for content cards without blur
  - Recording controls maintain full glassmorphic effect with blur
  - Content cards and list items use gradient-only glassmorphic effect for better performance

### Enhanced
- **Card Layout in SwipeableCardsView**: Improved card visibility and centering
  - Cards now use full screen width minus 60px (30px padding on each side)
  - Adjacent cards peek 30px on both sides of the selected card
  - Added horizontal spacers (22.5px) to ensure proper centering accounting for card spacing
  - Card spacing set to 15px between cards
  - Selected card is now always centered in the viewport

### Fixed
- **Gesture recognizer performance**: Removed triple-tap gesture recognizer that was causing UI delays
  - Removed font debug view and all associated triple-tap gesture handlers
  - This eliminates the 350ms delay when tapping buttons that was introduced by gesture conflict
  - UI interactions are now instantaneous without gesture recognizer interference

### Changed
- **Recordings list layout**: Extended scroll view to full screen height with floating record button
  - Scroll view now extends from below the logo to the bottom of the screen
  - Record button floats above the scroll view at the bottom
  - Provides better use of screen space for viewing past recordings
- **Home screen gradient**: Updated to use rainbow gradient matching Figma design
  - Replaced solid orange gradient with animated rainbow gradient from GradientBackground component
  - Applied same gradient to both home screen and swipeable cards view for consistency
  - Rainbow gradient includes 6 color stops with breathing animation effect
  - Matches Figma design at https://www.figma.com/design/KnkuJhDf5CxBwYt4xZtSEZ/Funnel-Design-File-6-18?node-id=67-239
- **Glassmorphic modifier**: Added 50% dark grey backdrop for improved readability
  - Added `Color(white: 0.2).opacity(0.5)` layer before blur effect
  - Ensures text and UI elements remain readable over the rainbow gradient
  - Maintains the blur and gradient overlay effects while improving contrast

### Verified
- **Gradient Background Colors**: Confirmed exact match between Figma design and implementation
  - Extracted gradient from Figma node ID 67:211 (gradient fill)
  - Linear gradient with 6 color stops at positions 0, 0.2, 0.4, 0.6, 0.8, 1.0
  - Colors (RGB values):
    - Position 0: (0.576, 0.651, 0.878) - Light blue/purple
    - Position 0.2: (0.404, 0.816, 0.796) - Cyan/turquoise
    - Position 0.4: (0.976, 0.839, 0.459) - Yellow
    - Position 0.6: (0.969, 0.698, 0.459) - Orange
    - Position 0.8: (0.965, 0.294, 0.298) - Red/coral
    - Position 1.0: (0.827, 0.435, 0.749) - Purple/magenta
  - All values match exactly with GradientBackground.swift implementation

### Fixed
- **Button asset references in SwipeableCardsView**: Fixed incorrect image names
  - Changed "backbtn" to "BackBtn" to match actual asset names
  - Changed "addbtn" to "AddBtn" to match actual asset names
  - Fixed case sensitivity issue preventing buttons from displaying

### Enhanced
- **Header design in SwipeableCardsView**: Improved header layout to match Figma design
  - Added truncated recording title between Back and Add buttons
  - Title displays first 30 characters of first bullet point with ellipsis if needed
  - Applied proper text styling with gradient effect and shadows
  - Added InnerShadowModifier for text inner shadow effect
  - Adjusted padding and spacing to match Figma specifications
  - Header now shows contextual title instead of being empty

### Changed
- **Updated app display name**: Changed from "Funnel" to "Funnel - Think Better" for Xcode Cloud compatibility
  - Added INFOPLIST_KEY_CFBundleDisplayName to project.yml
  - Updated microphone usage description to use new app name

## [0.10.0] - 2025-06-15

### Added
- **SwipeableCardsView**: Implemented card-based interface for viewing recording details
  - Custom card layout with proper sizing (screen width - 60px)
  - Adjacent card peeking (30px on each side)
  - Smooth swipe animations with haptic feedback
  - Bullet summary, transcript, and diagram cards
  - Navigation header with back button
- **ProcessedRecordingView**: Complete implementation of multi-format display
  - Integrated with SwipeableCardsView for better UX
  - Full transcript display with timestamps
  - Bullet point summary with formatted list
  - Diagram/visual representation support
- **Navigation Flow**: Seamless flow from recording → processing → viewing results
  - Automatic navigation after recording completes
  - Loading states during processing
  - Error handling with user feedback
- **RecordingCard UI Component**: Reusable component for displaying recording list items
  - Glassmorphic design matching app theme
  - Duration formatting
  - Truncated preview text
  - Consistent styling across the app

### Changed
- **ProcessingView**: Enhanced with improved visual feedback
  - Progress indicators for each processing step
  - Animated transitions between states
  - Better error messaging
- **Recording Model**: Extended with computed properties
  - Added formattedDuration for display
  - Added bulletSummaryText for preview
  - Improved optional handling
- **Navigation Structure**: Streamlined app navigation
  - Centralized navigation state
  - Predictable back button behavior
  - Maintained recording context throughout flow

### Fixed
- Fixed navigation path issues when processing recordings
- Fixed model context passing between views
- Fixed timestamp formatting in transcript display
- Fixed card sizing calculations for proper centering

### Technical Details
- SwipeableCardsView uses GeometryReader for dynamic sizing
- Card animations use spring physics for natural feel
- Haptic feedback on card changes for tactile response
- Efficient view updates with @Published properties

## [0.9.0] - 2025-06-17

### Changed
- **Simplified API to single endpoint**: Removed individual `/api/transcribe`, `/api/summarize`, and `/api/diagram` endpoints
- **Renamed endpoint**: Changed `/api/process` to `/api/new-recording` for better clarity
- **Updated iOS app**: Now uses the single `/api/new-recording` endpoint exclusively
- **Simplified test structure**: Consolidated test commands to single `deno task test`

### Added
- Comprehensive test suite for `/api/new-recording` endpoint
- Test fixture with sample audio recording at `server/tests/fixtures/sample-audio-recording.m4a`
- Error handling tests for missing files and invalid file types
- Test scripts for manual testing with curl

### Removed
- Individual API endpoints (`/api/transcribe`, `/api/summarize`, `/api/diagram`)
- Unused API request/response types from both server and iOS
- Test with synthetic WAV file (now only testing with real audio)
- Multiple test commands (consolidated to single `deno task test`)

### Technical Details
- Server now has single endpoint that handles complete audio processing pipeline
- Parallel processing of summary and diagram generation for better performance
- All tests use real audio file for more realistic validation
- Simplified API reduces network calls from 3 to 1

## [0.8.0] - 2025-06-17

### Changed
- **Major UI Restructuring**: Consolidated recording interface
  - Merged `FunnelEmptyView` and `FunnelRecordingView` into single `NewRecordingView`
  - Removed "Funnel" prefix from view names for cleaner naming convention
  - Created `RecordingControls` component that conditionally shows recording/stop buttons based on state
  - Recording view now uses smooth state transitions instead of view swapping

### Added
- **CurrentRecordingProvider**: New EnvironmentObject for centralized recording state management
  - Manages AudioRecorderManager instance
  - Handles recording state, time tracking, and waveform data
  - Provides app-wide access to recording functionality

### Removed
- Deleted `FunnelEmptyView.swift` (functionality merged into NewRecordingView)
- Deleted `FunnelRecordingView.swift` (functionality merged into NewRecordingView)
- Removed local recording state management from individual views

### Technical Details
- Recording state is now centralized in CurrentRecordingProvider EnvironmentObject
- Single view architecture with conditional UI based on recording state
- Improved animation and transition smoothness between recording states

## [0.7.0] - 2025-06-17

### Added
- Combined API endpoint `/api/process` on server that handles audio upload, transcription, summarization, and diagram generation in a single request
- New `ProcessedRecording` Codable struct to handle the combined API response
- `ProcessedRecordingView` debug screen to display all processed data (transcript, summary, diagram)
- Navigation flow from recording → processing → debug view
- Server-side `/api/diagram` endpoint integration in combined endpoint

### Changed
- Updated `RecordingProcessor` to use the new combined endpoint, reducing API calls from 3 to 1
- Updated `FunnelAPIService` with new `processAudio()` method for the combined endpoint
- Improved performance by processing transcription, summarization, and diagram generation in parallel on server
- Fixed Makefile build commands to properly handle simulator names with spaces

### Fixed
- Makefile xcodebuild commands now correctly handle "iPhone 16 Pro" simulator name
- Build success/failure detection in Makefile now works properly
- Removed unnecessary grep filters that were causing false build failures

### Technical Details
- Server processes audio in single endpoint with parallel AI operations
- Client makes one network request instead of three separate requests
- Debug view provides scrollable interface for inspecting all processed data

## [0.6.0] - 2025-06-17

### Added
- Server API integration for recording processing pipeline
  - APIClient.swift - Generic networking client with multipart upload support
  - FunnelAPIService.swift - Service layer for Funnel API endpoints
  - APIModels.swift - Codable models matching server types
- Recording data model with SwiftData integration
  - Recording.swift - Full-featured model replacing basic Item model
  - ProcessingStatus enum for tracking upload/processing state
  - Support for transcript, bullet summary, and diagram data
- RecordingProcessor.swift - Orchestrates recording upload and processing flow
- ProcessingView.swift - UI for showing upload/processing progress
- Network permission configuration for local development

### Changed
- AudioRecorderManager now supports completion handlers for recording results
- Updated FunnelRecordingView to automatically process recordings after stopping
- Replaced Item model with comprehensive Recording model in SwiftData
- ContentView now shows processing status after recording
- Added modelContext parameter to FunnelRecordingView

### Technical Details
- Implemented async/await networking with proper error handling
- Added multipart form data support for audio file uploads
- Integrated recording flow: record → save → upload → transcribe → summarize
- Support for both debug (localhost) and production API endpoints
- Added NSAppTransportSecurity settings for local development