//
//  FunnelApp.swift
//  Funnel
//
//  Created by Joel Drotleff on 6/16/25.
//

import SwiftData
import SwiftUI

@main
struct FunnelApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Recording.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    @StateObject private var appState: AppState

    init() {
        // Create AppState with the model container's mainContext
        let container = Self.createModelContainer()
        _appState = StateObject(wrappedValue: AppState(modelContext: container.mainContext))
        sharedModelContainer = container
    }

    private static func createModelContainer() -> ModelContainer {
        let schema = Schema([Recording.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .preferredColorScheme(.dark)
                .colorScheme(.light)
        }
        .modelContainer(sharedModelContainer)
    }
}
