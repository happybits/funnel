import XCTest
import AVFoundation
@testable import FunnelAI

class DebugAudioTest: XCTestCase {
    func testDebugAudioStreaming() async throws {
        print("\n🔍 === DEBUG AUDIO TEST ===")
        
        // 1. Find audio file
        let projectPath = URL(fileURLWithPath: #file)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Funnel")
            .appendingPathComponent("Funnel")
            .appendingPathComponent("sample-recording-mary-had-lamb.m4a")
        
        print("📁 Looking for audio at: \(projectPath)")
        let exists = FileManager.default.fileExists(atPath: projectPath.path)
        print("   File exists: \(exists)")
        
        guard exists else {
            XCTFail("Audio file not found")
            return
        }
        
        // 2. Load audio
        let audioFile = try AVAudioFile(forReading: projectPath)
        print("🎵 Audio loaded: \(audioFile.length) frames")
        
        // 3. Test WebSocket
        let recordingId = UUID().uuidString
        let wsURL = URL(string: "ws://localhost:8000/api/recordings/\(recordingId)/stream")!
        
        let session = URLSession(configuration: .default)
        let wsTask = session.webSocketTask(with: wsURL)
        
        var messages: [String] = []
        
        // Receive messages
        Task {
            do {
                while wsTask.state == .running {
                    let msg = try await wsTask.receive()
                    if case .string(let text) = msg {
                        print("📨 MSG: \(text)")
                        messages.append(text)
                    }
                }
            } catch {
                print("❌ Receive error: \(error)")
            }
        }
        
        // Connect and send config
        wsTask.resume()
        try await Task.sleep(nanoseconds: 100_000_000)
        
        let config = """
        {"type":"config","format":"pcm16","sampleRate":16000,"channels":1}
        """
        try await wsTask.send(.string(config))
        print("⚙️ Sent config")
        
        // Wait for ready
        try await Task.sleep(nanoseconds: 500_000_000)
        
        // Send a small chunk of real audio
        let testData = Data(repeating: 0xFF, count: 4800) // Non-zero data
        try await wsTask.send(.data(testData))
        print("🎤 Sent test chunk")
        
        // Wait
        try await Task.sleep(nanoseconds: 2_000_000_000)
        
        // Close
        wsTask.cancel(with: .normalClosure, reason: nil)
        
        print("\n📊 Results:")
        print("- Messages: \(messages.count)")
        for msg in messages {
            print("  • \(msg)")
        }
        
        XCTAssertFalse(messages.isEmpty, "Should receive messages")
    }
}