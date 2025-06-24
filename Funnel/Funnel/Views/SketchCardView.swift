import SwiftUI

struct SketchCardView: View {
    let title: String
    let onBack: () -> Void
    let onDiagram: () -> Void

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.827, green: 0.435, blue: 0.749),
                    Color(red: 0.727, green: 0.335, blue: 0.649),
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Button {
                        onBack()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(
                                Circle()
                                    .fill(Color.white.opacity(0.2))
                            )
                    }

                    Spacer()

                    Text(title)
                        .font(.custom("NunitoSans-Bold", size: 16))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .frame(maxWidth: 200)

                    Spacer()

                    Button {
                        // Add action
                    } label: {
                        HStack(spacing: 6) {
                            Text("Add")
                                .font(.custom("NunitoSans-SemiBold", size: 14))
                            Image(systemName: "arrow.down.circle")
                                .font(.system(size: 16))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.2))
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                .padding(.bottom, 20)

                ScrollView {
                    VStack(spacing: 20) {
                        HStack(spacing: 40) {
                            VStack {
                                Text("MAGIC PAINTBRUSH")
                                    .font(.custom("NunitoSans-Bold", size: 14))
                                    .foregroundColor(.white)
                                Text("DEV")
                                    .font(.custom("NunitoSans-Bold", size: 14))
                                    .foregroundColor(.white)
                            }

                            VStack {
                                Text("NOT JUNIOR")
                                    .font(.custom("NunitoSans-Bold", size: 14))
                                    .foregroundColor(.white)
                                Text("")
                                    .font(.custom("NunitoSans-Bold", size: 14))
                            }
                        }
                        .padding(.top, 20)

                        VStack(spacing: 30) {
                            ComparisonRow(
                                left: "Single Tool",
                                right: "Separate Person"
                            )

                            Image(systemName: "arrow.down")
                                .font(.system(size: 20))
                                .foregroundColor(.white.opacity(0.8))

                            ComparisonRow(
                                left: "Direct Control\nof Output",
                                right: "Delegation\nBack & Forth"
                            )

                            Image(systemName: "arrow.down")
                                .font(.system(size: 20))
                                .foregroundColor(.white.opacity(0.8))

                            ComparisonRow(
                                left: "Instant Results",
                                right: "Async Process"
                            )

                            Image(systemName: "arrow.down")
                                .font(.system(size: 20))
                                .foregroundColor(.white.opacity(0.8))

                            ComparisonRow(
                                left: "YOU control the\nstrokes",
                                right: "THEY interpret\nrequirements"
                            )
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 30)
                    }
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(stops: [
                                        .init(color: .white.opacity(0.2), location: 0),
                                        .init(color: .white.opacity(0.1), location: 1),
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                    )
                    .padding(.horizontal, 20)
                }

                HStack(spacing: 20) {
                    ForEach(["doc.text", "bubble.left", "arrow.up.doc"], id: \.self) { icon in
                        Button {
                            // Action for bottom buttons
                        } label: {
                            Image(systemName: icon)
                                .font(.system(size: 22))
                                .foregroundColor(.white.opacity(0.8))
                                .frame(width: 50, height: 50)
                                .background(
                                    Circle()
                                        .fill(Color.white.opacity(0.2))
                                )
                        }
                    }
                }
                .padding(.vertical, 20)

                Button {
                    onDiagram()
                } label: {
                    Text("Diagram")
                        .font(.custom("NunitoSans-SemiBold", size: 16))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.2))
                        )
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct ComparisonRow: View {
    let left: String
    let right: String

    var body: some View {
        HStack(spacing: 20) {
            VStack {
                Text(left)
                    .font(.custom("NunitoSans-Regular", size: 14))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.5), lineWidth: 1)
                    )
            }
            .frame(maxWidth: .infinity)

            VStack {
                Text(right)
                    .font(.custom("NunitoSans-Regular", size: 14))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.5), lineWidth: 1)
                    )
            }
            .frame(maxWidth: .infinity)
        }
    }
}

#Preview {
    SketchCardView(
        title: "AI Coding ≠ Managing Junior Devs",
        onBack: {},
        onDiagram: {}
    )
}
