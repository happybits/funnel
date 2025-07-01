import SwiftData
import SwiftUI
import UIKit

struct SwipeableCardsView: View {
    @EnvironmentObject var recordingManager: RecordingManager
    @EnvironmentObject var gradientManager: GradientBackgroundManager
    @Environment(\.modelContext) private var modelContext
    @State private var currentPage = 0
    @State private var dragOffset: CGSize = .zero
    @State private var scrollOffset: CGFloat = 0
    @State private var scrolledID: Int? = 0

    let recording: Recording

    // Computed property for truncated title
    private var truncatedTitle: String {
        if let firstBullet = recording.bulletSummary?.first {
            // Take first 30 characters and add ellipsis if needed
            let maxLength = 30
            if firstBullet.count > maxLength {
                return String(firstBullet.prefix(maxLength - 3)) + "..."
            }
            return firstBullet
        }
        return "Recording"
    }

    private var header: some View {
        HStack {
            Button {
                recordingManager.presentedRecording = nil
            } label: {
                Image("BackBtn")
            }

            Spacer()

            Button {
                // TODO: Add voice action
            } label: {
                Image("AddBtn")
            }
        }
        .padding(.top, 10)
    }

    private var cardsContainer: some View {
        // Cards Container with custom scroll view for peek effect
        GeometryReader { geometry in
            let cardWidth = geometry.size.width - 60 // Full width minus 30px on each side

            ScrollViewReader { scrollProxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {
                        BulletSummaryCard(bulletSummary: recording.bulletSummary ?? [])
                            .frame(width: cardWidth)
                            .id(0)

                        DiagramCard(diagram: recording.diagram)
                            .frame(width: cardWidth)
                            .id(1)

                        TranscriptCard(transcript: recording.transcript ?? "")
                            .frame(width: cardWidth)
                            .id(2)
                    }
                    .scrollTargetLayout()
                }
                .contentMargins(.horizontal, 30, for: .scrollContent)
                .scrollTargetBehavior(.viewAligned)
                .scrollPosition(id: $scrolledID)
                .onAppear {
                    scrollProxy.scrollTo(currentPage, anchor: .center)
                }
                .onChange(of: scrolledID) { _, newValue in
                    if let page = newValue {
                        currentPage = page
                    }
                }
            }
        }
        .padding(.top, 20)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            cardsContainer
        }
        .onChange(of: currentPage) { _, newValue in
            // Update gradient based on current card
            switch newValue {
            case 0:
                gradientManager.setTheme(.orange)
            case 1:
                gradientManager.setTheme(.pinkRed)
            case 2:
                gradientManager.setTheme(.blueTeal)
            default:
                gradientManager.setTheme(.defaultTheme)
            }
        }
        .onAppear {
            // Set initial gradient based on first card
            gradientManager.setTheme(.orange)
        }
        .onDisappear {
            // Reset to default gradient when leaving
            gradientManager.setTheme(.defaultTheme)
        }
    }
}

// MARK: - Card Views

struct BulletSummaryCard: View {
    let bulletSummary: [String]

    var body: some View {
        VStack(spacing: 20) {
            Text("Summary")
                .funnelBodyBold()
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)

            VStack(alignment: .leading, spacing: 12) {
                ForEach(bulletSummary, id: \.self) { bullet in
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                            .funnelCallout()
                            .foregroundColor(.white.opacity(0.8))

                        Text(bullet)
                            .funnelCallout()
                            .foregroundColor(.white.opacity(0.9))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            Spacer()
        }
        .padding(25)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(
                    LinearGradient(
                        stops: [
                            .init(color: Color.white, location: 0),
                            .init(color: Color.white.opacity(0), location: 0.434),
                            .init(color: Color.white, location: 1),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: 4)
        .liveGlassmorphicCell(cornerRadius: 10)
        .padding(.bottom, 100)
        .overlay(alignment: .bottomLeading) {
            CardOptions(cardType: .bulletSummary(bulletSummary))
        }
    }
}

struct DiagramCard: View {
    let diagram: Recording.Diagram?

    var body: some View {
        VStack(spacing: 20) {
            if let diagram = diagram {
                Text(diagram.title)
                    .funnelBodyBold()
                    .foregroundColor(.white)

                Text(diagram.description)
                    .funnelCallout()
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)

                Spacer()

                // TODO: Render actual diagram
                Text(diagram.content)
                    .funnelSmall()
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)

                Spacer()
            } else {
                Text("No diagram available")
                    .funnelCallout()
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .padding(25)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [Color.white.opacity(0.1), Color.white.opacity(0.4)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .opacity(0.6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 9)
                .stroke(
                    LinearGradient(
                        stops: [
                            .init(color: Color.white, location: 0),
                            .init(color: Color.white.opacity(0), location: 0.434),
                            .init(color: Color.white, location: 1),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.9
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 9))
        .shadow(color: .black.opacity(0.12), radius: 10.8, x: 0, y: 3.6)
        .liveGlassmorphicCell(cornerRadius: 9)
        .padding(.bottom, 100)
        .overlay(alignment: .bottomLeading) {
            CardOptions(cardType: .diagram(diagram))
        }
    }
}

struct TranscriptCard: View {
    let transcript: String

    var body: some View {
        ScrollView {
            Text(transcript)
                .funnelCallout()
                .foregroundColor(.white.opacity(0.9))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(25)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [Color.white.opacity(0.1), Color.white.opacity(0.4)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .opacity(0.6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 9)
                .stroke(
                    LinearGradient(
                        stops: [
                            .init(color: Color.white, location: 0),
                            .init(color: Color.white.opacity(0), location: 0.434),
                            .init(color: Color.white, location: 1),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.9
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 9))
        .shadow(color: .black.opacity(0.12), radius: 10.8, x: 0, y: 3.6)
        .liveGlassmorphicCell(cornerRadius: 9)
        .padding(.bottom, 100)
        .overlay(alignment: .bottomLeading) {
            CardOptions(cardType: .transcript(transcript))
        }
    }
}

#Preview {
    SwipeableCardsView(recording: {
        let recording = Recording(audioFileName: "sample.m4a", duration: 60)
        recording.transcript = "This is a sample transcript that demonstrates the text content..."
        recording.bulletSummary = [
            "First key point from the recording",
            "Second important insight",
            "Third valuable observation",
            "Final summary point",
        ]
        recording.diagramTitle = "Key Concepts"
        recording.diagramDescription = "Visual representation of main ideas"
        recording.diagramContent = "Concept A → Concept B → Result"
        return recording
    }())
        .funnelPreviewEnvironment()
        .background(GradientBackground())
}
