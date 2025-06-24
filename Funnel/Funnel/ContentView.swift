import SwiftUI

enum AppState {
    case empty
    case recording
    case viewingIndex
    case viewingTranscript
    case viewingSketch
}

struct ContentView: View {
    @State private var appState: AppState = .empty
    @State private var recordingData: RecordingData?

    var body: some View {
        ZStack {
            switch appState {
            case .empty:
                EmptyStateView {
                    withAnimation {
                        appState = .recording
                    }
                }

            case .recording:
                RecordingView {
                    withAnimation {
                        // Simulate processing and show results
                        recordingData = RecordingData.sample
                        appState = .viewingIndex
                    }
                }

            case .viewingIndex:
                if let data = recordingData {
                    IndexCardView(
                        title: data.title,
                        bulletPoints: data.bulletPoints,
                        onBack: {
                            withAnimation {
                                appState = .empty
                            }
                        },
                        onAdd: {
                            // Handle add action
                        }
                    )
                    .overlay(alignment: .bottom) {
                        HStack(spacing: 20) {
                            Button {
                                withAnimation {
                                    appState = .viewingTranscript
                                }
                            } label: {
                                Image(systemName: "doc.text")
                                    .font(.system(size: 22))
                                    .foregroundColor(.white.opacity(0.8))
                                    .frame(width: 50, height: 50)
                                    .background(
                                        Circle()
                                            .fill(Color.white.opacity(0.2))
                                    )
                            }

                            Button {
                                // Already on index
                            } label: {
                                Image(systemName: "list.bullet")
                                    .font(.system(size: 22))
                                    .foregroundColor(.white)
                                    .frame(width: 50, height: 50)
                                    .background(
                                        Circle()
                                            .fill(Color.white.opacity(0.4))
                                    )
                            }

                            Button {
                                withAnimation {
                                    appState = .viewingSketch
                                }
                            } label: {
                                Image(systemName: "square.grid.2x2")
                                    .font(.system(size: 22))
                                    .foregroundColor(.white.opacity(0.8))
                                    .frame(width: 50, height: 50)
                                    .background(
                                        Circle()
                                            .fill(Color.white.opacity(0.2))
                                    )
                            }
                        }
                        .padding(.bottom, 120)
                    }
                }

            case .viewingTranscript:
                if let data = recordingData {
                    TranscriptCardView(
                        title: data.title,
                        transcript: data.transcript,
                        duration: data.duration,
                        onBack: {
                            withAnimation {
                                appState = .viewingIndex
                            }
                        },
                        onAdd: {
                            // Handle add action
                        }
                    )
                }

            case .viewingSketch:
                if let data = recordingData {
                    SketchCardView(
                        title: data.title,
                        onBack: {
                            withAnimation {
                                appState = .viewingIndex
                            }
                        },
                        onDiagram: {
                            // Handle diagram action
                        }
                    )
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct RecordingData {
    let title: String
    let bulletPoints: [String]
    let transcript: String
    let duration: String

    static let sample = RecordingData(
        title: "AI Coding ≠ Managing Junior Devs",
        bulletPoints: [
            "It's like a magic paintbrush from a glitchy video game",
            "Incredibly powerful but maddeningly unintuitive",
            "Wrong angle = nothing happens",
            "Right angle = instant transformation",
            "Requires learning alien logic, not people skills",
        ],
        transcript: "Okay. So I am thinking about an idea I had for an article which is like why agentic coding with Agentic coding assistance like Claude Code, and Cursor, it feels like.\n\nAnd I've heard it described being a manager. You're gonna be a manager. It's like being a manager of humans. You've got all these AI agents.\n\nThey're just like little humans that know, human engineers, and you just have to tell them what to do, and they'll magically write code for you and then maybe they do it wrong, and you just have to give them feedback, and then it'll work.\n\nBut I don't really think that metaphor is super accurate. And but I've been trying to think of what is a better metaphor. We're like, what is this like? And, you know, is it coding with a broken or something? Or is it coding with a know how something with things with bricks? Or with. Construction equipment For what? And I",
        duration: "45s"
    )
}

#Preview {
    ContentView()
}
