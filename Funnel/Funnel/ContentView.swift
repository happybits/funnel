import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var recordingManager = RecordingManager()

    var body: some View {
        NavigationStack {
            ZStack {
                // Rainbow gradient background from GradientBackground component
                GradientBackground()

                ZStack {
                    // Main recording view
                    NewRecordingView(hideBackground: true)

                    // Processing overlay
                    if recordingManager.isProcessing {
                        ProcessingOverlay()
                            .transition(.opacity.combined(with: .scale(scale: 0.9)))
                    }
                }
                .navigationDestination(item: $recordingManager.presentedRecording) { recording in
                    SwipeableCardsView(recording: recording, hideBackground: true)
                        .navigationBarBackButtonHidden(true)
                        .background(
                            GradientBackground()
                        )
                }
            }
            .animation(.easeInOut(duration: 0.3), value: recordingManager.isProcessing)
        }
        .environmentObject(recordingManager)
    }
}

// Processing overlay that appears on top of recording view
struct ProcessingOverlay: View {
    @EnvironmentObject var recordingManager: RecordingManager

    private var processingBox: some View {
        VStack(spacing: 8) {
            // Processing animation
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))

            let funnelText = "Processing - Hang tight!"
            Text(funnelText)
                .funnelTitle()
                .whiteSandGradientEffect()
                .multilineTextAlignment(.center)

            if let error = recordingManager.processingError {
                Text("Error: \(error.localizedDescription)")
                    .font(.system(size: 14))
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.top, 10)

                Button(action: { recordingManager.dismissError() }) {
                    Text("Dismiss")
                        .funnelBody()
                        .padding(.horizontal, 30)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(Color.white.opacity(0.2))
                        )
                }
                .padding(.top, 20)
            }
        }
        .padding()
        .frame(maxWidth: 350)
        .glassmorphic(cornerRadius: 15, gradientOpacity: (0.1, 0.4))
    }

    var body: some View {
        Color.black.opacity(0.3)
            .ignoresSafeArea()
            .overlay {
                processingBox
            }
    }
}

#Preview {
    ContentView()
        .funnelPreviewEnvironment()
}
