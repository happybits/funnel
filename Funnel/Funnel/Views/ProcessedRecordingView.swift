//
//  ProcessedRecordingView.swift
//  Funnel
//
//  Created by Claude on 6/17/25.
//

import SwiftData
import SwiftUI

struct ProcessedRecordingView: View {
    let recording: Recording
    @EnvironmentObject var appState: AppState
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
                        Text("\(formatDuration(recording.duration))")
                            .font(.title3)
                    }
                    .padding(.horizontal)

                    Divider()

                    // Transcript Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Transcript")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text(recording.transcript ?? "No transcript available")
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

                        ForEach(Array((recording.bulletSummary ?? []).enumerated()), id: \.offset) { _, bullet in
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
                            Text("Title: \(recording.diagramTitle ?? "No title")")
                                .font(.subheadline)
                                .fontWeight(.medium)

                            Text("Description: \(recording.diagramDescription ?? "No description")")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            Text("Content:")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .padding(.top, 4)

                            Text(recording.diagramContent ?? "No content")
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
                        appState.resetToRecording()
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
    let sampleRecording = ModelContainer.createSampleRecording(
        container: ModelContainer.previewContainer,
        title: "Sample Recording",
        processingStatus: .completed
    )

    ProcessedRecordingView(recording: sampleRecording)
        .funnelPreviewEnvironment()
        .environmentObject(AppState(modelContext: ModelContainer.previewContainer.mainContext))
}
