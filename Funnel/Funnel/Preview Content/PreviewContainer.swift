//
//  PreviewContainer.swift
//  Funnel
//
//  Created by Claude on 6/17/25.
//

import Foundation
import SwiftData
import SwiftUI

// Sample data for previews
private let sampleTranscripts = [
    "Hey, I just had this amazing idea for a new feature. What if we could allow users to share their recordings directly to social media? I think it would really increase engagement.",
    "So I was thinking about the user onboarding flow. Right now it's a bit confusing. We should simplify it and maybe add a quick tutorial.",
    "Just recorded my thoughts on the new design. I love the gradient background, but I think we need to make the buttons more prominent.",
    "Quick note: We need to fix that bug in the audio player. It's cutting off the last few seconds of recordings.",
    "Reminder to myself: Schedule a meeting with the design team to discuss the new icon set.",
]

private let sampleBulletSummaries = [
    ["• New feature idea: Social media sharing", "• Expected to increase user engagement", "• Would allow direct sharing of recordings"],
    ["• User onboarding needs simplification", "• Current flow is confusing", "• Suggest adding a tutorial"],
    ["• Positive feedback on gradient background", "• Buttons need more visual prominence", "• Overall design direction is good"],
    ["• Audio player bug identified", "• Last few seconds of recordings being cut off", "• High priority fix needed"],
    ["• Action item: Schedule design team meeting", "• Topic: New icon set discussion", "• Time-sensitive"],
]

private let sampleDiagramTitles = [
    "Social Media Integration Flow",
    "Simplified Onboarding Process",
    "UI Enhancement Priorities",
    "Audio Player Bug Fix",
    "Team Meeting Agenda",
]

extension ModelContainer {
    @MainActor
    static func createSampleRecording(
        container: ModelContainer,
        title: String? = nil,
        processingStatus: ProcessingStatus = .completed
    ) -> Recording {
        let index = Int.random(in: 0..<sampleTranscripts.count)
        
        let recording = Recording(
            audioFileName: "recording_\(UUID().uuidString).m4a",
            duration: TimeInterval.random(in: 30...180)
        )
        
        recording.title = title ?? "Recording \(Int.random(in: 1...100))"
        recording.processingStatus = processingStatus
        
        if processingStatus == .completed {
            recording.transcript = sampleTranscripts[index]
            recording.bulletSummary = sampleBulletSummaries[index]
            recording.diagramTitle = sampleDiagramTitles[index]
            recording.diagramDescription = "A visual representation of the key concepts discussed"
            recording.diagramContent = """
            ```mermaid
            graph TD
                A[Main Idea] --> B[Key Point 1]
                A --> C[Key Point 2]
                B --> D[Action Item]
                C --> E[Follow-up]
            ```
            """
        }
        
        container.mainContext.insert(recording)
        return recording
    }
    
    @MainActor
    static let previewContainer: ModelContainer = {
        do {
            let schema = Schema([Recording.self])
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            let container = try ModelContainer(for: schema, configurations: config)
            
            // Create sample recordings
            let _ = createSampleRecording(
                container: container,
                title: "Morning Standup Notes",
                processingStatus: .completed
            )
            
            let _ = createSampleRecording(
                container: container,
                title: "Feature Brainstorm",
                processingStatus: .completed
            )
            
            let _ = createSampleRecording(
                container: container,
                title: "Bug Report",
                processingStatus: .transcribing
            )
            
            let _ = createSampleRecording(
                container: container,
                title: "Design Review",
                processingStatus: .failed
            )
            
            return container
        } catch {
            fatalError("Failed to create preview container: \(error.localizedDescription)")
        }
    }()
}

// View modifier for adding preview environment
extension View {
    @ViewBuilder
    func funnelPreviewEnvironment() -> some View {
        self
            .modelContainer(ModelContainer.previewContainer)
            .environmentObject(MockCurrentRecordingProvider())
    }
}

// Helper to check if running in preview
var isRunningInPreview: Bool {
    ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
}

// Mock recording provider for previews
class MockCurrentRecordingProvider: CurrentRecordingProvider {
    private var mockTimer: Timer?
    private var mockWaveformTimer: Timer?
    
    override func startRecording(completion: @escaping (Result<URL, Error>) -> Void) {
        // Simulate recording start
        DispatchQueue.main.async { [weak self] in
            self?.isRecording = true
            self?.recordingTime = 0
            self?.waveformValues = []
            self?.startMockTimers()
        }
    }
    
    override func stopRecording() {
        mockTimer?.invalidate()
        mockWaveformTimer?.invalidate()
        isRecording = false
        recordingTime = 0
        waveformValues = []
    }
    
    private func startMockTimers() {
        // Mock recording time
        mockTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.recordingTime += 0.1
        }
        
        // Mock waveform animation
        mockWaveformTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            withAnimation(.linear(duration: 0.05)) {
                // Generate random waveform values to simulate audio
                let randomLevel = CGFloat.random(in: 0.1...0.8)
                self.waveformValues.append(randomLevel)
                
                if self.waveformValues.count > 50 {
                    self.waveformValues.removeFirst()
                }
            }
        }
    }
}