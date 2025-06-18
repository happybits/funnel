
import SwiftUI

// Reusable pure blur view without material effects
struct VisualEffectView: UIViewRepresentable {
    var effect: UIVisualEffect?

    func makeUIView(context _: UIViewRepresentableContext<Self>) -> UIVisualEffectView {
        UIVisualEffectView()
    }

    func updateUIView(_ uiView: UIVisualEffectView, context _: UIViewRepresentableContext<Self>) {
        uiView.effect = effect
    }
}

struct GlassmorphicModifier: ViewModifier {
    let cornerRadius: CGFloat
    let gradientOpacity: (start: Double, end: Double)

    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    // Pure backdrop blur without material effects
                    VisualEffectView(effect: UIBlurEffect(style: .regular))
                        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))

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
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white,
                                Color.white.opacity(0),
                                Color.white,
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(color: Color.black.opacity(0.12), radius: 12, x: 0, y: 4)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.white.opacity(0.25), lineWidth: 1)
                    .blur(radius: 1)
                    .offset(y: 2)
                    .mask(RoundedRectangle(cornerRadius: cornerRadius))
            )
    }
}

extension View {
    func glassmorphic(cornerRadius: CGFloat = 15, gradientOpacity: (start: Double, end: Double) = (0.0, 0.3)) -> some View {
        modifier(GlassmorphicModifier(cornerRadius: cornerRadius, gradientOpacity: gradientOpacity))
    }
    
    func glassmorphic(cornerRadius: CGFloat = 15, blurRadius: CGFloat = 10) -> some View {
        modifier(GlassmorphicModifier(cornerRadius: cornerRadius, gradientOpacity: (0.1, 0.4)))
    }
}
