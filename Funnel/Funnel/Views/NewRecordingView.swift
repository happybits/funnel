
import SwiftData
import SwiftUI

struct NewRecordingView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var recordingManager: RecordingManager
    @EnvironmentObject var debugSettings: DebugSettings
    @EnvironmentObject var audioRecorder: AudioRecorderManager
    @Query(sort: \Recording.timestamp, order: .reverse) private var recordings: [Recording]

    @State private var isRecording = false
    @State private var recordingTime: TimeInterval = 0
    @State private var waveformValues: [CGFloat] = []
    @State private var recordingError: Error?

    private var recordingTimer: Timer?
    private var levelTimer: Timer?

    var body: some View {
        ZStack(alignment: .bottom) {
            // Background recordings list that extends full height
            if !recordings.isEmpty && !isRecording {
                RecordingsListView(recordings: recordings)
                    .padding(.horizontal, 15)
                    .padding(.top, 178) // Space for logo
            }

            VStack(spacing: 0) {
                // Logo aligned to left
                HStack {
                    FunnelLogo()
                        .padding(.leading, 30)
                    Spacer()

                    // Blur toggle for debugging
                    // Toggle("Blur", isOn: $debugSettings.blurEnabled)
                    //     .toggleStyle(CheckboxToggleStyle())
                    //     .foregroundColor(.white.opacity(0.7))
                    //     .padding(.trailing, 30)
                }
                .padding(.top, 89)

                if recordings.isEmpty && !isRecording {
                    // Show explainer text when no recordings
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
                    .padding(.bottom, 179)
                } else {
                    Spacer()
                }
            }

            // Recording controls float on top
            RecordingControlsView(
                isRecording: $isRecording,
                recordingTime: $recordingTime,
                waveformValues: $waveformValues,
                recordingError: $recordingError,
                audioRecorder: audioRecorder,
                onRecordingComplete: { audioURL, duration, recordingId, isLiveStreaming in
                    Task {
                        await recordingManager.processRecording(
                            audioURL: audioURL,
                            duration: duration,
                            modelContext: modelContext,
                            recordingId: recordingId,
                            isLiveStreaming: isLiveStreaming
                        )
                    }
                }
            )
            .padding(.horizontal, 15)
        }
        .ignoresSafeArea()
    }
}

struct RecordingControlsView: View {
    @Binding var isRecording: Bool
    @Binding var recordingTime: TimeInterval
    @Binding var waveformValues: [CGFloat]
    @Binding var recordingError: Error?

    let audioRecorder: AudioRecorderManager
    let onRecordingComplete: (URL, TimeInterval, String?, Bool) -> Void

    @State private var isPressed = false
    @State private var recordingTimer: Timer?
    @State private var levelTimer: Timer?

    var body: some View {
        VStack(spacing: 0) {
            if isRecording {
                // Recording state
                VStack(spacing: 20) {
                    Text("Voice Recording")
                        .funnelFont(.nunitoExtraBold, size: 18)
                        .whiteSandGradientEffect()

                    Text(formatTime(recordingTime))
                        .funnelBody()
                        .whiteSandGradientEffect()

                    WaveformView(values: waveformValues)
                        .frame(height: 37)
                        .padding(.horizontal, 25)
                }
                .padding(.top, 30)

                Spacer()
            }

            // Single button that changes based on state
            Button {
                if isRecording {
                    stopRecording()
                } else {
                    startRecording()
                }
            } label: {
                Image(isRecording ? "StopRecordBtn" : "RecordBtn")
                    .scaleEffect(isPressed ? 0.95 : 1.0)
            }
            .buttonStyle(PlainButtonStyle())
            .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = pressing
                }
            }, perform: {})
            .padding(.top, 15)
            .padding(.bottom, 61)
        }
        .frame(width: 372, height: isRecording ? 350 : 179)
        .liveGlassmorphic(
            cornerRadius: 15,
            gradientOpacity: isRecording ? (0.05, 0.25) : (0.0, 0.15)
        )
        .animation(.easeInOut(duration: 0.3), value: isRecording)
    }

    private func startRecording() {
        audioRecorder.requestMicrophonePermission { granted in
            guard granted else {
                recordingError = FunnelError.microphonePermissionDenied
                return
            }

            audioRecorder.startRecording { result in
                switch result {
                case .success:
                    DispatchQueue.main.async {
                        isRecording = true
                        recordingTime = 0
                        waveformValues = []
                        startTimers()
                    }
                case let .failure(error):
                    recordingError = error
                }
            }
        }
    }

    private func stopRecording() {
        let duration = recordingTime

        guard duration >= 0.5 else {
            recordingError = FunnelError.recordingTooShort(minimumDuration: 0.5)
            return
        }

        // Capture these values BEFORE stopping (they get reset in stopRecording)
        let wasLiveStreaming = audioRecorder.isLiveStreaming
        let recordingId = audioRecorder.recordingId
        let recordingURL = audioRecorder.currentRecordingURL

        print("RecordingControlsView: Stopping recording - wasLiveStreaming: \(wasLiveStreaming), recordingId: \(recordingId ?? "nil")")

        audioRecorder.stopRecording()
        recordingTimer?.invalidate()
        levelTimer?.invalidate()

        isRecording = false

        // For live streaming, we need to use a dummy URL and pass the recording ID
        if wasLiveStreaming {
            // Create a dummy URL for compatibility
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let dummyURL = documentsPath.appendingPathComponent("live-stream-\(recordingId ?? "unknown").m4a")
            onRecordingComplete(dummyURL, duration, recordingId, true)
        } else if let audioURL = recordingURL {
            // Traditional file-based recording
            onRecordingComplete(audioURL, duration, nil, false)
        }
    }

    private func startTimers() {
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            DispatchQueue.main.async {
                recordingTime = audioRecorder.recordingTime
            }
        }

        levelTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            DispatchQueue.main.async {
                withAnimation(.linear(duration: 0.05)) {
                    let normalizedLevel = CGFloat(audioRecorder.audioLevel)
                    let visualLevel = max(0.05, normalizedLevel)
                    waveformValues.append(visualLevel)

                    if waveformValues.count > 50 {
                        waveformValues.removeFirst()
                    }
                }
            }
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

struct RecordingsListView: View {
    let recordings: [Recording]
    @EnvironmentObject var recordingManager: RecordingManager

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(recordings) { recording in
                    Button {
                        recordingManager.presentedRecording = recording
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(recording.title)
                                    .funnelFont(.nunitoBold, size: 16)
                                    .foregroundColor(.white)
                                    .shadow(radius: 8)
                                    .lineLimit(1)

                                Text(recording.timestamp.formatted(date: .abbreviated, time: .shortened))
                                    .funnelFont(.nunitoRegular, size: 14)
                                    .foregroundColor(.white.opacity(0.7))
                                    .shadow(radius: 8)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .foregroundColor(.white.opacity(0.5))
                        }
                        .padding(20)
                        .frame(maxWidth: .infinity)
                        .liveGlassmorphicCell(
                            cornerRadius: 15,
                            gradientOpacity: (0.1, 0.3)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.bottom, 195) // Add bottom padding to content so last item can scroll above record button
        }
        .scrollIndicators(.hidden)
    }
}

#Preview {
    ZStack {
        GradientBackground()
        NewRecordingView()
            .funnelPreviewEnvironment()
            .environmentObject(RecordingManager())
            .environmentObject(DebugSettings())
            .environmentObject(AudioRecorderManager())
    }
}
