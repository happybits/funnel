import SwiftUI

struct BottomDrawerModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            // Background blur effect that blurs content behind (10px radius from Figma)
            // Using .light style for pure blur without dark frostiness
            .background(
                VisualEffectView(effect: UIBlurEffect(style: .regular))
                    .clipShape(
                        UnevenRoundedRectangle(
                            topLeadingRadius: 15,
                            bottomLeadingRadius: 0,
                            bottomTrailingRadius: 0,
                            topTrailingRadius: 15
                        )
                    )
            )
            // Linear gradient fill from Figma: white 0% to 30% opacity
            .background(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.0),
                        Color.white.opacity(0.3),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            // Clip to shape with rounded top corners
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: 15,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: 15
                )
            )
            // Gradient stroke from Figma (OUTSIDE alignment)
            .overlay(
                UnevenRoundedRectangle(
                    topLeadingRadius: 15,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: 15
                )
                .strokeBorder(
                    LinearGradient(
                        stops: [
                            Gradient.Stop(color: Color.white.opacity(1.0), location: 0.0),
                            Gradient.Stop(color: Color.white.opacity(0.0), location: 0.43440794944763184),
                            Gradient.Stop(color: Color.white.opacity(1.0), location: 1.0),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
            )
            // Inner shadow (white 25% opacity, offset y:4, radius:8)
            .overlay(
                UnevenRoundedRectangle(
                    topLeadingRadius: 15,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: 15
                )
                .inset(by: -4)
                .stroke(Color.white.opacity(0.25), lineWidth: 2)
                .blur(radius: 8)
                .offset(y: 4)
                .mask(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 15,
                        bottomLeadingRadius: 0,
                        bottomTrailingRadius: 0,
                        topTrailingRadius: 15
                    )
                    .inset(by: -10)
                )
            )
            // Drop shadow (black 12% opacity, offset y:4, radius:12)
            .shadow(color: Color.black.opacity(0.12), radius: 12, x: 0, y: 4)
    }
}

extension View {
    func bottomDrawerStyle() -> some View {
        modifier(BottomDrawerModifier())
    }
}

#Preview {
    struct PreviewContainer: View {
        var body: some View {
            ZStack {
                // Use the same gradient background as main content view
                GradientBackground()

                VStack {
                    Spacer()

                    // Example drawer content
                    VStack(spacing: 20) {
                        // Handle indicator
                        Capsule()
                            .fill(Color.white.opacity(0.3))
                            .frame(width: 40, height: 5)
                            .padding(.top, 10)

                        Text("Bottom Drawer")
                            .font(.title2)
                            .foregroundColor(.white)

                        Text("This is an example of the bottom drawer style with glassmorphic effects")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        HStack(spacing: 20) {
                            Button("Cancel") {
                                // Action
                            }
                            .buttonStyle(.bordered)
                            .tint(.white)

                            Button("Confirm") {
                                // Action
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.white)
                        }
                        .padding(.bottom, 30)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal)
                    .bottomDrawerStyle()
                }
            }
            .padding(.horizontal)
            .ignoresSafeArea()
        }
    }

    return PreviewContainer()
}
