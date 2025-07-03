import AVFoundation

/// Production audio source that uses the device microphone
class MicrophoneAudioSource: AudioSourceProtocol {
    private var audioEngine: AVAudioEngine?

    var outputFormat: AVAudioFormat {
        // Return the input node's format when engine is attached
        if let engine = audioEngine {
            return engine.inputNode.inputFormat(forBus: 0)
        }
        // Return a default format if engine not attached
        return AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!
    }

    func attachToEngine(_ engine: AVAudioEngine) throws -> AVAudioNode {
        audioEngine = engine

        // Skip audio session setup in test environment
        let isTestEnvironment = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
        if !isTestEnvironment {
            // Setup audio session
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record)
        }

        // Return the input node (microphone)
        return engine.inputNode
    }

    func startPlayback() throws {
        // No-op for microphone - audio starts flowing when engine starts
    }

    func stopPlayback() {
        // No-op for microphone - audio stops when engine stops
    }
}
