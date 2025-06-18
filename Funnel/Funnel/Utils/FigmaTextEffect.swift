import SwiftUI

// Custom text effect modifier that matches the Figma design
struct WhiteSandGradientEffect: ViewModifier {
    func body(content: Content) -> some View {
        content
            .foregroundStyle(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.1),
                        Color.white.opacity(0.4)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                content
                    .foregroundColor(.white.opacity(0.9))
                    .blendMode(.overlay)
            )
            .shadow(color: .black.opacity(0.12), radius: 20, x: 0, y: 4)
    }
}

extension View {
    func whiteSandGradientEffect() -> some View {
        modifier(WhiteSandGradientEffect())
    }
}
