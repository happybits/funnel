# Swift integration testing for PCM audio streaming over WebSocket

The challenge of testing real-time PCM audio streaming from Swift to a Deno server requires careful orchestration of audio processing, network communication, and test validation. Based on comprehensive research of current Swift audio APIs, WebSocket implementations, and testing patterns, the optimal approach combines AVFoundation for audio handling, Starscream for reliable WebSocket communication, and XCTest's modern async/await patterns for integration testing.

## Audio processing with AVFoundation

Swift provides robust audio file loading and PCM conversion through AVFoundation, which supports all common formats including MP3, WAV, AAC, and FLAC. The framework offers both high-level and low-level approaches, with AVAudioFile providing the simplest path for most use cases.

```swift
// Load and convert audio to PCM format
class AudioConverter {
    func loadAndConvertToPCM(url: URL) throws -> Data {
        let audioFile = try AVAudioFile(forReading: url)
        
        // Define target PCM format - 16kHz mono 16-bit is standard for transcription
        let outputFormat = AVAudioFormat(
            commonFormat: .pcmFormatInt16, 
            sampleRate: 16000, 
            channels: 1, 
            interleaved: false
        )!
        
        let converter = AVAudioConverter(
            from: audioFile.processingFormat, 
            to: outputFormat
        )!
        
        // Process entire file
        let frameCount = AVAudioFrameCount(audioFile.length)
        let inputBuffer = AVAudioPCMBuffer(
            pcmFormat: audioFile.processingFormat, 
            frameCapacity: frameCount
        )!
        
        try audioFile.read(into: inputBuffer)
        
        let outputBuffer = AVAudioPCMBuffer(
            pcmFormat: outputFormat, 
            frameCapacity: converter.outputFrameCapacity(sourceFrameCount: frameCount)
        )!
        
        var error: NSError?
        converter.convert(to: outputBuffer, error: &error) { _, outStatus in
            outStatus.pointee = .haveData
            return inputBuffer
        }
        
        return extractPCMData(from: outputBuffer)
    }
    
    private func extractPCMData(from buffer: AVAudioPCMBuffer) -> Data {
        let frameLength = Int(buffer.frameLength)
        var data = Data(capacity: frameLength * 2) // 2 bytes per 16-bit sample
        
        let samples = UnsafeBufferPointer(
            start: buffer.int16ChannelData![0], 
            count: frameLength
        )
        
        for sample in samples {
            data.append(contentsOf: withUnsafeBytes(of: sample.littleEndian) { Array($0) })
        }
        
        return data
    }
}
```

The audio format configuration is critical for transcription services. Most accept 16-bit PCM at 16kHz sample rate in mono configuration. For streaming efficiency, **300ms chunks have proven optimal** in production implementations, balancing latency with network efficiency. This translates to 9,600 bytes per chunk at 16kHz mono 16-bit PCM.

## WebSocket implementation choices

While iOS 13+ includes native URLSessionWebSocketTask, production experience reveals significant reliability issues. Starscream emerges as the recommended choice despite being a third-party dependency, offering battle-tested stability and comprehensive RFC 6455 compliance.

```swift
import Starscream

class AudioStreamingClient: WebSocketDelegate {
    private var socket: WebSocket?
    private let chunkDuration: TimeInterval = 0.3 // 300ms chunks
    private var audioBuffer = Data()
    
    func connect(to url: URL) {
        var request = URLRequest(url: url)
        request.timeoutInterval = 5
        
        socket = WebSocket(request: request)
        socket?.delegate = self
        socket?.connect()
    }
    
    func streamAudioFile(at url: URL) throws {
        let pcmData = try AudioConverter().loadAndConvertToPCM(url: url)
        
        // Calculate chunk size based on format
        let sampleRate = 16000
        let bytesPerSample = 2
        let chunkSize = Int(Double(sampleRate) * chunkDuration) * bytesPerSample
        
        // Stream in chunks
        for chunkStart in stride(from: 0, to: pcmData.count, by: chunkSize) {
            let chunkEnd = min(chunkStart + chunkSize, pcmData.count)
            let chunk = pcmData[chunkStart..<chunkEnd]
            
            sendAudioChunk(chunk)
            
            // Simulate real-time playback timing
            Thread.sleep(forTimeInterval: chunkDuration)
        }
    }
    
    private func sendAudioChunk(_ data: Data) {
        // Add frame header for server processing
        var frame = Data()
        frame.append(contentsOf: withUnsafeBytes(of: UInt32(data.count).bigEndian) { Array($0) })
        frame.append(data)
        
        socket?.write(data: frame)
    }
}
```

For binary data transmission, proper message framing ensures reliable chunk processing. Including metadata like sequence numbers and timestamps enables the server to handle network jitter and packet reordering.

## Integration testing with XCTest

Modern XCTest async/await patterns provide clean integration testing for streaming scenarios. The framework's asynchronous capabilities align well with WebSocket communication patterns.

