//
//  NewRecordingView.swift
//  Funnel
//
//  Created by Claude on 6/17/25.
//

import SwiftData
import SwiftUI

struct NewRecordingView: View {
    @EnvironmentObject var currentRecording: CurrentRecordingProvider
    @StateObject private var recordingProcessor: RecordingProcessor
    let modelContext: ModelContext
    let onRecordingComplete: () -> Void

    init(modelContext: ModelContext, onRecordingComplete: @escaping () -> Void) {
        self.modelContext = modelContext
        self.onRecordingComplete = onRecordingComplete
        _recordingProcessor = StateObject(wrappedValue: RecordingProcessor(modelContext: modelContext))
    }

    var body: some View {
        ZStack {
            GradientBackground()

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
                        .funnelTitle()
                        .funnelTextOverlay("Record Your First Message", font: .nunitoExtraBold, size: 18)

                    let speakText = "Speak your thoughts — we'll turn them into something magical."

                    Text(speakText)
                        .funnelBody()
                        .multilineTextAlignment(.center)
                        .funnelTextOverlay(speakText, font: .nunitoRegular, size: 15)
                        .padding(.horizontal, 40)
                }
                .padding(.bottom, currentRecording.isRecording ? 156 : 179)

                RecordingControls(
                    recordingProcessor: recordingProcessor,
                    onRecordingComplete: onRecordingComplete
                )
                .padding(.horizontal, 15)
                .padding(.bottom, 0)
            }
        }
        .ignoresSafeArea()
    }
}

struct RecordingControls: View {
    @EnvironmentObject var currentRecording: CurrentRecordingProvider
    @State private var isPressed = false
    let recordingProcessor: RecordingProcessor
    let onRecordingComplete: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            if currentRecording.isRecording {
                // Recording state
                VStack(spacing: 20) {
                    Text("Voice Recording 1")
                        .funnelTitle()
                        .funnelTextOverlay("Voice Recording 1", font: .nunitoExtraBold, size: 18)

                    Text(formatTime(currentRecording.recordingTime))
                        .funnelBody()
                        .funnelTextOverlay(formatTime(currentRecording.recordingTime), font: .nunitoRegular, size: 15)

                    WaveformView(values: currentRecording.waveformValues)
                        .frame(height: 37)
                        .padding(.horizontal, 25)
                }
                .padding(.top, 30)

                Spacer()

                StopButton(isPressed: $isPressed) {
                    handleStopRecording()
                }
                .padding(.bottom, 46)
            } else {
                // Not recording state
                RecordButton(isPressed: $isPressed) {
                    handleStartRecording()
                }
                .padding(.top, 15)
                .padding(.bottom, 61)
            }
        }
        .frame(width: 372, height: currentRecording.isRecording ? 350 : 179)
        .glassmorphic(
            cornerRadius: 15,
            gradientOpacity: currentRecording.isRecording ? (0.1, 0.4) : (0.0, 0.3)
        )
        .animation(.easeInOut(duration: 0.3), value: currentRecording.isRecording)
    }

    private func handleStartRecording() {
        print("RecordingControls: handleStartRecording called")
        currentRecording.startRecording { result in
            print("RecordingControls: Recording completion result: \(result)")
            // Completion will be handled in stop recording
        }
    }

    private func handleStopRecording() {
        let recordingDuration = currentRecording.recordingTime

        // Ensure minimum recording duration to avoid API errors
        guard recordingDuration >= 0.5 else {
            print("RecordingControls: Recording too short (\(recordingDuration)s), minimum is 0.5s")
            // Could show an alert here, but for now just ignore
            return
        }

        currentRecording.stopRecording()

        // Get the recording URL from the audio recorder
        if let audioURL = currentRecording.audioRecorder.currentRecordingURL {
            Task {
                await recordingProcessor.processRecording(
                    audioURL: audioURL,
                    duration: recordingDuration
                )
                DispatchQueue.main.async {
                    onRecordingComplete()
                }
            }
        } else {
            onRecordingComplete()
        }
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
            Image("RecordButton")
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
    NewRecordingView(
        modelContext: ModelContainer.previewContainer.mainContext,
        onRecordingComplete: {}
    )
    .funnelPreviewEnvironment()
}

