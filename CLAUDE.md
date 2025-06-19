# Funnel - Audio Note Summarizer


## App Concept
A SwiftUI app that captures stream-of-consciousness audio recordings and transforms them into multiple visual representations. Perfect for capturing ideas on-the-go when inspiration strikes.

## Core Features

### Audio Recording
- Simple one-tap recording with AirPods/headphone support
- Background recording capability
- Visual waveform display during recording
- Clean, minimal recording interface

### Multi-Format Output Cards
After recording, view your content in different formats via fullscreen swipeable cards:
- **Bullet Points Card**: Organized summary with key points and action items
- **Napkin Drawing Card**: Visual sketch/diagram representation of concepts
- **Full Transcript Card**: Complete transcription with timestamps
- Additional card formats can be added (mind map, tweet thread, etc.)

### Note Management
- Chronological list of all recordings
- Search functionality across transcripts and summaries
- Tags and categories for organization
- Export options (text, markdown, share sheet)
- Archive and delete functionality

### User Experience
- Minimal, distraction-free interface
- Fullscreen card navigation with smooth transitions
- Siri Shortcuts integration ("Hey Siri, start a voice note")
- Dark mode support
- Haptic feedback for recording start/stop

## Technical Architecture

### iOS App (Swift/SwiftUI)
- AVAudioRecorder for audio capture
- Speech framework for on-device transcription
- SwiftData for local storage
- URLSession for API communication
- Custom card view system with gesture navigation

### Backend (Deno Deploy)
- RESTful API endpoints
- OpenAI Whisper API for audio transcription
- Anthropic Claude API for generating bullet summaries
- Audio file processing and storage

### Data Model
- Recording: audio file, timestamp, duration
- ProcessedContent: transcript, bulletSummary, napkinDrawing, etc.
- Tags: user-defined categories
- Settings: API preferences, audio quality, export formats

## MVP Scope
1. Basic recording interface
2. Upload audio to Deno backend
3. Process audio to generate:
   - Full transcript (via OpenAI Whisper)
   - Bullet point summary (via Anthropic Claude)
4. Display results in swipeable card interface
5. Local storage with SwiftData

## API Design

### Endpoint

**POST /api/new-recording**
- Input: Audio file (multipart/form-data)
- Process: 
  1. Send audio to OpenAI Whisper API for transcription
  2. Send transcript to Anthropic Claude API (in parallel):
     - Generate bullet point summary
     - Generate diagram/visual representation
- Output: 
```json
{
  "transcript": "string",
  "duration": number,
  "bulletSummary": ["string"],
  "diagram": {
    "title": "string",
    "description": "string",
    "content": "string"
  }
}
```

## Future Enhancements
- More card format options (flowchart, outline, etc.)
- Multiple iteration steps to take a "shower thought" to a fleshed-out idea / plan
- Voice commands during recording ("new topic", "important")
- Collaboration features
- Integration with note-taking apps




## Development Setup

### Build Commands
The project includes a Makefile for simplified building and development:

```bash
make build      # Build the app
make clean      # Clean build artifacts and DerivedData
make run        # Build and run on simulator
make format     # Format all Swift code
make quick      # Quick build with minimal output
make help       # Show all available commands
```

Other useful commands:
- `make` or `make all` - Same as `make build`
- `make install` - Installs required tools (swiftformat)
- `make deep-clean` - Removes everything including DerivedData
- `make watch` - Watches for changes and rebuilds automatically
- `make release` - Creates a release build

### Code Signing
With the new Xcode folder-based project structure, code signing is configured directly in Xcode:
1. Open the project in Xcode
2. Select the Funnel target
3. Go to Signing & Capabilities
4. Set your Team ID: `6L379HCV5Q`

The Team ID can be found in Xcode's signing settings or the Apple Developer portal.

### Running the Application

1. **Start the server**:
   ```bash
   cd server
   deno task dev
   ```

2. **Run the iOS app**:
   ```bash
   make run
   ```

### Testing

The server includes comprehensive tests for the API endpoint:

```bash
cd server
deno task test
```

The tests validate:
- Successful audio transcription and processing
- Error handling for missing/invalid files
- Response format and data types
- Real audio file processing using `tests/fixtures/sample-audio-recording.m4a`

For manual testing with curl:
```bash
./test-curl.sh tests/fixtures/sample-audio-recording.m4a
```

## Figma to Code Workflow

The Figma design is here: https://www.figma.com/design/KnkuJhDf5CxBwYt4xZtSEZ/Funnel-Design-File-6-16?node-id=0-1&t=aAnNqwbjqKNHH9At-1

**CRITICAL: When implementing ANY Figma design, you MUST follow the 5-phase
workflow in `/docs/figma-to-code-guide.md`**

### The 5 Mandatory Phases:

1. **Phase 1: Visual Export & Analysis** - Export PNG first, create visual
   inventory
2. **Phase 2: Structure Discovery** - Map node hierarchy
3. **Phase 3: Detailed Data Extraction** - Get measurements, colors, typography
4. **Phase 4: Asset Export** - Export icons/images as SVG/PNG
5. **Phase 5: Code Implementation** - Build with exact measurements

### Golden Rule

**"Export images first, analyze structure second, extract details third."**

### Common Mistakes to Avoid:

- ❌ Jumping straight to node data without visual export
- ❌ Missing UI elements (avatars, status indicators, etc.)
- ❌ Requesting too many nodes at once (token limits)
- ❌ Ignoring opacity values in colors
- ❌ Not comparing final result with original design

### Always Start With:

```typescript
// Step 1 - Export visual first!
mcp__figmastrand__figma_get_images({
  fileKey: "...",
  ids: "...",
  format: "png",
  scale: 2,
});
```

# Important Instruction Reminders
Do what has been asked; nothing more, nothing less.
NEVER create files unless they're absolutely necessary for achieving your goal.
ALWAYS prefer editing an existing file to creating a new one.
NEVER proactively create documentation files (*.md) or README files. Only create documentation files if explicitly requested by the User.
ALWAYS update /docs/CHANGELOG.md when making significant changes to the codebase, including new features, bug fixes, or architectural changes.
**STOP adding SwiftUI materials when matching Figma designs** - If Figma specifies "background blur", implement ONLY blur, NOT .ultraThinMaterial or any material effects. Read the exact Figma properties and implement only those.
**ALWAYS use Assets.xcassets for image resources** - When exporting images from Figma or any other source, add them to Assets.xcassets in Xcode. Do NOT create loose image files in the project directory. This ensures proper asset management, resolution support (@1x, @2x, @3x), and easy reference in SwiftUI.
**USE idiomatic Swift trailing closure syntax** - When a function's last parameter is a closure, use trailing closure syntax. For SwiftUI views with multiple closures like Button, use multiple trailing closures:
```swift
// Good - idiomatic SwiftUI
Button {
    // action here
} label: {
    // content here
}

// Avoid - verbose
Button(action: {
    // action
}, label: {
    // content
})
```
This applies to all SwiftUI views and Swift functions where trailing closures make the code more readable.