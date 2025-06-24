# Glassmorphism Implementation Guide

This guide explains the custom glassmorphism implementation in the Funnel app, including performance considerations and best practices.

## Overview

Glassmorphism is a design trend that creates a frosted glass effect with:
- Background blur
- Semi-transparent gradient overlay
- Subtle borders and shadows
- Light refraction effects

## Performance Challenges

### ❌ What NOT to Do: CADisplayLink

Our initial attempt used CADisplayLink to capture live content:

```swift
// DON'T DO THIS!
class LiveBlurViewModel: ObservableObject {
    private var displayLink: CADisplayLink?
    @Published var currentImage: UIImage?
    
    func startCapturing() {
        displayLink = CADisplayLink(target: self, selector: #selector(updateFrame))
        displayLink?.add(to: .current, forMode: .common)
    }
}
```

**Why this fails:**
- CADisplayLink fires 60-120 times per second
- Each frame captures the entire view hierarchy
- Causes excessive CPU usage and memory allocation
- Results in app freezes and crashes

### ✅ The Solution: UIVisualEffectView

UIVisualEffectView is Apple's optimized solution for blur effects:

```swift
struct VisualEffectBlur: UIViewRepresentable {
    var style: UIBlurEffect.Style
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: style))
        view.overrideUserInterfaceStyle = .light // Force light mode
        return view
    }
}
```

**Benefits:**
- Hardware-accelerated blur
- Efficient real-time updates
- Minimal CPU/GPU usage
- Native iOS look and feel

## Implementation Architecture

### 1. Base Blur View

The `LiveBlurView` wraps UIVisualEffectView for SwiftUI:

```swift
struct LiveBlurView: View {
    let blurRadius: CGFloat
    
    var body: some View {
        VisualEffectBlur(style: .systemUltraThinMaterialLight)
            .edgesIgnoringSafeArea(.all)
    }
}
```

### 2. Full Glassmorphic Modifier

For UI elements that need the full effect (like recording controls):

```swift
struct LiveGlassmorphicModifier: ViewModifier {
    @EnvironmentObject var debugSettings: DebugSettings
    let cornerRadius: CGFloat
    let gradientOpacity: (start: Double, end: Double)
    
    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    // Conditional blur based on debug settings
                    if debugSettings.blurEnabled {
                        VisualEffectBlur(style: .systemUltraThinMaterialLight)
                            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                    }
                    
                    // Gradient overlay
                    LinearGradient(
                        colors: [
                            Color.white.opacity(gradientOpacity.start),
                            Color.white.opacity(gradientOpacity.end),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
            )
            .overlay(/* borders */)
            .shadow(/* shadows */)
    }
}
```

### 3. Performance-Optimized Cell Modifier

For scrollable content where blur would impact performance:

```swift
struct LiveGlassmorphicCellModifier: ViewModifier {
    // Same as above but WITHOUT the blur layer
    // Only includes gradient, borders, and shadows
}
```

## Usage Patterns

### When to Use Full Glassmorphism

Use `.liveGlassmorphic()` for:
- Static UI elements
- Recording controls
- Modal overlays
- Elements that don't scroll

```swift
RecordButton()
    .liveGlassmorphic(
        cornerRadius: 40,
        blurRadius: 10,
        gradientOpacity: (0.1, 0.4)
    )
```

### When to Use Cell Glassmorphism

Use `.liveGlassmorphicCell()` for:
- List items
- Scrollable cards
- Any content in ScrollView
- Performance-critical areas

```swift
ForEach(recordings) { recording in
    RecordingCell(recording: recording)
        .liveGlassmorphicCell(
            cornerRadius: 15,
            gradientOpacity: (0.1, 0.3)
        )
}
```

## Debug Mode

The implementation includes a debug toggle for A/B testing performance:

```swift
// In FunnelApp.swift
@StateObject private var debugSettings = DebugSettings()

// Pass to environment
.environmentObject(debugSettings)

// Toggle in UI (commented out for production)
Toggle("Blur", isOn: $debugSettings.blurEnabled)
```

## Performance Tips

1. **Minimize Blur Usage**: Only apply blur where it adds significant visual value
2. **Avoid Nested Blurs**: Don't stack multiple blur effects
3. **Use Appropriate Blur Styles**: `.systemUltraThinMaterialLight` has the best performance
4. **Test on Real Devices**: Simulator performance doesn't reflect real-world usage
5. **Profile with Instruments**: Monitor CPU and GPU usage when implementing blur

## Important Limitation: Live Blur on iOS

**Creating truly transparent live blur on iOS is extremely difficult** without using UIVisualEffectView, which always includes a frosted glass appearance. There's no native way to achieve pure blur without the material effect.

**Key insight**: If your background is a gradient (not dynamic content like photos or videos), you don't actually need live blur. The gradient + semi-transparent overlay achieves the glassmorphism look without the performance cost of real-time blur. This is why our `liveGlassmorphicCell` modifier works well - it relies on the gradient background rather than trying to blur dynamic content.

## Figma to Code Translation

When implementing Figma designs with glassmorphism:

1. **Background Blur**: Figma's "Background Blur" → `VisualEffectBlur`
2. **Fill Opacity**: Figma's fill → `LinearGradient` with opacity
3. **Effects**: Figma's effects → SwiftUI shadows and overlays
4. **Layer Styles**: Combine all effects in a single ViewModifier

## Troubleshooting

### Blur Not Showing
- Check that `debugSettings.blurEnabled` is true
- Ensure the view has content behind it to blur
- Verify the blur radius is > 0

### Performance Issues
- Switch to `.liveGlassmorphicCell()` for scrollable content
- Reduce the number of blurred elements
- Consider using static blur (non-live) for some elements

### Visual Artifacts
- Force light mode with `overrideUserInterfaceStyle = .light`
- Ensure proper clipping with `clipShape()`
- Check that shadows are applied in the correct order