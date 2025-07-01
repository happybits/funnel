import AVFoundation
import Foundation
@testable import FunnelAI

/// Direct WebSocket streamer that bypasses AudioRecorderManager for testing
class DirectWebSocketStreamer {
    private let apiClient: APIClient
    private var webSocket: URLSessionWebSocketTask?
    private var urlSession: URLSession?
    private let recordingId: String

    init(recordingId: String = UUID().uuidString) {
        apiClient = APIClient.shared
        self.recordingId = recordingId
    }

    /// Stream audio file to server via WebSocket
    func streamAudioFile(_ fileURL: URL) async throws {
        print("DirectWebSocketStreamer: Starting stream for recording \(recordingId)")

        // Load and convert audio to PCM
        let pcmData = try await loadAndConvertToPCM(fileURL: fileURL)
        print("DirectWebSocketStreamer: Loaded \(pcmData.count) bytes of PCM data")

        // Create WebSocket connection
        let config = URLSessionConfiguration.default
        urlSession = URLSession(configuration: config)

        guard let wsURL = apiClient.webSocketURL(for: "/api/recordings/\(recordingId)/stream") else {
            throw APIError.invalidURL
        }

        webSocket = urlSession?.webSocketTask(with: wsURL)
        webSocket?.resume()

        // Start receiving messages in background
        Task {
            await receiveMessages()
        }

        // Wait for connection
        try await Task.sleep(nanoseconds: 200_000_000) // 200ms

        // Send configuration
        let configMessage: [String: Any] = [
            "type": "config",
            "format": "pcm16",
            "sampleRate": 16000,
            "channels": 1,
        ]

        let configData = try JSONSerialization.data(withJSONObject: configMessage)
        let configString = String(data: configData, encoding: .utf8)!
        try await webSocket?.send(.string(configString))

        print("DirectWebSocketStreamer: Sent config, waiting for ready...")
        try await Task.sleep(nanoseconds: 300_000_000) // 300ms

        // Stream audio in chunks
        let chunkSize = 16000 // 1 second at 16kHz
        var offset = 0

        while offset < pcmData.count {
            let endIndex = min(offset + chunkSize, pcmData.count)
            let chunk = pcmData[offset ..< endIndex]

            try await webSocket?.send(.data(chunk))

            offset = endIndex

            // Small delay between chunks to simulate real-time streaming
            try await Task.sleep(nanoseconds: 50_000_000) // 50ms
        }

        print("DirectWebSocketStreamer: Finished streaming audio")

        // Wait a bit for final transcripts
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds

        // Close WebSocket
        webSocket?.cancel(with: .normalClosure, reason: nil)

        // Wait for connection to close
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms
    }

    /// Finalize recording and get processed data
    func finalizeRecording() async throws -> ProcessedRecording {
        print("DirectWebSocketStreamer: Finalizing recording \(recordingId)")

        let apiService = FunnelAPIService.shared
        return try await apiService.finalizeRecording(recordingId: recordingId)
    }

    /// Load audio file and convert to PCM format expected by server
    private func loadAndConvertToPCM(fileURL: URL) async throws -> Data {
        return try await Task {
            let audioFile = try AVAudioFile(forReading: fileURL)

            // Target format: 16kHz mono 16-bit PCM
            guard let outputFormat = AVAudioFormat(
                commonFormat: .pcmFormatInt16,
                sampleRate: 16000,
                channels: 1,
                interleaved: false
            ) else {
                throw NSError(domain: "DirectWebSocketStreamer", code: 1,
                              userInfo: [NSLocalizedDescriptionKey: "Failed to create output format"])
            }

            // Create converter
            guard let converter = AVAudioConverter(from: audioFile.processingFormat, to: outputFormat) else {
                throw NSError(domain: "DirectWebSocketStreamer", code: 2,
                              userInfo: [NSLocalizedDescriptionKey: "Failed to create converter"])
            }

            // Read entire file
            let frameCount = AVAudioFrameCount(audioFile.length)
            guard let inputBuffer = AVAudioPCMBuffer(pcmFormat: audioFile.processingFormat,
                                                     frameCapacity: frameCount)
            else {
                throw NSError(domain: "DirectWebSocketStreamer", code: 3,
                              userInfo: [NSLocalizedDescriptionKey: "Failed to create input buffer"])
            }

            try audioFile.read(into: inputBuffer)

            // Create output buffer
            let outputFrameCapacity = converter.outputFormat.sampleRate * Double(frameCount) / audioFile.processingFormat.sampleRate
            guard let outputBuffer = AVAudioPCMBuffer(
                pcmFormat: outputFormat,
                frameCapacity: AVAudioFrameCount(outputFrameCapacity)
            ) else {
                throw NSError(domain: "DirectWebSocketStreamer", code: 4,
                              userInfo: [NSLocalizedDescriptionKey: "Failed to create output buffer"])
            }

            // Convert
            var error: NSError?
            let status = converter.convert(to: outputBuffer, error: &error) { _, outStatus in
                outStatus.pointee = .haveData
                return inputBuffer
            }

            guard status != .error, error == nil else {
                throw error ?? NSError(domain: "DirectWebSocketStreamer", code: 5,
                                       userInfo: [NSLocalizedDescriptionKey: "Conversion failed"])
            }

            // Extract PCM data
            return extractPCMData(from: outputBuffer)
        }.value
    }

    /// Extract raw PCM data from audio buffer
    private func extractPCMData(from buffer: AVAudioPCMBuffer) -> Data {
        let frameLength = Int(buffer.frameLength)
        var data = Data(capacity: frameLength * 2) // 2 bytes per 16-bit sample

        guard let samples = buffer.int16ChannelData?[0] else {
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

    /// Receive messages from WebSocket (runs in background)
    private func receiveMessages() async {
        guard let webSocket = webSocket else { return }

        do {
            while true {
                let message = try await webSocket.receive()

                switch message {
                case let .string(text):
                    print("DirectWebSocketStreamer: Received: \(text)")
                case let .data(data):
                    print("DirectWebSocketStreamer: Received data: \(data.count) bytes")
                @unknown default:
                    break
                }
            }
        } catch {
            // Connection closed or error - this is expected
            if (error as NSError).code != 57 { // 57 = Socket is not connected
                print("DirectWebSocketStreamer: WebSocket error: \(error)")
            }
        }
    }
}
