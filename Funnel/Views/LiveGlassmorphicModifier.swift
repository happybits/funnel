import SwiftUI
import UIKit

struct VisualEffectBlur: UIViewRepresentable {
    var style: UIBlurEffect.Style
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: style))
        // Force light mode appearance
        view.overrideUserInterfaceStyle = .light
        return view
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
        uiView.overrideUserInterfaceStyle = .light
    }
}

struct LiveGlassmorphicModifier: ViewModifier {
    @EnvironmentObject var debugSettings: DebugSettings
    
    let cornerRadius: CGFloat
    let blurRadius: CGFloat
    let gradientOpacity: (start: Double, end: Double)

    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    if debugSettings.blurEnabled {
                        // Use UIVisualEffectView for better performance
                        // .systemUltraThinMaterialLight provides minimal frosting with good blur
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
            .shadow(color: Color.black.opacity(0.12), radius: 12, x: 0, y: 4)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.white.opacity(0.25), lineWidth: 1)
                    .blur(radius: 1)
                    .offset(y: 2)
                    .mask(RoundedRectangle(cornerRadius: cornerRadius))
            )
    }
}

struct LiveGlassmorphicCellModifier: ViewModifier {
    let cornerRadius: CGFloat
    let gradientOpacity: (start: Double, end: Double)

    func body(content: Content) -> some View {
        content
            .background(
                // Gradient overlay only, no blur
                LinearGradient(
                    colors: [
                        Color.white.opacity(gradientOpacity.start),
                        Color.white.opacity(gradientOpacity.end),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
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
            .shadow(color: Color.black.opacity(0.12), radius: 12, x: 0, y: 4)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
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
    func liveGlassmorphic(
        cornerRadius: CGFloat = 15,
        blurRadius: CGFloat = 10,
        gradientOpacity: (start: Double, end: Double) = (0.1, 0.4)
    ) -> some View {
        modifier(LiveGlassmorphicModifier(
            cornerRadius: cornerRadius,
            blurRadius: blurRadius,
            gradientOpacity: gradientOpacity
        ))
    }
    
    func liveGlassmorphicCell(
        cornerRadius: CGFloat = 15,
        gradientOpacity: (start: Double, end: Double) = (0.1, 0.4)
    ) -> some View {
        modifier(LiveGlassmorphicCellModifier(
            cornerRadius: cornerRadius,
            gradientOpacity: gradientOpacity
        ))
    }
}
