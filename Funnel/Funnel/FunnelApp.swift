import SwiftData
import SwiftUI

@main
struct FunnelApp: App {
    @StateObject private var debugSettings = DebugSettings()
    @StateObject private var audioRecorderManager = AudioRecorderManager()
    
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

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
                .colorScheme(.light)
                .environmentObject(debugSettings)
                .environmentObject(audioRecorderManager)
        }
        .modelContainer(sharedModelContainer)
    }
}
