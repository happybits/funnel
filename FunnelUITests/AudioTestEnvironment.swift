import Foundation
import AVFoundation

class AudioTestEnvironment {
    private let engine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private var audioFile: AVAudioFile?
    
    func setupTestAudioEnvironment() {
        // Note: BlackHole must be installed and configured as system audio input
        // This can be done via macOS System Preferences -> Sound -> Input
        // Select "BlackHole 2ch" as the input device
        
        // Attach and connect the player node
        engine.attach(playerNode)
        engine.connect(playerNode, to: engine.mainMixerNode, format: nil)
        
        // Start the audio engine
        do {
            try engine.start()
        } catch {
            print("Failed to start audio engine: \(error)")
        }
    }
    
    func generateTestTone(frequency: Float = 440.0, duration: Double = 5.0) {
        let sampleRate = 44100.0
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            print("Failed to create audio buffer")
            return
        }
        
        buffer.frameLength = frameCount
        guard let channelData = buffer.floatChannelData?[0] else { return }
        
        // Generate sine wave
        for i in 0..<Int(frameCount) {
            channelData[i] = Float(sin(2.0 * .pi * Double(frequency) * Double(i) / sampleRate)) * 0.5
        }
        
        // Schedule and play the buffer
        playerNode.scheduleBuffer(buffer, at: nil, options: .loops)
        playerNode.play()
    }
    
    func playTestAudioFile(atPath path: String) {
        do {
            let url = URL(fileURLWithPath: path)
            audioFile = try AVAudioFile(forReading: url)
            
            guard let file = audioFile else { return }
            
            playerNode.scheduleFile(file, at: nil, completionHandler: nil)
            playerNode.play()
        } catch {
            print("Failed to play audio file: \(error)")
        }
    }
    
    func playBundledTestAudio() {
        // Play the sample audio file from the test bundle
        guard let bundle = Bundle(for: AudioTestEnvironment.self).path(forResource: "test-audio", ofType: "m4a") else {
            print("Test audio file not found in bundle")
            return
        }
        
        playTestAudioFile(atPath: bundle)
    }
    
    func stopAudio() {
        playerNode.stop()
    }
    
    func cleanup() {
        stopAudio()
        engine.stop()
    }
}

// MARK: - Audio Test Utilities

extension AudioTestEnvironment {
    
    // Generate speech-like audio patterns
    func generateSpeechPattern(duration: Double = 5.0) {
        let sampleRate = 44100.0
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            return
        }
        
        buffer.frameLength = frameCount
        guard let channelData = buffer.floatChannelData?[0] else { return }
        
        // Generate more complex waveform simulating speech
        for i in 0..<Int(frameCount) {
            let time = Double(i) / sampleRate
            
            // Mix multiple frequencies to simulate speech
            var sample: Float = 0
            
            // Fundamental frequency (varies over time)
            let fundamental = 100.0 + 50.0 * sin(2.0 * .pi * 0.5 * time)
            sample += Float(sin(2.0 * .pi * fundamental * time)) * 0.3
            
            // Add harmonics
            sample += Float(sin(2.0 * .pi * fundamental * 2 * time)) * 0.2
            sample += Float(sin(2.0 * .pi * fundamental * 3 * time)) * 0.1
            
            // Add some noise for realism
            sample += Float.random(in: -0.05...0.05)
            
            // Apply envelope (simulate words/pauses)
            let envelope = Float(sin(2.0 * .pi * 2.0 * time) * 0.5 + 0.5)
            channelData[i] = sample * envelope * 0.5
        }
        
        playerNode.scheduleBuffer(buffer, at: nil, options: .loops)
        playerNode.play()
    }
    
    // Check if BlackHole is available
    static func isBlackHoleAvailable() -> Bool {
        let devices = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInMicrophone, .externalUnknown],
            mediaType: .audio,
            position: .unspecified
        ).devices
        
        return devices.contains { device in
            device.localizedName.lowercased().contains("blackhole")
        }
    }
    
    // Helper to ensure audio routing through BlackHole
    func configureBlackHoleRouting() {
        #if targetEnvironment(simulator)
        // In simulator, we rely on system audio preferences
        print("Note: Ensure BlackHole is selected as input device in System Preferences")
        #else
        // On real device testing, this won't apply
        print("Running on real device - using device microphone")
        #endif
    }
}