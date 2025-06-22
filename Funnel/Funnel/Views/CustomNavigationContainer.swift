import SwiftUI

// Custom navigation container that provides slide animations without NavigationStack
struct CustomNavigationContainer<Content: View>: View {
    @Binding var currentView: NavigationDestination
    let content: Content

    @State private var displayedView: NavigationDestination = .recording
    @State private var nextView: NavigationDestination?
    @State private var offset: CGFloat = 0
    @State private var isAnimating = false

    init(currentView: Binding<NavigationDestination>, @ViewBuilder content: () -> Content) {
        _currentView = currentView
        self.content = content()
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Current view
                viewForDestination(displayedView)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .offset(x: offset)

                // Next view (slides in during transition)
                if let nextView = nextView {
                    viewForDestination(nextView)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .offset(x: offset + (displayedView == .recording ? geometry.size.width : -geometry.size.width))
                }
            }
        }
        .onChange(of: currentView) { _, newValue in
            guard !isAnimating else { return }
            isAnimating = true

            // Set up the next view
            nextView = newValue

            // Animate the transition
            withAnimation(.easeInOut(duration: 0.3)) {
                if newValue == .recording {
                    // Sliding back (right to left)
                    offset = UIScreen.main.bounds.width
                } else {
                    // Sliding forward (left to right)
                    offset = -UIScreen.main.bounds.width
                }
            }

            // After animation completes, update the displayed view
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                displayedView = newValue
                nextView = nil
                offset = 0
                isAnimating = false
            }
        }
    }

    @ViewBuilder
    private func viewForDestination(_ destination: NavigationDestination) -> some View {
        switch destination {
        case .recording:
            content
        case let .cards(recording):
            SwipeableCardsView(recording: recording)
        }
    }
}

// Navigation destination enum
enum NavigationDestination: Equatable {
    case recording
    case cards(Recording)

    static func == (lhs: NavigationDestination, rhs: NavigationDestination) -> Bool {
        switch (lhs, rhs) {
        case (.recording, .recording):
            return true
        case let (.cards(lhsRecording), .cards(rhsRecording)):
            return lhsRecording.id == rhsRecording.id
        default:
            return false
        }
    }
}

