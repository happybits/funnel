import SwiftUI

struct TranscriptCardView: View {
    let title: String
    let transcript: String
    let duration: String
    let onBack: () -> Void
    let onAdd: () -> Void

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.576, green: 0.651, blue: 0.878),
                    Color(red: 0.404, green: 0.616, blue: 0.796),
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
                    VStack(alignment: .leading, spacing: 12) {
                        Text(duration)
                            .font(.custom("NunitoSans-Bold", size: 18))
                            .foregroundColor(.white.opacity(0.8))

                        Text(transcript)
                            .font(.custom("NunitoSans-Regular", size: 16))
                            .foregroundColor(.white)
                            .lineSpacing(6)
                            .fixedSize(horizontal: false, vertical: true)
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
                    onAdd()
                } label: {
                    HStack(spacing: 8) {
                        Text("Add")
                            .font(.custom("NunitoSans-SemiBold", size: 16))
                        Image(systemName: "mic.fill")
                            .font(.system(size: 16))
                    }
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
    TranscriptCardView(
        title: "AI Coding ≠ Managing Junior Devs",
        transcript: "Okay. So I am thinking about an idea I had for an article which is like why agentic coding with Agentic coding assistance like Claude Code, and Cursor, it feels like.\n\nAnd I've heard it described being a manager. You're gonna be a manager. It's like being a manager of humans. You've got all these AI agents.\n\nThey're just like little humans that know, human engineers, and you just have to tell them what to do, and they'll magically write code for you and then maybe they do it wrong, and you just have to give them feedback, and then it'll work.\n\nBut I don't really think that metaphor is super accurate. And but I've been trying to think of what is a better metaphor. We're like, what is this like? And, you know, is it coding with a broken or something? Or is it coding with a know how something with things with bricks? Or with. Construction equipment For what? And I",
        duration: "45s",
        onBack: {},
        onAdd: {}
    )
}
