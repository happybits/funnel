import SwiftUI

enum GradientTheme: String {
    case defaultTheme
    case orange
    case pinkRed
    case blueTeal

    var colors: [Color] {
        switch self {
        case .defaultTheme:
            return [
                Color(red: 1.0, green: 0.56, blue: 0.0), // Orange #FF8F00
                Color(red: 1.0, green: 0.26, blue: 0.35), // Coral #FF4359
                Color(red: 0.52, green: 0.85, blue: 1.0), // Sky Blue #85D9FF
                Color(red: 1.0, green: 0.77, blue: 0.0), // Golden #FFC400
                Color(red: 0.93, green: 0.33, blue: 0.93), // Pink #ED54ED
                Color(red: 0.41, green: 0.47, blue: 1.0), // Blue #6978FF
            ]
        case .orange:
            return [
                Color(red: 1.0, green: 0.56, blue: 0.0),
                Color(red: 1.0, green: 0.77, blue: 0.0),
                Color(red: 1.0, green: 0.56, blue: 0.0).opacity(0.8),
                Color(red: 1.0, green: 0.77, blue: 0.0).opacity(0.9),
                Color(red: 1.0, green: 0.26, blue: 0.35),
                Color(red: 1.0, green: 0.56, blue: 0.0).opacity(0.7),
            ]
        case .pinkRed:
            return [
                Color(red: 0.93, green: 0.33, blue: 0.93),
                Color(red: 1.0, green: 0.26, blue: 0.35),
                Color(red: 0.93, green: 0.33, blue: 0.93).opacity(0.8),
                Color(red: 1.0, green: 0.26, blue: 0.35).opacity(0.9),
                Color(red: 1.0, green: 0.56, blue: 0.0),
                Color(red: 0.93, green: 0.33, blue: 0.93).opacity(0.7),
            ]
        case .blueTeal:
            return [
                Color(red: 0.41, green: 0.47, blue: 1.0),
                Color(red: 0.52, green: 0.85, blue: 1.0),
                Color(red: 0.41, green: 0.47, blue: 1.0).opacity(0.8),
                Color(red: 0.52, green: 0.85, blue: 1.0).opacity(0.9),
                Color(red: 0.0, green: 0.8, blue: 0.8),
                Color(red: 0.41, green: 0.47, blue: 1.0).opacity(0.7),
            ]
        }
    }
}

class GradientBackgroundManager: ObservableObject {
    @Published var currentTheme: GradientTheme = .defaultTheme
    @Published var targetTheme: GradientTheme = .defaultTheme
    @Published var transitionProgress: Double = 1.0

    private var transitionTimer: Timer?

    func setTheme(_ theme: GradientTheme, animated: Bool = true) {
        guard theme != currentTheme else { return }

        if animated {
            targetTheme = theme
            transitionProgress = 0.0

            transitionTimer?.invalidate()
            transitionTimer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { _ in
                withAnimation(.easeInOut(duration: 0.016)) {
                    self.transitionProgress = min(1.0, self.transitionProgress + 0.033)

                    if self.transitionProgress >= 1.0 {
                        self.currentTheme = self.targetTheme
                        self.transitionTimer?.invalidate()
                        self.transitionTimer = nil
                    }
                }
            }
        } else {
            currentTheme = theme
            targetTheme = theme
            transitionProgress = 1.0
        }
    }

    var interpolatedColors: [Color] {
        if transitionProgress >= 1.0 {
            return currentTheme.colors
        }

        return zip(currentTheme.colors, targetTheme.colors).map { currentColor, targetColor in
            Color(
                red: lerp(currentColor.components.red, targetColor.components.red, transitionProgress),
                green: lerp(currentColor.components.green, targetColor.components.green, transitionProgress),
                blue: lerp(currentColor.components.blue, targetColor.components.blue, transitionProgress)
            )
        }
    }

    private func lerp(_ start: Double, _ end: Double, _ progress: Double) -> Double {
        start + (end - start) * progress
    }
}

// Extension to get color components
extension Color {
    var components: (red: Double, green: Double, blue: Double) {
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        return (Double(red), Double(green), Double(blue))
    }
}

struct GlobalGradientBackground: View {
    @StateObject private var animationState = GradientAnimationState()
    @EnvironmentObject var gradientManager: GradientBackgroundManager

    var body: some View {
        ZStack {
            ForEach(0 ..< 6) { index in
                AnimatedCircle(index: index, animationState: animationState, colors: gradientManager.interpolatedColors)
            }

            // Subtle overlay for depth
            Rectangle()
                .fill(Color.black.opacity(0.15))
        }
        .ignoresSafeArea()
        .onAppear {
            animationState.startAnimation()
        }
    }
}

struct AnimatedCircle: View {
    let index: Int
    @ObservedObject var animationState: GradientAnimationState
    let colors: [Color]

    private var progress: Double {
        (animationState.phase + Double(index) * 0.3).truncatingRemainder(dividingBy: 1.0)
    }

    private var scale: Double {
        1.0 + 0.5 * sin(progress * .pi * 2)
    }

    private var opacity: Double {
        0.6 + 0.4 * sin(progress * .pi * 2 + .pi / 2)
    }

    private var xOffset: Double {
        200 * cos(Double(index) * .pi / 3 + animationState.phase * .pi * 2)
    }

    private var yOffset: Double {
        200 * sin(Double(index) * .pi / 3 + animationState.phase * .pi * 2)
    }

    var body: some View {
        Circle()
            .fill(colors[index])
            .frame(width: 400, height: 400)
            .scaleEffect(scale)
            .opacity(opacity)
            .blur(radius: 60)
            .offset(x: xOffset, y: yOffset)
    }
}

// Keep the existing GradientAnimationState
class GradientAnimationState: ObservableObject {
    @Published var phase: Double = 0
    private var timer: Timer?

    func startAnimation() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            withAnimation(.linear(duration: 0.05)) {
                self.phase = (self.phase + 0.002).truncatingRemainder(dividingBy: 1.0)
            }
        }
    }

    deinit {
        timer?.invalidate()
    }
}
