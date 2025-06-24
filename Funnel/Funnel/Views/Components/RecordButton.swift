import SwiftUI

struct RecordButton: View {
    let action: () -> Void
    @Binding var isRecording: Bool

    var body: some View {
        Button {
            action()
        } label: {
            ZStack {
                Circle()
                    .frame(width: 57, height: 57)
                    .foregroundColor(isRecording ? .red : .white.opacity(0.8))

                if isRecording {
                    RoundedRectangle(cornerRadius: 4)
                        .frame(width: 24, height: 24)
                        .foregroundColor(.white)
                } else {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.red.opacity(0.8))
                }
            }
        }
        .frame(width: 77, height: 77)
        .glassmorphic(cornerRadius: 100, shadowRadius: 12)
    }
}

#Preview {
    ZStack {
        GradientBackground()

        VStack(spacing: 40) {
            RecordButton(action: {}, isRecording: .constant(false))
            RecordButton(action: {}, isRecording: .constant(true))
        }
    }
}
