import SwiftUI

struct EmptyStateView: View {
    let onRecord: () -> Void

    var body: some View {
        ZStack {
            GradientBackground()

            VStack {
                Spacer()

                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .frame(width: 91, height: 91)
                            .glassmorphic(cornerRadius: 91, shadowRadius: 22.75)
                            .opacity(0.5)

                        Image(systemName: "mic")
                            .font(.system(size: 32))
                            .foregroundColor(.white.opacity(0.8))
                            .shadow(color: .white.opacity(0.4), radius: 9.48, x: 0, y: 7.58)
                            .shadow(color: .black.opacity(0.12), radius: 7.58, x: 0, y: 7.58)
                    }

                    VStack(spacing: 20) {
                        Text("Record You First Message")
                            .font(.custom("NunitoSans-ExtraBold", size: 18))
                            .foregroundColor(.white)
                            .shadow(color: .white, radius: 12, x: 0, y: 4)
                            .shadow(color: .black.opacity(0.12), radius: 20, x: 0, y: 4)

                        Text("Speak your thoughts — we'll turn them into something magical. Tap below to record.")
                            .font(.custom("NunitoSans-Regular", size: 15))
                            .multilineTextAlignment(.center)
                            .lineSpacing(3)
                            .foregroundColor(.white)
                            .shadow(color: .white, radius: 12, x: 0, y: 4)
                            .shadow(color: .black.opacity(0.12), radius: 20, x: 0, y: 4)
                            .frame(maxWidth: 321)
                    }
                }
                .padding(.horizontal, 25)

                Spacer()

                VStack {
                    RecordButton(action: onRecord, isRecording: .constant(false))
                        .padding(.bottom, 61)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 179)
                .background(
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: .white.opacity(0), location: 0),
                            .init(color: .white.opacity(0.3), location: 1),
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .glassmorphic(cornerRadius: 15, shadowRadius: 12)
                    .mask(
                        UnevenRoundedRectangle(
                            topLeadingRadius: 15,
                            bottomLeadingRadius: 0,
                            bottomTrailingRadius: 0,
                            topTrailingRadius: 15
                        )
                    )
                )
            }
            .ignoresSafeArea(edges: .bottom)

            VStack {
                HStack {
                    Image("FunnelLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 30)
                        .shadow(color: .black.opacity(0.12), radius: 10, x: 0, y: 4)
                        .shadow(color: .white.opacity(0.12), radius: 4, x: 0, y: 4)

                    Spacer()
                }
                .padding(.horizontal, 25)
                .padding(.top, 70)

                Spacer()
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    EmptyStateView(onRecord: {})
}
