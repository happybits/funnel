//
//  GradientBackground.swift
//  Funnel
//
//  Created by Joel Drotleff on 6/16/25.
//

import SwiftUI

struct GradientBackground: View {
    var body: some View {
        Image("GradientBackground")
            .resizable()
            .aspectRatio(contentMode: .fill)
            .ignoresSafeArea()
            .rotationEffect(.degrees(180))
    }
}

#Preview {
    GradientBackground()
}
