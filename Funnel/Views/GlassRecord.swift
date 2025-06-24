import SwiftUI

enum BackgroundType: CaseIterable {
    case image1
    case image2
    case image3
    case white
    case gray
    
    var label: String {
        switch self {
        case .image1: return "Image 1"
        case .image2: return "Image 2"
        case .image3: return "Image 3"
        case .white: return "White"
        case .gray: return "Gray"
        }
    }
}

struct GlassRecord: View {
    @EnvironmentObject var debugSettings: DebugSettings
    @State private var isPressed = false
    @State private var backgroundType: BackgroundType = .image1
    
    var body: some View {
        ZStack {
            // Dynamic background
            switch backgroundType {
            case .image1:
                AsyncImage(url: URL(string: "https://picsum.photos/400/800?random=1")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .ignoresSafeArea()
                } placeholder: {
                    Color.gray
                        .ignoresSafeArea()
                }
            case .image2:
                AsyncImage(url: URL(string: "https://picsum.photos/400/800?random=2")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .ignoresSafeArea()
                } placeholder: {
                    Color.gray
                        .ignoresSafeArea()
                }
            case .image3:
                AsyncImage(url: URL(string: "https://picsum.photos/400/800?random=3")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .ignoresSafeArea()
                } placeholder: {
                    Color.gray
                        .ignoresSafeArea()
                }
            case .white:
                Color.white
                    .ignoresSafeArea()
            case .gray:
                Color.gray
                    .ignoresSafeArea()
            }
            
            // Glass morphic record button - exact Figma specs
            Button {
                // Action here
            } label: {
                ZStack {
                    // Red stop square with rounded corners
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(red: 1, green: 59/255, blue: 48/255).opacity(0.8))
                        .frame(width: 30, height: 30)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(stops: [
                                            .init(color: .white, location: 0),
                                            .init(color: .white.opacity(0), location: 0.434),
                                            .init(color: .white, location: 1)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                }
                .frame(width: 60, height: 60)
                .padding(10)
                .liveGlassmorphicCell(
                    cornerRadius: 40,
                    gradientOpacity: (0.1, 0.4)
                )
                .shadow(color: .black.opacity(0.2), radius: 16, x: 0, y: 8) // Additional drop shadow
                .scaleEffect(isPressed ? 0.95 : 1.0)
            }
            .buttonStyle(PlainButtonStyle())
            .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity) {
            } onPressingChanged: { pressing in
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = pressing
                }
            }
            
            // Background picker and blur toggle
            VStack {
                HStack {
                    ForEach(BackgroundType.allCases, id: \.self) { bgType in
                        Button {
                            withAnimation {
                                backgroundType = bgType
                            }
                        } label: {
                            Text(bgType.label)
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(backgroundType == bgType ? Color.black.opacity(0.3) : Color.white.opacity(0.3))
                                )
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding()
                
                Spacer()
                
                // Blur toggle checkbox
                HStack {
                    Toggle("Blur Effect", isOn: $debugSettings.blurEnabled)
                        .toggleStyle(CheckboxToggleStyle())
                        .foregroundColor(.white)
                        .padding()
                        .background(
                            Capsule()
                                .fill(Color.black.opacity(0.3))
                        )
                }
                .padding()
            }
        }
    }
}

#Preview {
    GlassRecord()
        .environmentObject(DebugSettings())
}