```swift
class AudioStreamingIntegrationTests: XCTestCase {
    var streamingClient: AudioStreamingClient!
    var testServer: URL!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Connect to local Deno server
        testServer = URL(string: "ws://localhost:8080/audio")!
        streamingClient = AudioStreamingClient()
        
        // Wait for connection
        let connected = await withCheckedContinuation { continuation in
            streamingClient.onConnected = {
                continuation.resume(returning: true)
            }
            streamingClient.connect(to: testServer)
        }
        
        XCTAssertTrue(connected)
    }
    
    func testEndToEndAudioStreaming() async throws {
        // Load test audio file
        let testBundle = Bundle(for: type(of: self))
        let audioURL = testBundle.url(forResource: "test_audio", withExtension: "wav")!
        
        // Set up transcription result expectation
        let transcriptionExpectation = XCTestExpectation(description: "Receive transcription")
        var receivedTranscription: String?
        
        streamingClient.onTranscriptionReceived = { transcription in
            receivedTranscription = transcription
            transcriptionExpectation.fulfill()
        }
        
        // Stream audio file
        try streamingClient.streamAudioFile(at: audioURL)
        
        // Wait for transcription with timeout
        await fulfillment(of: [transcriptionExpectation], timeout: 30.0)
        
        // Validate results
        XCTAssertNotNil(receivedTranscription)
        XCTAssertTrue(receivedTranscription!.contains("expected text"))
    }
    
    func testStreamingPerformance() async throws {
        let metrics = StreamingMetrics()
        streamingClient.metricsCollector = metrics
        
        measure {
            try! streamingClient.streamAudioFile(at: testAudioURL)
        }
        
        // Validate performance metrics
        XCTAssertLessThan(metrics.averageChunkLatency, 0.05) // 50ms max latency
        XCTAssertGreaterThan(metrics.throughput, 128_000) // 128kbps minimum
    }
}
```

Test organization benefits from dedicated fixtures and proper lifecycle management. Audio test files should represent real-world scenarios with various formats, durations, and content types.

## Streaming simulation and timing

Realistic streaming simulation requires careful attention to timing and buffer management. The audio streaming should match real-time playback speed to accurately test server-side processing.

```swift
class RealTimeAudioStreamer {
    private let audioEngine = AVAudioEngine()
    private var webSocket: WebSocket?
    
    func streamInRealTime(from url: URL) throws {
        let audioFile = try AVAudioFile(forReading: url)
        let playerNode = AVAudioPlayerNode()
        
        audioEngine.attach(playerNode)
        audioEngine.connect(playerNode, to: audioEngine.mainMixerNode, format: audioFile.processingFormat)
        
        // Install tap to capture audio as it plays
        let tapFormat = AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: 16000, channels: 1, interleaved: false)!
        
        audioEngine.mainMixerNode.installTap(
            onBus: 0,
            bufferSize: AVAudioFrameCount(16000 * 0.3), // 300ms chunks
            format: tapFormat
        ) { [weak self] buffer, _ in
            let pcmData = self?.extractPCMData(from: buffer) ?? Data()
            self?.webSocket?.write(data: pcmData)
        }
        
        try audioEngine.start()
        playerNode.play()
        
        playerNode.scheduleFile(audioFile, at: nil) {
            // Playback completed
            self.cleanup()
        }
    }
}
```

## Best practices and optimization

**Buffer management** proves critical for streaming performance. Pre-allocating buffers and using object pools reduces memory pressure and allocation overhead. For integration tests, configure audio sessions with low-latency settings:

```swift
try AVAudioSession.sharedInstance().setCategory(.playAndRecord, options: [.defaultToSpeaker])
try AVAudioSession.sharedInstance().setPreferredIOBufferDuration(0.005) // 5ms buffer
```

**Error handling** must account for network interruptions, format mismatches, and server errors. Integration tests should validate graceful degradation under adverse conditions:

```swift
func testNetworkInterruption() async throws {
    // Start streaming
    Task {
        try await streamingClient.streamAudioFile(at: testAudioURL)
    }
    
    // Simulate network interruption
    await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
    networkSimulator.disconnect()
    
    // Verify reconnection
    await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
    XCTAssertTrue(streamingClient.isConnected)
    XCTAssertTrue(streamingClient.didResumeStreaming)
}
```

**Performance considerations** include threading, with audio processing requiring dedicated high-priority queues. Never perform audio operations on the main thread. Memory usage requires monitoring, especially for long-duration streams.

## Conclusion

Building robust integration tests for PCM audio streaming over WebSocket requires coordinating multiple Swift frameworks and careful attention to real-time constraints. The combination of AVFoundation for audio processing, Starscream for reliable WebSocket communication, and XCTest's modern async patterns provides a solid foundation. Key success factors include proper audio format configuration (16kHz mono 16-bit PCM), optimal chunk sizing (300ms), realistic timing simulation, and comprehensive error handling. This approach enables thorough validation of the complete audio streaming pipeline from Swift client to Deno server, ensuring production-ready quality.