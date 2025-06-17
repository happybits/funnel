//
//  ProcessingView.swift
//  Funnel
//
//  Created by Claude on 6/17/25.
//

import SwiftUI
import SwiftData

struct ProcessingView: View {
    @ObservedObject var recordingProcessor: RecordingProcessor
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            GradientBackground()

            VStack(spacing: 30) {
                // Logo
                HStack {
                    FunnelLogo()
                        .padding(.leading, 30)
                    Spacer()
                }
                .padding(.top, 89)

                Spacer()

                VStack(spacing: 25) {
                    // Processing animation
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(2)

                    Text("Processing Your Recording")
                        .funnelTitle()
                        .funnelTextOverlay("Processing Your Recording", font: .nunitoExtraBold, size: 18)

                    Text(recordingProcessor.processingStatus)
                        .funnelBody()
                        .funnelTextOverlay(recordingProcessor.processingStatus, font: .nunitoRegular, size: 15)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)

                    if let error = recordingProcessor.processingError {
                        Text("Error: \(error.localizedDescription)")
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                            .padding(.top, 10)

                        Button(action: onDismiss) {
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

                Spacer()
            }
        }
        .ignoresSafeArea()
        .onChange(of: recordingProcessor.isProcessing) { _, isProcessing in
            if !isProcessing && recordingProcessor.processingError == nil {
                // Processing completed successfully
                onDismiss()
            }
        }
    }
}

#Preview {
    let processor = RecordingProcessor(modelContext: ModelContainer.previewContainer.mainContext)
    ProcessingView(
        recordingProcessor: processor,
        onDismiss: {}
    )
    .funnelPreviewEnvironment()
}
