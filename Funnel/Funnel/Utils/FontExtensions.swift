import SwiftUI

// Font names enum for type safety
enum FunnelFont: String {
    case nunitoRegular = "Nunito-Regular"
    case nunitoBold = "Nunito-Bold"
    case nunitoExtraBold = "Nunito-ExtraBold"
    case nunitoBlack = "Nunito-Black"
    case nunitoSemiBold = "Nunito-SemiBold"
    case nunitoMedium = "Nunito-Medium"
    case nunitoLight = "Nunito-Light"
    case nunitoExtraLight = "Nunito-ExtraLight"
    // Italic variants
    case nunitoItalic = "Nunito-Italic"
    case nunitoBoldItalic = "Nunito-BoldItalic"
    case nunitoExtraBoldItalic = "Nunito-ExtraBoldItalic"
    case nunitoBlackItalic = "Nunito-BlackItalic"
    case nunitoSemiBoldItalic = "Nunito-SemiBoldItalic"
    case nunitoMediumItalic = "Nunito-MediumItalic"
    case nunitoLightItalic = "Nunito-LightItalic"
    case nunitoExtraLightItalic = "Nunito-ExtraLightItalic"
}

// Font size presets
enum FunnelFontSize: CGFloat {
    case title = 18
    case body = 15
    case small = 13
    case large = 24
}

// Custom font modifiers
extension View {
    func funnelFont(_ font: FunnelFont, size: CGFloat) -> some View {
        self.font(.custom(font.rawValue, size: size))
    }

    func funnelFont(_ font: FunnelFont, size: FunnelFontSize) -> some View {
        self.font(.custom(font.rawValue, size: size.rawValue))
    }
}

// Text style modifiers with the layered effect from the design
extension View {
    func funnelTextStyle(opacity: (CGFloat, CGFloat) = (0.1, 0.4)) -> some View {
        foregroundStyle(
            LinearGradient(
                colors: [
                    Color.white.opacity(opacity.0),
                    Color.white.opacity(opacity.1),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .shadow(color: .black.opacity(0.12), radius: 20, x: 0, y: 4)
    }

    func funnelTextOverlay(_ text: String, font: FunnelFont, size: CGFloat) -> some View {
        overlay(
            Text(text)
                .font(.custom(font.rawValue, size: size))
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
                .blendMode(.overlay)
                .shadow(color: .white, radius: 12, x: 0, y: 4)
        )
    }
}

// Convenience methods for common text styles
extension Text {
    func funnelTitle() -> some View {
        funnelFont(.nunitoExtraBold, size: .title)
            .funnelTextStyle()
    }

    func funnelBody() -> some View {
        funnelFont(.nunitoRegular, size: .body)
            .funnelTextStyle()
    }

    func funnelSmall() -> some View {
        funnelFont(.nunitoRegular, size: .small)
            .funnelTextStyle()
    }
}

// Debug helper to list available fonts
struct FontDebugView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Available Fonts:")
                .font(.headline)

            ForEach(UIFont.familyNames.sorted(), id: \.self) { family in
                VStack(alignment: .leading, spacing: 5) {
                    Text(family)
                        .font(.caption)
                        .bold()

                    ForEach(UIFont.fontNames(forFamilyName: family).sorted(), id: \.self) { font in
                        Text(font)
                            .font(.custom(font, size: 14))
                            .padding(.leading, 10)
                    }
                }
            }
        }
        .padding()
    }
}
