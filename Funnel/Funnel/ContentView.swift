//
//  ContentView.swift
//  Funnel
//
//  Created by Joel Drotleff on 6/16/25.
//

import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var appState: AppState
    @Query private var recordings: [Recording]
    @State private var showFontDebug = false

    var body: some View {
        ZStack {
            if showFontDebug {
                // Temporary debug view - triple tap to toggle
                VStack {
                    FontDebugView()
                        .onTapGesture(count: 3) {
                            showFontDebug = false
                        }
                }
            } else {
                switch appState.navigationState {
                case .recording:
                    NewRecordingView()
                        .transition(.opacity)
                        .onTapGesture(count: 3) {
                            showFontDebug = true
                        }

                case .processing:
                    ProcessingView()
                        .transition(.move(edge: .bottom))

                case let .viewing(recording):
                    ProcessedRecordingView(recording: recording)
                        .transition(.move(edge: .bottom))
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: appState.navigationState)
        .onAppear {
            // Ensure AppState has the correct model context
            appState.modelContext = modelContext
        }
    }
}

#Preview {
    ContentView()
        .funnelPreviewEnvironment()
}
