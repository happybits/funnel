import SwiftUI

struct IndexCardView: View {
    let title: String
    let bulletPoints: [String]
    let onBack: () -> Void
    let onAdd: () -> Void

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.965, green: 0.698, blue: 0.459),
                    Color(red: 0.969, green: 0.498, blue: 0.459),
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
                        onAdd()
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
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(bulletPoints, id: \.self) { point in
                            HStack(alignment: .top, spacing: 12) {
                                Circle()
                                    .fill(Color.white.opacity(0.8))
                                    .frame(width: 6, height: 6)
                                    .offset(y: 8)

                                Text(point)
                                    .font(.custom("NunitoSans-Regular", size: 16))
                                    .foregroundColor(.white)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    .padding(.horizontal, 30)
                    .padding(.vertical, 30)
                    .frame(maxWidth: .infinity, alignment: .leading)
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
                    ForEach(["doc.text", "bubble.left", "square.grid.2x2"], id: \.self) { icon in
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
                    // Index card action
                } label: {
                    Text("Index Card")
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

#Preview {
    IndexCardView(
        title: "AI Coding ≠ Managing Junior Devs",
        bulletPoints: [
            "It's like a magic paintbrush from a glitchy video game",
            "Incredibly powerful but maddeningly unintuitive",
            "Wrong angle = nothing happens",
            "Right angle = instant transformation",
            "Requires learning alien logic, not people skills",
        ],
        onBack: {},
        onAdd: {}
    )
}
