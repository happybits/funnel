import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var recordingManager = RecordingManager()
    @State private var showFontDebug = false
    @State private var currentGradientColors: [Color] = [
        Color(red: 0.972, green: 0.698, blue: 0.459),
        Color(red: 0.976, green: 0.843, blue: 0.459),
    ]

    // Default gradient for recording state
    private let recordingGradientColors = [
        Color(red: 0.972, green: 0.698, blue: 0.459),
        Color(red: 0.976, green: 0.843, blue: 0.459),
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                // Single gradient background that stays in place
                LinearGradient(
                    colors: currentGradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.5), value: currentGradientColors)

                if showFontDebug {
                    // Temporary debug view - triple tap to toggle
                    VStack {
                        FontDebugView()
                            .onTapGesture(count: 3) {
                                showFontDebug = false
                            }
                    }
                } else {
                    ZStack {
                        // Main recording view
                        NewRecordingView(hideBackground: true)
                            .onTapGesture(count: 3) {
                                showFontDebug = true
                            }

                        // Processing overlay
                        if recordingManager.isProcessing {
                            ProcessingOverlay()
                                .transition(.opacity.combined(with: .scale(scale: 0.9)))
                        }
                    }
                    .navigationDestination(item: $recordingManager.presentedRecording) { recording in
                        SwipeableCardsView(recording: recording, hideBackground: false)
                            .navigationBarBackButtonHidden(true)
                            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("CardGradientChanged"))) { notification in
                                if let colors = notification.userInfo?["colors"] as? [Color] {
                                    currentGradientColors = colors
                                }
                            }
                    }
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
