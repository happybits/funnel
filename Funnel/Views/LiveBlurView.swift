import SwiftUI
import UIKit

struct LiveBlurView: UIViewRepresentable {
    let style: UIBlurEffect.Style
    let blurRadius: CGFloat

    init(style: UIBlurEffect.Style = .regular, blurRadius: CGFloat = 20.0) {
        self.style = style
        self.blurRadius = blurRadius
    }

    func makeUIView(context _: Context) -> LiveBlurUIView {
        let view = LiveBlurUIView(style: style, blurRadius: blurRadius)
        return view
    }

    func updateUIView(_ uiView: LiveBlurUIView, context _: Context) {
        uiView.blurRadius = blurRadius
        uiView.setNeedsDisplay()
    }
}

class LiveBlurUIView: UIView {
    private var displayLink: CADisplayLink?
    private var blurredImageView: UIImageView
    var blurRadius: CGFloat
    private let style: UIBlurEffect.Style
    private let context = CIContext(options: [.useSoftwareRenderer: false])
    private let downsampleFactor: CGFloat = 0.5 // Downsample to 50% for performance

    init(style: UIBlurEffect.Style, blurRadius: CGFloat) {
        self.style = style
        self.blurRadius = blurRadius
        blurredImageView = UIImageView()
        super.init(frame: .zero)

        setupViews()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        backgroundColor = .clear

        blurredImageView.contentMode = .scaleAspectFill
        blurredImageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(blurredImageView)

        NSLayoutConstraint.activate([
            blurredImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            blurredImageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            blurredImageView.topAnchor.constraint(equalTo: topAnchor),
            blurredImageView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()

        if window != nil {
            startCapturing()
        } else {
            stopCapturing()
        }
    }

    private func startCapturing() {
        displayLink = CADisplayLink(target: self, selector: #selector(updateBlur))
        displayLink?.preferredFramesPerSecond = 30 // Limit to 30 FPS for performance
        displayLink?.add(to: .main, forMode: .common)
    }

    private func stopCapturing() {
        displayLink?.invalidate()
        displayLink = nil
    }

    @objc private func updateBlur() {
        guard let window = window,
              let superview = superview else { return }

        // Calculate the frame in window coordinates
        let frameInWindow = superview.convert(frame, to: window)

        // Downsample for performance
        let captureSize = CGSize(
            width: frameInWindow.size.width * downsampleFactor,
            height: frameInWindow.size.height * downsampleFactor
        )

        // Capture the content behind this view
        UIGraphicsBeginImageContextWithOptions(captureSize, false, 0.0)
        guard let context = UIGraphicsGetCurrentContext() else {
            UIGraphicsEndImageContext()
            return
        }

        // Scale down the context
        context.scaleBy(x: downsampleFactor, y: downsampleFactor)

        // Translate to capture the correct area
        context.translateBy(x: -frameInWindow.origin.x, y: -frameInWindow.origin.y)

        // Hide self temporarily to capture what's behind
        let wasHidden = isHidden
        isHidden = true

        // Render the window
        window.layer.render(in: context)

        // Restore visibility
        isHidden = wasHidden

        // Get the captured image
        guard let capturedImage = UIGraphicsGetImageFromCurrentImageContext() else {
            UIGraphicsEndImageContext()
            return
        }
        UIGraphicsEndImageContext()

        // Apply blur
        if let blurredImage = applyBlur(to: capturedImage) {
            blurredImageView.image = blurredImage
        }
    }

    private func applyBlur(to image: UIImage) -> UIImage? {
        guard let ciImage = CIImage(image: image) else { return nil }

        // Apply gaussian blur with the specified radius
        let filter = CIFilter(name: "CIGaussianBlur")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        filter?.setValue(blurRadius, forKey: kCIInputRadiusKey)

        guard let outputImage = filter?.outputImage else { return nil }

        // Crop to original size to remove blur edges
        let cropped = outputImage.clampedToExtent()

        // Render the result
        guard let cgImage = context.createCGImage(cropped, from: ciImage.extent) else { return nil }

        return UIImage(cgImage: cgImage)
    }

    deinit {
        stopCapturing()
    }
}

struct LiveBlurPreview: View {
    @State private var selectedImageIndex = 0
    @State private var blurRadius: CGFloat = 20

    let imageIds = [237, 239, 240, 241, 244] // Specific Lorem Picsum image IDs

    var body: some View {
        ZStack {
            // Background image from Lorem Picsum
            AsyncImage(url: URL(string: "https://picsum.photos/id/\(imageIds[selectedImageIndex])/400/800")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
            }
            .ignoresSafeArea()

            // Live blur overlay
            LiveBlurView(blurRadius: blurRadius)
                .frame(width: 300, height: 200)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)

            // Controls
            VStack {
                Spacer()

                VStack(spacing: 16) {
                    // Blur radius slider
                    VStack(alignment: .leading) {
                        Text("Blur Radius: \(Int(blurRadius))")
                            .foregroundColor(.white)
                            .font(.caption)

                        Slider(value: $blurRadius, in: 0 ... 50)
                            .accentColor(.white)
                    }

                    // Image picker buttons
                    HStack(spacing: 12) {
                        ForEach(0 ..< 5) { index in
                            Button {
                                selectedImageIndex = index
                            } label: {
                                Text("\(index + 1)")
                                    .font(.caption)
                                    .foregroundColor(selectedImageIndex == index ? .black : .white)
                                    .frame(width: 32, height: 32)
                                    .background(
                                        Circle()
                                            .fill(selectedImageIndex == index ? Color.white : Color.white.opacity(0.2))
                                    )
                            }
                        }
                    }
                }
                .padding()
                .background(Color.black.opacity(0.7))
                .cornerRadius(12)
                .padding()
            }
        }
    }
}

#Preview("Live Blur") {
    LiveBlurPreview()
}

#Preview("Glassmorphic") {
    struct GlassmorphicPreview: View {
        @State private var selectedImageIndex = 0
        @State private var blurRadius: CGFloat = 20

