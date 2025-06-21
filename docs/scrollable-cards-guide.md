# Scrollable Cards with Peek Effect Guide

This guide explains how to implement a horizontal scrollable card view where adjacent cards peek from the sides and the selected card is always centered.

## Key Concepts

### 1. Card Width Calculation
```swift
let cardWidth = geometry.size.width - 60 // Full width minus padding on each side
```
- Cards should be slightly narrower than the screen to show adjacent cards
- Common pattern: `screenWidth - (2 * peekAmount)`
- Example: For 30px peek on each side, use `width - 60`

### 2. ScrollView Setup
```swift
ScrollView(.horizontal, showsIndicators: false) {
    HStack(spacing: 15) {
        // Your cards here
    }
    .scrollTargetLayout()
}
.contentMargins(.horizontal, 30, for: .scrollContent)
.scrollTargetBehavior(.viewAligned)
.scrollPosition(id: $scrolledID)
```

### 3. Critical Components

#### `.scrollTargetLayout()`
- Must be applied to the HStack containing your cards
- Tells SwiftUI which views are the scroll targets

#### `.contentMargins(.horizontal, value, for: .scrollContent)`
- Adds padding to the scroll content area
- This is what makes cards center properly
- Use the same value as your peek amount (e.g., 30)

#### `.scrollTargetBehavior(.viewAligned)`
- Enables snapping behavior
- Cards will snap to aligned positions when scrolling stops

#### `.scrollPosition(id: $binding)`
- Tracks which card is currently centered
- Useful for updating UI based on selected card

## Complete Example

```swift
struct ScrollableCardsView: View {
    @State private var selectedCard: Int? = 0
    
    var body: some View {
        GeometryReader { geometry in
            let cardWidth = geometry.size.width - 60 // 30px peek on each side
            
            ScrollViewReader { scrollProxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {
                        ForEach(0..<5) { index in
                            CardView(index: index)
                                .frame(width: cardWidth)
                                .id(index)
                        }
                    }
                    .scrollTargetLayout()
                }
                .contentMargins(.horizontal, 30, for: .scrollContent)
                .scrollTargetBehavior(.viewAligned)
                .scrollPosition(id: $selectedCard)
                .onAppear {
                    // Optional: Scroll to a specific card on appear
                    scrollProxy.scrollTo(selectedCard, anchor: .center)
                }
            }
        }
    }
}
```

## Common Pitfalls to Avoid

### ❌ Don't use spacer views
```swift
// Bad - Don't do this
HStack(spacing: 15) {
    Spacer().frame(width: 30)
    CardView()
    Spacer().frame(width: 30)
}
```

### ❌ Don't use padding on ScrollView
```swift
// Bad - This won't center cards properly
ScrollView(.horizontal) {
    // content
}
.padding(.horizontal, 30)
```

### ✅ Do use contentMargins
```swift
// Good - This properly centers cards
ScrollView(.horizontal) {
    // content
}
.contentMargins(.horizontal, 30, for: .scrollContent)
```

## Customization Options

### Different Peek Amounts
```swift
let peekAmount: CGFloat = 40
let cardWidth = geometry.size.width - (2 * peekAmount)
// ...
.contentMargins(.horizontal, peekAmount, for: .scrollContent)
```

### Variable Card Spacing
```swift
HStack(spacing: 20) { // Adjust spacing between cards
    // cards
}
```

### Page Indicators
```swift
// Below your ScrollView
HStack(spacing: 8) {
    ForEach(0..<cardCount) { index in
        Circle()
            .fill(selectedCard == index ? Color.primary : Color.gray)
            .frame(width: 8, height: 8)
    }
}
```

## Animation Tips

1. **Smooth Gradient Transitions**
   ```swift
   .animation(.easeInOut(duration: 0.3), value: selectedCard)
   ```

2. **Scale Effect for Selected Card**
   ```swift
   CardView()
       .scaleEffect(selectedCard == index ? 1.0 : 0.95)
       .animation(.spring(), value: selectedCard)
   ```

3. **Opacity for Non-Selected Cards**
   ```swift
   CardView()
       .opacity(selectedCard == index ? 1.0 : 0.8)
   ```

## Performance Considerations

- Use `.id()` on each card for efficient updates
- Consider lazy loading for large numbers of cards
- Limit complex animations to avoid janky scrolling
- Test on older devices to ensure smooth performance

## Summary

The key to perfect scrollable cards with peek effect is:
1. Calculate card width as `screenWidth - (2 * peekAmount)`
2. Use `.contentMargins()` instead of spacers or padding
3. Apply `.scrollTargetLayout()` to your HStack
4. Enable `.scrollTargetBehavior(.viewAligned)` for snapping
5. Track position with `.scrollPosition(id:)`

This approach ensures cards are properly centered, snap correctly, and show the desired peek amount on both sides.