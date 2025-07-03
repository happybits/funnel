import AVFoundation

extension AVAudioFile {
    /// Load audio file and convert to 16-bit PCM at 16kHz mono
    func convertToPCM() throws -> Data {
        // Define target format: 16kHz mono 16-bit PCM
        guard let outputFormat = AVAudioFormat(
            commonFormat: .pcmFormatInt16,
            sampleRate: 16000,
            channels: 1,
            interleaved: false
        ) else {
            throw NSError(domain: "AudioTest", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create output format"])
        }

        // Create converter
        guard let converter = AVAudioConverter(from: processingFormat, to: outputFormat) else {
            throw NSError(domain: "AudioTest", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to create converter"])
        }

        // Read entire file
        let frameCount = AVAudioFrameCount(length)
        guard let inputBuffer = AVAudioPCMBuffer(pcmFormat: processingFormat, frameCapacity: frameCount) else {
            throw NSError(domain: "AudioTest", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to create input buffer"])
        }

        try read(into: inputBuffer)

        // Create output buffer
        let outputFrameCapacity = converter.outputFormat.sampleRate * Double(frameCount) / processingFormat.sampleRate
        guard let outputBuffer = AVAudioPCMBuffer(
            pcmFormat: outputFormat,
            frameCapacity: AVAudioFrameCount(outputFrameCapacity)
        ) else {
            throw NSError(domain: "AudioTest", code: 4, userInfo: [NSLocalizedDescriptionKey: "Failed to create output buffer"])
        }

        // Convert
        var error: NSError?
        let status = converter.convert(to: outputBuffer, error: &error) { _, outStatus in
            outStatus.pointee = .haveData
            return inputBuffer
        }

        guard status != .error, error == nil else {
            throw error ?? NSError(domain: "AudioTest", code: 5, userInfo: [NSLocalizedDescriptionKey: "Conversion failed"])
        }

        // Extract PCM data
        return outputBuffer.extractPCMData()
    }
}

extension AVAudioPCMBuffer {
    /// Extract raw PCM data from audio buffer
    func extractPCMData() -> Data {
        let frameLength = Int(self.frameLength)
        var data = Data(capacity: frameLength * 2) // 2 bytes per 16-bit sample

        guard let samples = int16ChannelData?[0] else {
            return data
        }

        let samplePointer = UnsafeBufferPointer(start: samples, count: frameLength)

        for sample in samplePointer {
            // Convert to little endian
            let littleEndianSample = sample.littleEndian
            withUnsafeBytes(of: littleEndianSample) { bytes in
                data.append(contentsOf: bytes)
            }
        }

        return data
    }
}