        let imageIds = [237, 239, 240, 241, 244]

        var body: some View {
            ZStack {
                // Background image
                AsyncImage(url: URL(string: "https://picsum.photos/id/\(imageIds[selectedImageIndex])/400/800")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                }
                .ignoresSafeArea()

                // Glassmorphic card with content
                VStack(spacing: 16) {
                    Text("Glassmorphic Card")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Text("This combines live blur with glassmorphic styling")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)

                    Divider()
                        .background(Color.white.opacity(0.3))
                        .padding(.vertical, 8)

                    VStack(spacing: 12) {
                        Label("Real-time blur", systemImage: "wand.and.rays")
                        Label("Gradient overlay", systemImage: "gradient")
                        Label("Glass borders", systemImage: "square.stack.3d.up")
                    }
                    .font(.callout)
                    .foregroundColor(.white.opacity(0.8))
                }
                .padding(24)
                .frame(width: 320)
                .liveGlassmorphic(
                    cornerRadius: 20,
                    blurRadius: blurRadius,
                    gradientOpacity: (0.1, 0.4)
                )

                // Controls
                VStack {
                    Spacer()

                    VStack(spacing: 16) {
                        // Blur radius slider
                        VStack(alignment: .leading) {
                            Text("Blur Radius: \(Int(blurRadius))")
                                .foregroundColor(.white)
                                .font(.caption)

                            Slider(value: $blurRadius, in: 0 ... 50)
                                .accentColor(.white)
                        }

                        // Image picker
                        HStack(spacing: 12) {
                            ForEach(0 ..< 5) { index in
                                Button {
                                    selectedImageIndex = index
                                } label: {
                                    Text("\(index + 1)")
                                        .font(.caption)
                                        .foregroundColor(selectedImageIndex == index ? .black : .white)
                                        .frame(width: 32, height: 32)
                                        .background(
                                            Circle()
                                                .fill(selectedImageIndex == index ? Color.white : Color.white.opacity(0.2))
                                        )
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(12)
                    .padding()
                }
            }
        }
    }

    return GlassmorphicPreview()
}
