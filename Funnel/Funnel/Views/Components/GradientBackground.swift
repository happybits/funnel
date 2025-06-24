import SwiftUI

struct GradientBackground: View {
    @State private var animateGradient = true

    var body: some View {
        LinearGradient(
            gradient: Gradient(stops: [
                .init(color: Color(red: 0.576, green: 0.651, blue: 0.878), location: 0.0),
                .init(color: Color(red: 0.404, green: 0.816, blue: 0.796), location: 0.2),
                .init(color: Color(red: 0.976, green: 0.839, blue: 0.459), location: 0.4),
                .init(color: Color(red: 0.969, green: 0.698, blue: 0.459), location: 0.6),
                .init(color: Color(red: 0.965, green: 0.294, blue: 0.298), location: 0.8),
                .init(color: Color(red: 0.827, green: 0.435, blue: 0.749), location: 1.0),
            ]),
            startPoint: animateGradient ? .topLeading : .top,
            endPoint: animateGradient ? .bottomTrailing : .bottom
        )
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
                animateGradient.toggle()
            }
        }
    }
}

#Preview {
    GradientBackground()
}
