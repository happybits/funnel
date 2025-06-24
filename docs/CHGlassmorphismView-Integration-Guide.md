# CHGlassmorphismView Integration Guide

## Overview
CHGlassmorphismView is a UIKit library that creates glassmorphism effects with a translucent, blurred background. Since it's a UIKit component, we need to wrap it for SwiftUI usage.

## Library API

### Main Class: `CHGlassmorphismView`
A UIView subclass that creates glassmorphism effects.

### Key Methods

1. **Initialization**
   ```swift
   let glassmorphismView = CHGlassmorphismView(frame: CGRect)
   ```

2. **Configure All Properties at Once**
   ```swift
   glassmorphismView.makeGlassmorphismEffect(
       theme: .light,           // or .dark
       density: 0.65,          // 0.0 to 1.0 (blur intensity)
       cornerRadius: 20,       // corner radius in points
       distance: 20            // shadow/distance spread
   )
   ```

3. **Configure Individual Properties**
   ```swift
   glassmorphismView.setTheme(theme: .light)        // .light or .dark
   glassmorphismView.setBlurDensity(with: 0.65)     // 0.0 to 1.0
   glassmorphismView.setCornerRadius(20)            // CGFloat
   glassmorphismView.setDistance(20)                // CGFloat
   ```

### Properties and Defaults
- **Theme**: `.light` (default) or `.dark`
- **Blur Density**: `0.65` (default) - range from 0.0 to 1.0
- **Corner Radius**: `20` (default)
- **Distance**: `20` (default) - affects shadow spread

### Important Notes
- The library uses `UIVisualEffectView` internally for blur effects
- Any views underneath the glassmorphism view are affected by the blur
- Recommended to use `addSubview()` instead of `insertSubview(at: 0)`
- backgroundColor property always returns `.clear`

## SwiftUI Integration

### Basic UIViewRepresentable Wrapper

```swift
import SwiftUI
import CHGlassmorphismView

struct CHGlassmorphismViewWrapper: UIViewRepresentable {
    let theme: CHTheme
    let blurDensity: CGFloat
    let cornerRadius: CGFloat
    let distance: CGFloat
    
    init(
        theme: CHTheme = .light,
        blurDensity: CGFloat = 0.65,
        cornerRadius: CGFloat = 20,
        distance: CGFloat = 20
    ) {
        self.theme = theme
        self.blurDensity = blurDensity
        self.cornerRadius = cornerRadius
        self.distance = distance
    }
    
    func makeUIView(context: Context) -> CHGlassmorphismView {
        let view = CHGlassmorphismView()
        view.makeGlassmorphismEffect(
            theme: theme,
            density: blurDensity,
            cornerRadius: cornerRadius,
            distance: distance
        )
        return view
    }
    
    func updateUIView(_ uiView: CHGlassmorphismView, context: Context) {
        uiView.setTheme(theme: theme)
        uiView.setBlurDensity(with: blurDensity)
        uiView.setCornerRadius(cornerRadius)
        uiView.setDistance(distance)
    }
}
```

### SwiftUI View Modifier

```swift
struct GlassmorphismModifier: ViewModifier {
    let theme: CHTheme
    let blurDensity: CGFloat
    let cornerRadius: CGFloat
    let distance: CGFloat
    
    func body(content: Content) -> some View {
        content
            .background(
                CHGlassmorphismViewWrapper(
                    theme: theme,
                    blurDensity: blurDensity,
                    cornerRadius: cornerRadius,
                    distance: distance
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

extension View {
    func glassmorphism(
        theme: CHTheme = .light,
        blurDensity: CGFloat = 0.65,
        cornerRadius: CGFloat = 20,
        distance: CGFloat = 20
    ) -> some View {
        modifier(GlassmorphismModifier(
            theme: theme,
            blurDensity: blurDensity,
            cornerRadius: cornerRadius,
            distance: distance
        ))
    }
}
```

## Usage Examples

### Basic Usage
```swift
struct ContentView: View {
    var body: some View {
        ZStack {
            // Background content
            Image("background")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea()
            
            // Glassmorphic card
            VStack {
                Text("Glassmorphism")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                
                Text("Beautiful blur effect")
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding()
            .frame(width: 300, height: 200)
            .glassmorphism(
                theme: .light,
                blurDensity: 0.7,
                cornerRadius: 25,
                distance: 15
            )
        }
    }
}
```

### Advanced Usage with State
```swift
struct InteractiveGlassmorphism: View {
    @State private var isDarkTheme = false
    @State private var blurDensity: CGFloat = 0.65
    @State private var cornerRadius: CGFloat = 20
    
    var body: some View {
        VStack(spacing: 20) {
            // Glassmorphic card
            Text("Dynamic Glassmorphism")
                .padding(40)
                .glassmorphism(
                    theme: isDarkTheme ? .dark : .light,
                    blurDensity: blurDensity,
                    cornerRadius: cornerRadius
                )
            
            // Controls
            Toggle("Dark Theme", isOn: $isDarkTheme)
            
            VStack(alignment: .leading) {
                Text("Blur Density: \(blurDensity, specifier: "%.2f")")
                Slider(value: $blurDensity, in: 0...1)
            }
            
            VStack(alignment: .leading) {
                Text("Corner Radius: \(Int(cornerRadius))")
                Slider(value: $cornerRadius, in: 0...50)
            }
        }
        .padding()
    }
}
```

## Comparison with Custom Implementation

Your project already has a custom `LiveBlurView` implementation that captures and blurs content in real-time. Here's a comparison:

### CHGlassmorphismView
- **Pros**: 
  - Simpler to use
  - Optimized for performance
  - Handles theme switching (light/dark)
  - Built-in shadow effects
- **Cons**: 
  - Less control over blur implementation
  - UIKit-based (requires wrapping)
  - May not update as frequently as LiveBlurView

### LiveBlurView (Custom)
- **Pros**: 
  - Real-time blur updates (30 FPS)
  - Full control over blur algorithm
  - Native SwiftUI integration via `LiveGlassmorphicModifier`
  - Can customize gradient overlays
- **Cons**: 
  - More complex implementation
  - Higher performance impact
  - Requires manual theme handling

## Recommendations

1. **Use CHGlassmorphismView when**:
   - You need a simple, static glassmorphism effect
   - Performance is critical
   - You want built-in light/dark theme support

2. **Use LiveBlurView when**:
   - You need real-time blur updates
   - You want fine control over the effect
   - You're animating content behind the blur

3. **Hybrid Approach**:
   - Use CHGlassmorphismView for static UI elements
   - Use LiveBlurView for interactive or animated content

## Integration Steps

1. The library is already added via Swift Package Manager (version 1.0.2)
2. Import the module: `import CHGlassmorphismView`
3. Create the UIViewRepresentable wrapper (shown above)
4. Use the view modifier in your SwiftUI views

## Limitations

- No native SwiftUI support (requires UIViewRepresentable)
- Views underneath are affected by the glassmorphism effect
- Limited to iOS 11.0+
- No direct control over the blur algorithm