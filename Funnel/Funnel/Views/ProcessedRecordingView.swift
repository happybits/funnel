//
//  ProcessedRecordingView.swift
//  Funnel
//
//  Created by Claude on 6/17/25.
//

import SwiftUI
import SwiftData

struct ProcessedRecordingView: View {
    let processedRecording: ProcessedRecording
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Duration Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Duration")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("\(formatDuration(processedRecording.duration))")
                            .font(.title3)
                    }
                    .padding(.horizontal)

                    Divider()

                    // Transcript Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Transcript")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text(processedRecording.transcript)
                            .font(.body)
                            .textSelection(.enabled)
                    }
                    .padding(.horizontal)

                    Divider()

                    // Bullet Summary Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Bullet Summary")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        ForEach(Array(processedRecording.bulletSummary.enumerated()), id: \.offset) { _, bullet in
                            HStack(alignment: .top, spacing: 8) {
                                Text("•")
                                    .font(.body)
                                Text(bullet)
                                    .font(.body)
                                    .textSelection(.enabled)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                    .padding(.horizontal)

                    Divider()

                    // Diagram Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Diagram")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Title: \(processedRecording.diagram.title)")
                                .font(.subheadline)
                                .fontWeight(.medium)

                            Text("Description: \(processedRecording.diagram.description)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            Text("Content:")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .padding(.top, 4)

                            Text(processedRecording.diagram.content)
                                .font(.system(.body, design: .monospaced))
                                .textSelection(.enabled)
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal)

                    // Add some bottom padding
                    Color.clear.frame(height: 40)
                }
                .padding(.vertical)
            }
            .navigationTitle("Processed Recording")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func formatDuration(_ duration: Double) -> String {
        let totalSeconds = Int(duration)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

#Preview {
    // Create a sample ProcessedRecording from our preview data
    let sampleRecording = ModelContainer.createSampleRecording(
        container: ModelContainer.previewContainer,
        title: "Sample Recording",
        processingStatus: .completed
    )
    
    let processedRecording = ProcessedRecording(
        transcript: sampleRecording.transcript ?? "This is a sample transcript",
        duration: sampleRecording.duration,
        bulletSummary: sampleRecording.bulletSummary ?? ["Sample bullet point"],
        diagram: ProcessedRecording.DiagramData(
            title: sampleRecording.diagramTitle ?? "Sample Diagram",
            description: sampleRecording.diagramDescription ?? "A sample diagram",
            content: sampleRecording.diagramContent ?? "Sample content"
        )
    )
    
    ProcessedRecordingView(processedRecording: processedRecording)
        .funnelPreviewEnvironment()
}
