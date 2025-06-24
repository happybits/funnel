import SwiftUI

struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                .foregroundColor(configuration.isOn ? .white : .white.opacity(0.7))
                .onTapGesture {
                    configuration.isOn.toggle()
                }
            configuration.label
        }
    }
}