import SwiftUI

enum CardType {
    case bulletSummary([String])
    case diagram(Recording.Diagram?)
    case transcript(String)
    case thoughtProvokingQuestions([String])

    var shareContent: String {
        switch self {
        case let .bulletSummary(bullets):
            return bullets.joined(separator: "\n• ").prepending("• ")
        case let .diagram(diagram):
            if let diagram = diagram {
                return "\(diagram.title)\n\n\(diagram.description)\n\n\(diagram.content)"
            }
            return ""
        case let .transcript(text):
            return text
        case let .thoughtProvokingQuestions(questions):
            return questions.joined(separator: "\n\n")
        }
    }

    var copyContent: String {
        return shareContent
    }

    var canShare: Bool {
        switch self {
        case let .bulletSummary(bullets):
            return !bullets.isEmpty
        case let .diagram(diagram):
            return diagram != nil
        case let .transcript(text):
            return !text.isEmpty
        case let .thoughtProvokingQuestions(questions):
            return !questions.isEmpty
        }
    }
}

struct CardOptions: View {
    let cardType: CardType

    var body: some View {
        HStack(spacing: -16) {
            Button {
                UIPasteboard.general.string = cardType.copyContent
            } label: {
                Image("copy-btn")
            }
            .disabled(!cardType.canShare)
            .opacity(cardType.canShare ? 1.0 : 0.5)

            if cardType.canShare {
                ShareLink(item: cardType.shareContent) {
                    Image("share-btn")
                }
            } else {
                Image("share-btn")
            }
        }
        .padding(.leading, -8)
    }
}

#Preview {
    CardOptions(cardType: .diagram(nil))
        .background(GradientBackground())
}
