import SwiftUI
import SwiftData

struct SwipeableCardsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.modelContext) private var modelContext
    @State private var currentPage = 0
    @State private var dragOffset: CGSize = .zero
    
    let recording: Recording
    
    // Gradient colors for each card
    private let gradientColors: [[Color]] = [
        // Bullet Summary - Orange to Yellow
        [
            Color(red: 0.97, green: 0.70, blue: 0.46),
            Color(red: 0.98, green: 0.84, blue: 0.46)
        ],
        // Diagram - Blue to Purple
        [
            Color(red: 0.58, green: 0.65, blue: 0.88),
            Color(red: 0.83, green: 0.44, blue: 0.75)
        ],
        // Transcript - Cyan to Green
        [
            Color(red: 0.40, green: 0.82, blue: 0.80),
            Color(red: 0.56, green: 0.93, blue: 0.56)
        ]
    ]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Animated gradient background
                LinearGradient(
                    colors: gradientColors[currentPage],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.5), value: currentPage)
                
                VStack(spacing: 0) {
                    // Header with back button and add voice button
                    HStack {
                        // Back button
                        Button(action: {
                            appState.resetToRecording()
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.4), Color.white.opacity(0.9)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 24, height: 24)
                                .padding(10)
                                .background(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.1), Color.white.opacity(0.4)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                    .opacity(0.5)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 22)
                                        .stroke(
                                            LinearGradient(
                                                stops: [
                                                    .init(color: Color.white, location: 0),
                                                    .init(color: Color.white.opacity(0), location: 0.434),
                                                    .init(color: Color.white, location: 1)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 1
                                        )
                                )
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.12), radius: 22.75, x: 0, y: 7.58)
                                .glassmorphic(
                                    cornerRadius: 22,
                                    blurRadius: 18.96
                                )
                        }
                        
                        Spacer()
                        
                        // Add Voice button
                        Button(action: {
                            // TODO: Add voice action
                        }) {
                            HStack(spacing: 8) {
                                Text("Add")
                                    .funnelSubheadlineBold()
                                
                                Image(systemName: "mic.fill")
                                    .font(.system(size: 14))
                            }
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.1), Color.white.opacity(0.4)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .padding(.horizontal, 15)
                            .padding(.vertical, 10)
                            .background(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.1), Color.white.opacity(0.4)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                .opacity(0.5)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 22)
                                    .stroke(
                                        LinearGradient(
                                            stops: [
                                                .init(color: Color.white, location: 0),
                                                .init(color: Color.white.opacity(0), location: 0.434),
                                                .init(color: Color.white, location: 1)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            )
                            .clipShape(Capsule())
                            .shadow(color: .black.opacity(0.12), radius: 22.75, x: 0, y: 7.58)
                            .glassmorphic(
                                cornerRadius: 22,
                                blurRadius: 18.96
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    // Cards Container
                    TabView(selection: $currentPage) {
                        BulletSummaryCard(bulletSummary: recording.bulletSummary ?? [])
                            .tag(0)
                        
                        DiagramCard(diagram: recording.diagram)
                            .tag(1)
                        
                        TranscriptCard(transcript: recording.transcript ?? "")
                            .tag(2)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .padding(.top, 20)
                    
                    // Custom page indicators
                    HStack(spacing: 8) {
                        ForEach(0..<3) { index in
                            Circle()
                                .fill(currentPage == index ? Color.white : Color.white.opacity(0.3))
                                .frame(width: 8, height: 8)
                                .scaleEffect(currentPage == index ? 1.2 : 1)
                                .animation(.spring(response: 0.3), value: currentPage)
                        }
                    }
                    .padding(.bottom, 50)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Card Views

struct BulletSummaryCard: View {
    let bulletSummary: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Summary")
                .funnelBodyBold()
                .foregroundColor(.white)
            
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
        .background(
            LinearGradient(
                colors: [Color.white.opacity(0.1), Color.white.opacity(0.4)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .opacity(0.5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(
                    LinearGradient(
                        stops: [
                            .init(color: Color.white, location: 0),
                            .init(color: Color.white.opacity(0), location: 0.434),
                            .init(color: Color.white, location: 1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: 4)
        .glassmorphic(cornerRadius: 10, blurRadius: 10)
        .padding(.horizontal, 30)
        .padding(.bottom, 100)
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
                            .init(color: Color.white, location: 1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.9
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 9))
        .shadow(color: .black.opacity(0.12), radius: 10.8, x: 0, y: 3.6)
        .glassmorphic(cornerRadius: 9, blurRadius: 9)
        .padding(.horizontal, 50)
        .padding(.bottom, 100)
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
                            .init(color: Color.white, location: 1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.9
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 9))
        .shadow(color: .black.opacity(0.12), radius: 10.8, x: 0, y: 3.6)
        .glassmorphic(cornerRadius: 9, blurRadius: 9)
        .padding(.horizontal, 50)
        .padding(.bottom, 100)
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
            "Final summary point"
        ]
        recording.diagramTitle = "Key Concepts"
        recording.diagramDescription = "Visual representation of main ideas"
        recording.diagramContent = "Concept A → Concept B → Result"
        return recording
    }())
    .funnelPreviewEnvironment()
}