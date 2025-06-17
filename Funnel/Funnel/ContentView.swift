//
//  ContentView.swift
//  Funnel
//
//  Created by Joel Drotleff on 6/16/25.
//

import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var recordings: [Recording]
    @State private var showFontDebug = false
    @State private var showProcessing = false
    @State private var showProcessedRecording = false
    @State private var processedRecording: ProcessedRecording?
    @StateObject private var recordingProcessor: RecordingProcessor
    @StateObject private var currentRecording = CurrentRecordingProvider()

    init() {
        // Create a temporary RecordingProcessor - will be updated in onAppear
        let tempContext = try! ModelContext(ModelContainer(for: Recording.self))
        _recordingProcessor = StateObject(wrappedValue: RecordingProcessor(modelContext: tempContext))
    }

    var body: some View {
        ZStack {
            if showFontDebug {
                // Temporary debug view - triple tap to toggle
                VStack {
                    FontDebugView()
                        .onTapGesture(count: 3) {
                            showFontDebug = false
                        }
                }
            } else if let processedRecording = processedRecording, showProcessedRecording {
                ProcessedRecordingView(processedRecording: processedRecording)
                    .transition(.move(edge: .bottom))
            } else if showProcessing {
                ProcessingView(recordingProcessor: recordingProcessor) {
                    withAnimation {
                        showProcessing = false
                        // For debug purposes, show processed recording view if we have the latest recording
                        print("ContentView: Processing complete, recordings count: \(recordings.count)")
                        if let latestRecording = recordings.first {
                            print("ContentView: Latest recording status: \(latestRecording.processingStatus)")
                            print("ContentView: Has transcript: \(latestRecording.transcript != nil)")
                            print("ContentView: Has bullet summary: \(latestRecording.bulletSummary != nil)")
                            showProcessedRecordingAfterProcessing(recording: latestRecording)
                        } else {
                            print("ContentView: No recordings found after processing")
                        }
                    }
                }
            } else {
                NewRecordingView(modelContext: modelContext) {
                    withAnimation {
                        showProcessing = true
                    }
                }
                .environmentObject(currentRecording)
                .onTapGesture(count: 3) {
                    showFontDebug = true
                }
            }
        }
        .onAppear {
            // Update recording processor with actual model context
            recordingProcessor.modelContext = modelContext
        }
    }

    private func showProcessedRecordingAfterProcessing(recording: Recording) {
        // Only show if we have all the data
        guard let transcript = recording.transcript,
              let bulletSummary = recording.bulletSummary,
              let diagramTitle = recording.diagramTitle,
              let diagramDescription = recording.diagramDescription,
              let diagramContent = recording.diagramContent
        else {
            return
        }

        // Create ProcessedRecording from Recording data
        processedRecording = ProcessedRecording(
            transcript: transcript,
            duration: recording.duration,
            bulletSummary: bulletSummary,
            diagram: ProcessedRecording.DiagramData(
                title: diagramTitle,
                description: diagramDescription,
                content: diagramContent
            )
        )

        showProcessedRecording = true
    }
}

#Preview {
    ContentView()
        .funnelPreviewEnvironment()
}
