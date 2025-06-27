import SwiftUI

enum CardType {
    case bulletSummary([String])
    case diagram(Recording.Diagram?)
    case transcript(String)
    
    var shareContent: String {
        switch self {
        case .bulletSummary(let bullets):
            return bullets.joined(separator: "\n• ").prepending("• ")
        case .diagram(let diagram):
            if let diagram = diagram {
                return "\(diagram.title)\n\n\(diagram.description)\n\n\(diagram.content)"
            }
            return ""
        case .transcript(let text):
            return text
        }
    }
    
    var copyContent: String {
        return shareContent
    }
    
    var canShare: Bool {
        switch self {
        case .bulletSummary(let bullets):
            return !bullets.isEmpty
        case .diagram(let diagram):
            return diagram != nil
        case .transcript(let text):
            return !text.isEmpty
        }
    }
}

struct CardOptions: View {
    let cardType: CardType
    
    var body: some View {
        HStack(spacing: 0) {
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
    }
}

#Preview {
    CardOptions(cardType: .diagram(nil))
        .background(GradientBackground())

}
