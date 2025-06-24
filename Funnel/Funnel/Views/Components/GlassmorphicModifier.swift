import SwiftUI

struct VisualEffectBlur: UIViewRepresentable {
    var style: UIBlurEffect.Style

    func makeUIView(context _: Context) -> UIVisualEffectView {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: style))
        view.overrideUserInterfaceStyle = .light
        return view
    }

    func updateUIView(_ uiView: UIVisualEffectView, context _: Context) {
        uiView.effect = UIBlurEffect(style: style)
    }
}

struct GlassmorphicModifier: ViewModifier {
    let cornerRadius: CGFloat
    let shadowRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    VisualEffectBlur(style: .systemUltraThinMaterialLight)

                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: .white.opacity(0.1), location: 0),
                            .init(color: .white.opacity(0.4), location: 1),
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(stops: [
                                .init(color: .white, location: 0),
                                .init(color: .white.opacity(0), location: 0.434),
                                .init(color: .white, location: 1),
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: Color.black.opacity(0.12), radius: shadowRadius, x: 0, y: 4)
            .shadow(color: Color.white.opacity(0.25), radius: 8, x: 0, y: 4)
    }
}

extension View {
    func glassmorphic(cornerRadius: CGFloat = 15, shadowRadius: CGFloat = 12) -> some View {
        modifier(GlassmorphicModifier(cornerRadius: cornerRadius, shadowRadius: shadowRadius))
    }
}

#Preview {
    ZStack {
        GradientBackground()

        VStack {
            Text("Glassmorphic Effect")
                .font(.title)
                .padding()
                .glassmorphic()
        }
    }
}
