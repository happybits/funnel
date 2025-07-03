import AVFoundation

/// Protocol for audio sources that can be attached to an AVAudioEngine
protocol AudioSourceProtocol {
    /// Attach the audio source to the given engine and return the output node
    func attachToEngine(_ engine: AVAudioEngine) throws -> AVAudioNode

    /// Start audio playback/capture
    func startPlayback() throws

    /// Stop audio playback/capture
    func stopPlayback()

    /// Get the output format of this audio source
    var outputFormat: AVAudioFormat { get }
}
