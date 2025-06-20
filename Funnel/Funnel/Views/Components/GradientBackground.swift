import SwiftUI

struct GradientBackground: View {
    @State private var animationPhase: Double = 0
    @State private var gradientRotation: Double = 0

    // Base colors from Figma - using exact values
    private let baseColors: [(red: Double, green: Double, blue: Double)] = [
        (0.5764706134796143, 0.6509804129600525, 0.8784313797950745), // Light blue/purple
        (0.40392157435417175, 0.8156862854957581, 0.7960784435272217), // Cyan/turquoise
        (0.9764705896377563, 0.8392156958580017, 0.4588235318660736), // Yellow
        (0.9686274528503418, 0.6980392336845398, 0.4588235318660736), // Orange
        (0.9647058844566345, 0.29411765933036804, 0.2980392277240753), // Red/coral
        (0.8274509906768799, 0.43529412150382996, 0.7490196228027344), // Purple/magenta
    ]

    private let positions: [Double] = [0, 0.2, 0.4, 0.6, 0.8, 1.0]

    private func shiftedColor(baseColor: (red: Double, green: Double, blue: Double), phase: Double) -> Color {
        // Create a breathing effect by shifting brightness and saturation
        let breathingIntensity = sin(phase) * 0.15 // 15% maximum shift for more visibility
        let saturationShift = cos(phase * 0.5) * 0.1 // Subtle saturation wave

        return Color(
            red: min(1, max(0, baseColor.red + breathingIntensity - saturationShift)),
            green: min(1, max(0, baseColor.green + breathingIntensity)),
            blue: min(1, max(0, baseColor.blue + breathingIntensity + saturationShift))
        )
    }

    var body: some View {
        LinearGradient(
            stops: zip(baseColors, positions).map { color, position in
                Gradient.Stop(
                    color: shiftedColor(baseColor: color, phase: animationPhase + position * .pi),
                    location: position
                )
            },
            startPoint: UnitPoint(x: 0.1 + cos(gradientRotation) * 0.1, y: 0),
            endPoint: UnitPoint(x: 0.9 + sin(gradientRotation) * 0.1, y: 1)
        )
        .overlay(Color.black.opacity(0.15))
        .ignoresSafeArea()
        .onAppear {
            // Breathing animation with color shifts
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                animationPhase = .pi * 2
            }

            // Subtle gradient angle rotation for fluid movement
            withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                gradientRotation = .pi * 2
            }
        }
    }
}

#Preview {
    GradientBackground()
}
