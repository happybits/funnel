
import SwiftData
import SwiftUI

struct NewRecordingView: View {
    @EnvironmentObject var appState: AppState
    var hideBackground: Bool = false

    var body: some View {
        ZStack {
            if !hideBackground {
                GradientBackground()
            }

            VStack(spacing: 0) {
                // Logo aligned to left
                HStack {
                    FunnelLogo()
                        .padding(.leading, 30)
                    Spacer()
                }
                .padding(.top, 89)

                Spacer()

                VStack(spacing: 20) {
                    MicrophoneButton()

                    Text("Record Your First Message")
                        .funnelFont(.nunitoExtraBold, size: 18)
                        .whiteSandGradientEffect()

                    let speakText = "Speak your thoughts — we'll turn them into something magical."

                    Text(speakText)
                        .funnelFont(.nunitoRegular, size: 15)
                        .whiteSandGradientEffect()
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .padding(.bottom, appState.isRecording ? 156 : 179)

                RecordingControls()
                    .padding(.horizontal, 15)
                    .padding(.bottom, 0)
            }
        }
        .ignoresSafeArea()
    }
}

struct RecordingControls: View {
    @EnvironmentObject var appState: AppState
    @State private var isPressed = false

    var body: some View {
        VStack(spacing: 0) {
            if appState.isRecording {
                // Recording state
                VStack(spacing: 20) {
                    Text("Voice Recording 1")
                        .funnelFont(.nunitoExtraBold, size: 18)
                        .whiteSandGradientEffect()

                    Text(formatTime(appState.recordingTime))
                        .funnelBody()

                    WaveformView(values: appState.waveformValues)
                        .frame(height: 37)
                        .padding(.horizontal, 25)
                }
                .padding(.top, 30)

                Spacer()

                StopButton(isPressed: $isPressed) {
                    appState.stopRecording()
                }
                .padding(.bottom, 46)
            } else {
                // Not recording state
                RecordButton(isPressed: $isPressed) {
                    appState.startRecording()
                }
                .padding(.top, 15)
                .padding(.bottom, 61)
            }
        }
        .frame(width: 372, height: appState.isRecording ? 350 : 179)
        .glassmorphic(
            cornerRadius: 15,
            gradientOpacity: appState.isRecording ? (0.1, 0.4) : (0.0, 0.3)
        )
        .animation(.easeInOut(duration: 0.3), value: appState.isRecording)
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        let centiseconds = Int((time.truncatingRemainder(dividingBy: 1)) * 100)
        return String(format: "%02d:%02d.%02d", minutes, seconds, centiseconds)
    }
}

struct FunnelLogo: View {
    var body: some View {
        Image("FunnelLogo")
    }
}

struct MicrophoneButton: View {
    var body: some View {
        Image("MicHero")
    }
}

struct RecordButton: View {
    @Binding var isPressed: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Image("RecordBtn")
                .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

struct StopButton: View {
    @Binding var isPressed: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Image("StopRecordBtn")
                .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

struct WaveformView: View {
    let values: [CGFloat]

    var body: some View {
        HStack(spacing: 2) {
            ForEach(Array(values.enumerated()), id: \.offset) { _, value in
                RoundedRectangle(cornerRadius: 2)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.7),
                                Color.white.opacity(0.9),
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 4, height: 37 * value)
                    .animation(.easeInOut(duration: 0.1), value: value)
            }

            if values.count < 50 {
                ForEach(0 ..< (50 - values.count), id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 4, height: 8)
                }
            }
        }
    }
}

#Preview {
    NewRecordingView()
        .funnelPreviewEnvironment()
        .environmentObject(AppState(modelContext: ModelContainer.previewContainer.mainContext))
}
