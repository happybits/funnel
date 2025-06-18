# SwiftUI Layout Best Practices

This document captures learnings from real-world SwiftUI development to help create cleaner, more maintainable layouts.

## Key Principles

1. **Break complex views into private computed properties** - Keep your `body` focused on layout structure
2. **Prefer overlay/background modifiers over ZStack** - More precise positioning without Spacer complexity  
3. **Avoid GeometryReader unless necessary** - Often leads to layout issues; use frame modifiers instead

## 1. Prefer Overlay Modifiers Over ZStack for Positioned Elements

### ❌ Avoid: Using ZStack with Spacers
```swift
var body: some View {
    ZStack {
        BackgroundView()
        
        VStack {
            HStack {
                Logo()
                Spacer()
            }
            .padding(.top, 89)
            
            Spacer()
            
            ContentBox()
            
            Spacer()
        }
    }
}
```

### ✅ Prefer: Using Overlay with Alignment
```swift
var body: some View {
    BackgroundView()
        .overlay(alignment: .topLeading) {
            Logo()
                .padding(.leading, 30)
                .padding(.top, 89)
        }
        .overlay {
            ContentBox()
        }
}
```

**Why:** Overlay modifiers provide more precise positioning without the complexity of Spacers. They're also more declarative about intent.

## 2. Extract Complex Views into Computed Properties

### ❌ Avoid: Everything in One Body
```swift
var body: some View {
    VStack {
        // 50+ lines of nested views...
    }
}
```

### ✅ Prefer: Decomposed Views
```swift
struct ProcessingView: View {
    private var logo: some View {
        HStack {
            FunnelLogo()
                .padding(.leading, 30)
                .padding(.top, 89)
            Spacer()
        }
    }
    
    private var processingBox: some View {
        VStack(spacing: 8) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
            
            Text("Processing - Hang tight!")
                .funnelTitle()
            // Additional UI elements...
        }
        .frame(maxWidth: 350)
        .glassmorphic()
    }
    
    var body: some View {
        GradientBackground()
            .overlay(alignment: .topLeading) {
                logo
            }
            .overlay {
                processingBox
            }
            .ignoresSafeArea()
    }
}
```

**Why:** Breaking complex views into private computed properties makes the main `body` easy to understand at a glance - it clearly shows the overall layout structure. The individual components are separated, making them easier to modify, test, and reason about. This pattern is especially valuable when views have multiple distinct sections or complex nested structures.

## 3. Use Appropriate Spacing Values

### ❌ Avoid: Arbitrary Large Spacing
```swift
VStack(spacing: 30) {
    Text("Title")
    Text("Subtitle")
}
```

### ✅ Prefer: Intentional, Smaller Spacing
```swift
VStack(spacing: 8) {
    Text("Title")
    Text("Subtitle")
}
```

**Why:** Tighter spacing often looks more cohesive. Use padding for larger gaps when needed.

## 4. Apply DRY Principle to Text Content

### ❌ Avoid: Duplicating Strings
```swift
Text("Processing Your Recording")
    .modifier(CustomStyle())
    .overlay(Text("Processing Your Recording")
        .modifier(OverlayStyle()))
```

### ✅ Prefer: Store in Constants
```swift
let message = "Processing - Hang tight!"
Text(message)
    .modifier(CustomStyle())
    .overlay(Text(message)
        .modifier(OverlayStyle()))
```

**Why:** Reduces typos and makes updates easier.

## 5. Place Modifiers on the Most Specific View

### ❌ Avoid: Padding on Container
```swift
VStack {
    Logo()
}
.padding(.top, 89)
```

### ✅ Prefer: Padding on Element
```swift
Logo()
    .padding(.top, 89)
```

**Why:** More precise control and clearer intent.

## 6. Simplify Information Hierarchy

### ❌ Avoid: Too Many Dynamic Elements
```swift
VStack {
    Text(title)
    Text(subtitle)
    Text(dynamicStatus)
    Text(additionalInfo)
}
```

### ✅ Prefer: Essential Information Only
```swift
VStack {
    Text(title)
    if showingError {
        Text(errorMessage)
    }
}
```

**Why:** Less cognitive load for users, cleaner interface.

## 7. Use Frame Constraints Wisely

### ✅ Good: Max Width for Content Boxes
```swift
ContentView()
    .frame(maxWidth: 350)
    .glassmorphic()
```

**Why:** Prevents content from stretching too wide on larger screens while remaining flexible.

## Summary Checklist

When reviewing SwiftUI layouts, ask yourself:

- [ ] Can I replace any ZStack + Spacer combinations with overlay/background modifiers?
- [ ] Should complex views be broken into private computed properties?
- [ ] Can I avoid GeometryReader by using frame modifiers or other techniques?
- [ ] Are there logical groupings I can extract into computed properties?
- [ ] Is my spacing intentional and consistent?
- [ ] Have I avoided string duplication?
- [ ] Are modifiers applied to the most specific views?
- [ ] Is all displayed information essential?
- [ ] Do I have appropriate frame constraints?

Remember: The best SwiftUI code reads like a description of what you want, not instructions for how to build it. A clean `body` property that clearly shows the layout structure is a sign of well-organized SwiftUI code.