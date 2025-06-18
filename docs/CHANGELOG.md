# Changelog

All notable changes to the Funnel project will be documented in this file.

## [Unreleased]

### Enhanced
- **Gradient Background Animation**: Added breathing effect to gradient background
  - Increased color shift intensity from 5% to 15% for better visibility
  - Added subtle saturation wave effect using cosine function
  - Implemented gradient angle rotation for fluid movement
  - Adjusted animation durations: 6s for color breathing, 8s for rotation

### Changed
- **Updated APIClient to use production server**: Default URL now points to https://funnel-api.deno.dev
- **Added server toggle**: Added `useLocalServer` boolean flag in APIClient for easy switching between local development and production servers
- **Removed Xcode file headers**: Cleaned up all Swift files by removing standard Xcode-generated headers (file name, project name, creation date) to reduce clutter and improve code readability

### Added
- **Deployed server to Deno Deploy**: Production deployment at https://funnel-api.deno.dev
  - Created new project "funnel-api" on Deno Deploy
  - Configured deployment settings in deno.deploy.json
  - Added deployment configuration to deno.json
  - Environment variables need to be configured in Deno Deploy dashboard:
    - OPENAI_API_KEY - Required for audio transcription
    - ANTHROPIC_API_KEY - Required for content generation
    - CORS_ORIGIN - Optional, defaults to "*"
    - PORT - Automatically set by Deno Deploy
- **Bottom Drawer Component**: Created reusable `BottomDrawerModifier` matching Figma design
  - Found in Figma file as "Bottom Drawer" component (node ID: 67:356)
  - Glassmorphic style with rounded top corners only (15px radius)
  - Gradient background (white 0% to 30% opacity)
  - Complex gradient stroke with opacity variations
  - Multiple drawer variations found across different screens

### Changed
- **Updated Bottom Drawer UI**: Matched Figma design specifications exactly
  - Created custom `BottomDrawerModifier` with proper blur effect (radius 10)
  - Updated gradient background to match Figma (0.1 to 0.4 opacity)
  - Fixed corner radius to only round top corners (15px)
  - Added proper shadows: drop shadow (black 12%, offset y:4, radius:12) and inner shadow (white 25%, offset y:4, radius:8)
  - Updated gradient stroke with varying opacity
  - Changed title text from "Voice Recording 1" to "Adding Context" during recording
  - Updated fonts to use correct Nunito font family names
  - Fixed waveform bars to 2px width with 10px corner radius and proper shadows
  - Created custom stop button matching Figma design with gradient background and red square

### Fixed
- Recording functionality now properly handles completion callbacks
- Added minimum recording duration check (0.5s) to prevent API errors
- Fixed CurrentRecordingProvider type casting for SwiftUI previews
- Fixed ProcessingView UI not updating after successful API response
- Added file location logging for recorded audio files
- Reverted AudioRecorderManager from async/await to callback-based approach for simplicity
- Fixed server tests for updated API types

## [0.10.0] - 2025-06-17

### Changed
- **Major State Management Refactoring**: Implemented centralized state management
  - Created `AppState` class as single source of truth for all app state
  - Consolidated recording, processing, and navigation state management
  - Replaced multiple `@StateObject` instances with single `AppState` environment object
  - Simplified navigation using enum-based `NavigationState` (.recording, .processing, .viewing)

### Added
- **AppState.swift**: Centralized state management class that combines:
  - Recording functionality from `CurrentRecordingProvider`
  - Processing functionality from `RecordingProcessor`
  - Navigation state management
  - Error handling and retry logic

### Removed
- Removed `ProcessedRecording` struct (now using `Recording` model directly)
- Removed duplicate `RecordingProcessor` instances in views
- Removed complex state management from `ContentView`
- Removed initialization workarounds for `ModelContext`

### Fixed
- Fixed state synchronization issues between recording and processing
- Fixed multiple instances of state objects causing inconsistencies
- Fixed navigation flow with cleaner state-based transitions
- Fixed Equatable conformance for NavigationState enum
- Fixed main actor isolation warnings in timer callbacks

### Technical Details
- All state management now flows through single `AppState` instance
- Views no longer create their own state objects
- Navigation is handled via state changes rather than boolean flags
- Improved error handling with user-friendly error states
- Better separation of concerns between views and state management

