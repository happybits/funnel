import SwiftUI

struct WaveformView: View {
    @State private var amplitudes: [CGFloat] = Array(repeating: 0.5, count: 50)
    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 2) {
                ForEach(0 ..< amplitudes.count, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.white.opacity(0.8))
                        .frame(width: (geometry.size.width - CGFloat(amplitudes.count - 1) * 2) / CGFloat(amplitudes.count))
                        .frame(height: geometry.size.height * amplitudes[index])
                }
            }
            .frame(maxHeight: .infinity, alignment: .center)
        }
        .onReceive(timer) { _ in
            withAnimation(.easeInOut(duration: 0.1)) {
                for i in 0 ..< amplitudes.count {
                    amplitudes[i] = CGFloat.random(in: 0.1 ... 1.0)
                }
            }
        }
    }
}

struct RecordingView: View {
    let onStop: () -> Void
    @State private var recordingTime: TimeInterval = 0
    let timer = Timer.publish(every: 0.01, on: .main, in: .common).autoconnect()

    var formattedTime: String {
        let minutes = Int(recordingTime) / 60
        let seconds = Int(recordingTime) % 60
        let hundredths = Int((recordingTime.truncatingRemainder(dividingBy: 1)) * 100)
        return String(format: "%02d:%02d.%02d", minutes, seconds, hundredths)
    }

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

                VStack(spacing: 20) {
                    Text("Recording")
                        .font(.custom("NunitoSans-Bold", size: 20))
                        .foregroundColor(.white)

                    Text(formattedTime)
                        .font(.system(size: 24, weight: .regular, design: .monospaced))
                        .foregroundColor(.white.opacity(0.9))

                    WaveformView()
                        .frame(height: 60)
                        .padding(.horizontal, 30)

                    RecordButton(action: onStop, isRecording: .constant(true))
                        .padding(.bottom, 20)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 240)
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
        .onReceive(timer) { _ in
            recordingTime += 0.01
        }
    }
}

#Preview {
    RecordingView(onStop: {})
}
