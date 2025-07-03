import AVFoundation

/// Test audio source that plays an audio file through the engine
class FilePlaybackAudioSource: AudioSourceProtocol {
    private let audioFileURL: URL
    private var playerNode: AVAudioPlayerNode?
    private var audioFile: AVAudioFile?

    init(audioFileURL: URL) {
        self.audioFileURL = audioFileURL
    }

    var outputFormat: AVAudioFormat {
        // Return the audio file's format
        do {
            let file = try AVAudioFile(forReading: audioFileURL)
            return file.processingFormat
        } catch {
            print("FilePlaybackAudioSource: Failed to read audio file format: \(error)")
            return AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!
        }
    }

    func attachToEngine(_ engine: AVAudioEngine) throws -> AVAudioNode {
        // Load the audio file
        audioFile = try AVAudioFile(forReading: audioFileURL)

        // Create and attach player node
        let player = AVAudioPlayerNode()
        playerNode = player
        engine.attach(player)

        print("FilePlaybackAudioSource: Attached player node for \(audioFileURL.lastPathComponent)")
        print("   Format: \(audioFile!.processingFormat)")
        print("   Duration: \(Double(audioFile!.length) / audioFile!.processingFormat.sampleRate) seconds")

        return player
    }

    func startPlayback() throws {
        guard let playerNode = playerNode,
              let audioFile = audioFile
        else {
            throw NSError(domain: "FilePlaybackAudioSource", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "Player not initialized"])
        }

        // Schedule the entire file for playback
        playerNode.scheduleFile(audioFile, at: nil) { [weak self] in
            print("FilePlaybackAudioSource: Playback completed")
            self?.handlePlaybackCompletion()
        }

        // Start playback
        playerNode.play()
        print("FilePlaybackAudioSource: Started playback")
    }

    func stopPlayback() {
        playerNode?.stop()
        print("FilePlaybackAudioSource: Stopped playback")
    }

    private func handlePlaybackCompletion() {
        // Could notify delegates or post notifications here if needed
        // For now, just log completion
        DispatchQueue.main.async {
            print("FilePlaybackAudioSource: File playback finished")
        }
    }
}
