import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var newRecordingViewModel = NewRecordingViewModel()
    @StateObject private var gradientManager = GradientBackgroundManager()
    @State private var navigationDestination: NavigationDestination = .recording

    var body: some View {
        ZStack {
            GradientBackground()

            PushTransitionContainer(currentView: $navigationDestination) {
                // Main recording view
                NewRecordingView()
                    .overlay {
                        if newRecordingViewModel.isProcessing {
                            ProcessingOverlay()
                                .transition(.opacity)
                        }
                    }
                    .animation(.easeInOut(duration: 0.3), value: newRecordingViewModel.isProcessing)
            }
        }
        .environmentObject(newRecordingViewModel)
        .environmentObject(gradientManager)
        .onChange(of: newRecordingViewModel.presentedRecording) { _, newValue in
            if let recording = newValue {
                navigationDestination = .cards(recording)
            } else {
                navigationDestination = .recording
            }
        }
    }
}

// Processing overlay that appears on top of recording view
struct ProcessingOverlay: View {
    @EnvironmentObject var viewModel: NewRecordingViewModel

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

            if let error = viewModel.processingError {
                Text("Error: \(error.localizedDescription)")
                    .font(.system(size: 14))
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.top, 10)

                Button(action: { viewModel.dismissError() }) {
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
        .liveGlassmorphic(cornerRadius: 15, gradientOpacity: (0.1, 0.4))
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
