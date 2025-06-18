
import SwiftData
import SwiftUI

struct ProcessingView: View {
    @EnvironmentObject var appState: AppState

    private var logo: some View {
        HStack {
            FunnelLogo()
                .padding(.leading, 30)
                .padding(.top, 89)
            Spacer()
        }
    }

    private var processingBox: some View {
        VStack(spacing: 8) {
            // Processing animation
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))

            let funnelText = "Processing - Hang tight!"
            Text(funnelText)
                .funnelTitle()
                .multilineTextAlignment(.center)

            if let error = appState.processingError {
                Text("Error: \(error.localizedDescription)")
                    .font(.system(size: 14))
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.top, 10)

                Button(action: { appState.resetToRecording() }) {
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
        VStack {
            HStack {
                logo
                Spacer()
            }
            
            Spacer()
            
            processingBox
            
            Spacer()
        }
    }
}

#Preview {
    ProcessingView()
        .funnelPreviewEnvironment()
        .environmentObject(AppState(modelContext: ModelContainer.previewContainer.mainContext))
}
