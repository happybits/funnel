import SwiftUI

struct LiveBlurTestView: View {
    @State private var blurRadius: CGFloat = 20
    @State private var showBlur = true
    @State private var offset: CGFloat = 0

    var body: some View {
        ZStack {
            // Background content
            backgroundContent

            // Blurred overlay
            if showBlur {
                LiveBlurView(style: .regular, blurRadius: blurRadius)
                    .frame(width: 300, height: 200)
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
                    .offset(y: offset)
                    .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: offset)
            }

            // Controls
            VStack {
                Spacer()

                VStack(spacing: 20) {
                    // Blur radius slider
                    VStack(alignment: .leading) {
                        Text("Blur Radius: \(Int(blurRadius))")
                            .foregroundColor(.white)
                            .font(.headline)

                        Slider(value: $blurRadius, in: 0 ... 50)
                            .accentColor(.blue)
                    }

                    // Toggle blur
                    Toggle("Show Blur", isOn: $showBlur)
                        .foregroundColor(.white)
                        .font(.headline)

                    // Move blur view
                    Button("Animate Position") {
                        offset = offset == 0 ? -100 : 0
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                .background(Color.black.opacity(0.7))
                .cornerRadius(15)
                .padding()
            }
        }
        .ignoresSafeArea()
    }

    var backgroundContent: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [Color.blue, Color.purple, Color.pink],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Animated circles
            ForEach(0 ..< 5) { index in
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.white.opacity(0.8),
                                Color.white.opacity(0.1),
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 50
                        )
                    )
                    .frame(width: 100, height: 100)
                    .offset(
                        x: CGFloat.random(in: -150 ... 150),
                        y: CGFloat.random(in: -300 ... 300)
                    )
                    .animation(
                        Animation.easeInOut(duration: Double.random(in: 3 ... 6))
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.2),
                        value: offset
                    )
            }

            // Text content
            VStack(spacing: 30) {
                Text("Live Blur Demo")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text("This blur updates in real-time")
                    .font(.title2)
                    .foregroundColor(.white.opacity(0.8))

                Text("Move the controls to see the blur adapt")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(.top, 100)
        }
    }
}

#Preview {
    LiveBlurTestView()
}
