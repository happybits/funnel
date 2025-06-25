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

### Project Structure
This project uses Xcode's modern folder-based project structure (introduced in Xcode 14+). This means:
- Source files are automatically synchronized with the file system
- No need to manually add/remove files in Xcode
- Cleaner git diffs without .pbxproj conflicts for file additions/removals
- Files in synchronized folders (marked with folder icons in Xcode) are automatically included in the target

### Code Signing
With the folder-based project structure, code signing is configured directly in Xcode:
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

## SwiftUI Performance Tips

### Gesture Recognizers and UI Responsiveness
**AVOID adding gesture recognizers that can interfere with button taps** - Gesture recognizers like `.onTapGesture(count: 3)` add a delay to all tap interactions because the system waits to distinguish between single and multi-tap gestures. This creates a noticeable 350ms delay on button presses. If you need debug functionality, use a dedicated debug button or menu instead of gesture recognizers on the main UI.

### Glassmorphism and Blur Effects
**Performance considerations for live blur effects:**
- **NEVER use CADisplayLink-based blur** - It causes excessive CPU usage, memory leaks, and app crashes
- CADisplayLink fires 60-120 times per second, creating constant view updates that overwhelm the system
- Use UIVisualEffectView wrapped in UIViewRepresentable for performant live blur
- Force light mode on blur views with `overrideUserInterfaceStyle = .light` for consistency
- Use `.systemUltraThinMaterialLight` for minimal frosted glass effect
- Consider making blur optional with a debug toggle for performance testing

**Important iOS limitation**: Creating truly transparent live blur is extremely difficult without UIVisualEffectView, which always includes a frosted/material appearance. If your background is a gradient (not live content), you don't need real blur - the gradient + overlay achieves the glassmorphism effect without performance costs.

**Implementing glassmorphism in SwiftUI:**
```swift
// Use UIVisualEffectView for performance
struct VisualEffectBlur: UIViewRepresentable {
    var style: UIBlurEffect.Style
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: style))
        view.overrideUserInterfaceStyle = .light
        return view
    }
}

// Combine with gradient overlay for glass effect
.background(
    ZStack {
        VisualEffectBlur(style: .systemUltraThinMaterialLight)
        LinearGradient(
            colors: [.white.opacity(0.1), .white.opacity(0.4)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
)
```

**Selective blur application pattern:**
```swift
// Create separate modifiers for performance
extension View {
    // Full glassmorphic effect with blur - use sparingly
    func liveGlassmorphic(...) -> some View { 
        // Includes blur + gradient + shadows
    }
    
    // Gradient-only effect - use for scrollable content
    func liveGlassmorphicCell(...) -> some View {
        // Only gradient + shadows, no blur
    }
}
```

**Debug toggle pattern for performance testing:**
```swift
// Global debug settings
class DebugSettings: ObservableObject {
    @Published var blurEnabled: Bool = true
}

// In your app:
@StateObject private var debugSettings = DebugSettings()

// In your modifier:
if debugSettings.blurEnabled {
    VisualEffectBlur(style: .systemUltraThinMaterialLight)
}