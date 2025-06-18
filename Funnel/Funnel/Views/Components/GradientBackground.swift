//
//  GradientBackground.swift
//  Funnel
//
//  Created by Joel Drotleff on 6/16/25.
//

import SwiftUI

struct GradientBackground: View {
    @State private var animationPhase: Double = 0
    @State private var colorShift: Double = 0
    
    private let baseColors: [Color] = [
        Color(red: 0.98, green: 0.78, blue: 0.82),  // Soft pink
        Color(red: 0.95, green: 0.80, blue: 0.88),  // Light lavender
        Color(red: 0.88, green: 0.85, blue: 0.98),  // Soft purple
        Color(red: 0.82, green: 0.88, blue: 0.98),  // Light blue
        Color(red: 0.80, green: 0.92, blue: 0.95),  // Soft cyan
        Color(red: 0.82, green: 0.95, blue: 0.88),  // Light mint
        Color(red: 0.90, green: 0.95, blue: 0.82),  // Soft lime
        Color(red: 0.98, green: 0.92, blue: 0.82),  // Light peach
        Color(red: 0.98, green: 0.85, blue: 0.80),  // Soft coral
    ]
    
    private func shiftedColors(offset: Double) -> [Color] {
        let count = baseColors.count
        let shift = Int(offset * Double(count)) % count
        
        var shifted = baseColors
        for _ in 0..<shift {
            shifted.append(shifted.removeFirst())
        }
        
        // Blend between adjacent colors for smooth transitions
        let fraction = (offset * Double(count)).truncatingRemainder(dividingBy: 1.0)
        if fraction > 0 {
            shifted = shifted.enumerated().map { index, color in
                let nextIndex = (index + 1) % shifted.count
                return Color(
                    red: color.red * (1 - fraction) + shifted[nextIndex].red * fraction,
                    green: color.green * (1 - fraction) + shifted[nextIndex].green * fraction,
                    blue: color.blue * (1 - fraction) + shifted[nextIndex].blue * fraction
                )
            }
        }
        
        return shifted
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Base gradient layer
                LinearGradient(
                    colors: shiftedColors(offset: colorShift),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                // Animated overlay gradients for lava lamp effect
                ForEach(0..<3) { index in
                    RadialGradient(
                        colors: [
                            shiftedColors(offset: colorShift + Double(index) * 0.3)[index * 3 % baseColors.count].opacity(0.6),
                            Color.clear
                        ],
                        center: UnitPoint(
                            x: 0.5 + 0.3 * cos(animationPhase + Double(index) * .pi * 0.7),
                            y: 0.5 + 0.3 * sin(animationPhase * 0.8 + Double(index) * .pi * 0.5)
                        ),
                        startRadius: geometry.size.width * 0.1,
                        endRadius: geometry.size.width * 0.8
                    )
                    .blendMode(.overlay)
                }
                
                // Subtle noise overlay for texture
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.05),
                        Color.clear,
                        Color.white.opacity(0.03)
                    ],
                    startPoint: UnitPoint(
                        x: 0.5 + 0.2 * cos(animationPhase * 1.2),
                        y: 0
                    ),
                    endPoint: UnitPoint(
                        x: 0.5 + 0.2 * sin(animationPhase * 0.9),
                        y: 1
                    )
                )
                .blendMode(.overlay)
            }
            .ignoresSafeArea()
        }
        .onAppear {
            withAnimation(.linear(duration: 30).repeatForever(autoreverses: false)) {
                animationPhase = .pi * 2
            }
            withAnimation(.linear(duration: 45).repeatForever(autoreverses: false)) {
                colorShift = 1.0
            }
        }
    }
}

// Color extension for component access
extension Color {
    var red: Double {
        let uiColor = UIColor(self)
        var r: CGFloat = 0
        uiColor.getRed(&r, green: nil, blue: nil, alpha: nil)
        return Double(r)
    }
    
    var green: Double {
        let uiColor = UIColor(self)
        var g: CGFloat = 0
        uiColor.getRed(nil, green: &g, blue: nil, alpha: nil)
        return Double(g)
    }
    
    var blue: Double {
        let uiColor = UIColor(self)
        var b: CGFloat = 0
        uiColor.getRed(nil, green: nil, blue: &b, alpha: nil)
        return Double(b)
    }
}

#Preview {
    GradientBackground()
}