## [0.1.0] - 2025-06-16

### Added
- Initial iOS app structure with SwiftUI and SwiftData
- Gradient background component with vibrant colors matching Figma design
- Glassmorphic UI modifier for frosted glass effects
- FunnelEmptyView - empty state with microphone icon and record button
- FunnelRecordingView - recording state with animated waveform visualization
- Custom Nunito fonts (Black, BlackItalic) and Nunito Sans fonts (Regular, ExtraBold)
- XcodeGen configuration for project file generation
- Makefile for automated building and project generation
- .gitignore for Xcode and generated files

### Technical Details
- Implemented glassmorphic effects with gradient overlays and backdrop blur
- Created reusable components for consistent UI styling
- Added real-time waveform animation during recording
- Integrated custom fonts from Google Fonts
- Set up XcodeGen for declarative project management

## [0.2.0] - 2025-06-16

### Added
- Deno backend server with RESTful API
- POST /api/transcribe endpoint for audio transcription using OpenAI Whisper
- POST /api/summarize endpoint for generating bullet summaries using Anthropic Claude
- Environment configuration with .env support
- Comprehensive error handling and validation
- CORS support for cross-origin requests
- Health check endpoint at root path
- Deno Deploy configuration for easy deployment
- File type validation (mp3, mp4, wav, m4a) with 25MB size limit
- Transcript length validation (50k character limit)

### Technical Details
- Built with Hono framework for fast HTTP routing
- Modular architecture with separate lib/ and api/ directories
- TypeScript types for all API requests and responses
- Automatic formatting and linting with deno tasks
- Production-ready with proper logging and error handling

## [0.3.0] - 2025-06-16

### Changed
- Updated UI to match Figma design exactly
- Replaced placeholder logo and record button with SVG exports from Figma
- Fixed font names to use correct font family identifiers (NunitoSans-Regular, NunitoSans-ExtraBold)
- Updated gradient background to use exact image from Figma design
- Fixed typo "Record You First Message" to "Record Your First Message"
- Added new text styling extensions for consistent Figma-matching text effects

### Added
- SVG assets for logo and record button exported from Figma
- Background gradient image asset from Figma
- Text styling modifiers with proper shadows and overlays to match design

## [0.4.0] - 2025-06-16

### Added
- Font management utility with type-safe font names and modifiers
- FontExtensions.swift with comprehensive font handling
- Debug font view for troubleshooting font loading issues
- Makefile for simplified build commands and automation
- Support for all Nunito font weights and variants (16 fonts total)
- Custom text style modifiers (funnelTitle, funnelBody, funnelSmall)
- Font logging on app launch for debugging

### Changed
- Replaced NunitoSans fonts with complete Nunito font family
- Updated all font references throughout the app
- Fixed Info.plist font registration using XcodeGen info section
- Improved project.yml structure for proper font inclusion

### Fixed
- Custom fonts not displaying correctly in iOS app
- Info.plist UIAppFonts array generation with XcodeGen
- Font name mismatches between code and actual font files

### Technical Details
- Created FontExtensions.swift with FunnelFont enum for type safety
- Added convenience modifiers for common text styles
- Implemented proper Info.plist generation for font registration
- Added comprehensive Makefile with build, clean, format, and release targets

## [0.5.0] - 2025-06-16

### Added
- Exported 4 SVG assets from Figma design based on user comments
  - FunnelLogo.svg - Logo with "Funnel" text and plus icon
  - MicrophoneHero.svg - Microphone icon for empty state
  - RecordButton.svg - Red circular record button
  - StopButton.svg - Red square stop button
- Created new imagesets in Assets.xcassets for MicrophoneHero and StopButton
- Modified all SVG files to use percentage-based dimensions (width="100%" height="100%") for proper macOS Quick Look preview

### Changed
- Updated existing FunnelLogo and RecordButton assets with new Figma exports
- All SVG assets now use viewBox with percentage dimensions for better scalability

### Technical Details
- Used Figma MCP tool to extract assets from specific nodes
- Applied SVG optimization for macOS Quick Look compatibility
- Maintained vector format with preserves-vector-representation in imagesets

## [0.6.0] - 2025-06-17

### Added
- Complete network layer implementation for iOS app
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