import Foundation
import Network

class AudioStreamingMockServer {
    private var listener: NWListener?
    private var connections: [NWConnection] = []
    private let port: UInt16
    private let queue = DispatchQueue(label: "MockWebSocketServer")

    // Callbacks for test assertions
    var onConnection: ((NWConnection) -> Void)?
    var onAudioReceived: ((Data) -> Void)?
    var onMessageReceived: ((Data) -> Void)?
    var onTextMessageReceived: ((String) -> Void)?

    // Track received data
    private(set) var totalBytesReceived: Int = 0
    private(set) var messageCount: Int = 0
    private(set) var isRunning: Bool = false

    init(port: UInt16 = 8080) {
        self.port = port
    }

    func startServer() {
        let parameters = NWParameters.tcp
        parameters.allowLocalEndpointReuse = true

        // Configure for WebSocket
        let wsOptions = NWProtocolWebSocket.Options()
        parameters.defaultProtocolStack.applicationProtocols.insert(wsOptions, at: 0)

        do {
            listener = try NWListener(using: parameters, on: NWEndpoint.Port(integerLiteral: port))

            listener?.newConnectionHandler = { [weak self] connection in
                self?.handleNewConnection(connection)
            }

            listener?.stateUpdateHandler = { [weak self] state in
                switch state {
                case .ready:
                    self?.isRunning = true
                    print("Mock WebSocket server listening on port \(self?.port ?? 0)")
                case let .failed(error):
                    print("Mock server failed: \(error)")
                    self?.isRunning = false
                case .cancelled:
                    self?.isRunning = false
                default:
                    break
                }
            }

            listener?.start(queue: queue)
        } catch {
            print("Failed to create mock server: \(error)")
        }
    }

    func stopServer() {
        isRunning = false
        connections.forEach { $0.cancel() }
        connections.removeAll()
        listener?.cancel()
        listener = nil
        totalBytesReceived = 0
        messageCount = 0
    }

    private func handleNewConnection(_ connection: NWConnection) {
        connections.append(connection)
        onConnection?(connection)

        connection.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                print("Mock server: Client connected")
                self?.receiveMessages(on: connection)
            case .cancelled, .failed:
                self?.connections.removeAll { $0 === connection }
            default:
                break
            }
        }

        connection.start(queue: queue)
    }

    private func receiveMessages(on connection: NWConnection) {
        connection.receiveMessage { [weak self] data, context, isComplete, error in
            guard let self = self else { return }

            if let error = error {
                print("Mock server receive error: \(error)")
                return
            }

            if let data = data {
                self.messageCount += 1
                self.totalBytesReceived += data.count

                // Check if it's a WebSocket message
                if let context = context,
                   let wsMetadata = context.protocolMetadata(definition: NWProtocolWebSocket.definition) as? NWProtocolWebSocket.Metadata
                {
                    switch wsMetadata.opcode {
                    case .binary:
                        // Audio data
                        self.onAudioReceived?(data)
                        self.sendAudioReceivedResponse(to: connection, dataSize: data.count)

                    case .text:
                        // Text message
                        if let text = String(data: data, encoding: .utf8) {
                            self.onTextMessageReceived?(text)
                            self.handleTextMessage(text, on: connection)
                        }

                    default:
                        break
                    }
                }

                self.onMessageReceived?(data)
            }

            // Continue receiving
            if !isComplete {
                self.receiveMessages(on: connection)
            }
        }
    }

    private func handleTextMessage(_ message: String, on connection: NWConnection) {
        // Parse JSON messages from client
        if let data = message.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        {
            if let type = json["type"] as? String {
                switch type {
                case "start_recording":
                    sendResponse(to: connection, response: [
                        "type": "recording_started",
                        "sessionId": UUID().uuidString,
                        "timestamp": Date().timeIntervalSince1970,
                    ])

                case "stop_recording":
                    sendResponse(to: connection, response: [
                        "type": "recording_stopped",
                        "timestamp": Date().timeIntervalSince1970,
                    ])

                default:
                    break
                }
            }
        }
    }

    private func sendAudioReceivedResponse(to connection: NWConnection, dataSize: Int) {
        let response: [String: Any] = [
            "type": "audio_received",
            "size": dataSize,
            "timestamp": Date().timeIntervalSince1970,
            "totalReceived": totalBytesReceived,
        ]

        sendResponse(to: connection, response: response)
    }

    private func sendResponse(to connection: NWConnection, response: [String: Any]) {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: response),
              let jsonString = String(data: jsonData, encoding: .utf8)
        else {
            return
        }

        let metadata = NWProtocolWebSocket.Metadata(opcode: .text)
        let context = NWConnection.ContentContext(
            identifier: "Response",
            metadata: [metadata]
        )

        connection.send(
            content: jsonString.data(using: .utf8),
            contentContext: context,
            completion: .contentProcessed { _ in
                print("Mock server sent response: \(response["type"] ?? "unknown")")
            }
        )
    }

    // Test helper methods
    func sendMockTranscriptionResult(to connection: NWConnection, transcript: String) {
        let response: [String: Any] = [
            "type": "transcription_result",
            "transcript": transcript,
            "timestamp": Date().timeIntervalSince1970,
        ]

        sendResponse(to: connection, response: response)
    }

    func sendMockProcessingComplete(to connection: NWConnection) {
        let response: [String: Any] = [
            "type": "processing_complete",
            "results": [
                "transcript": "This is a test transcription of the audio recording.",
                "bulletSummary": [
                    "Key point about the audio content",
                    "Another important insight",
                    "Action item from the recording",
                ],
                "diagram": [
                    "title": "Audio Concepts",
                    "description": "Visual representation of ideas",
                    "content": "Diagram content here",
                ],
            ],
            "timestamp": Date().timeIntervalSince1970,
        ]

        sendResponse(to: connection, response: response)
    }
}

// MARK: - Test Helpers

extension AudioStreamingMockServer {
    // Simulate various server behaviors for testing
    func simulateNetworkError(on connection: NWConnection) {
        let response: [String: Any] = [
            "type": "error",
            "error": "Network error occurred",
            "code": 500,
        ]
        sendResponse(to: connection, response: response)
        connection.cancel()
    }

    func simulateProcessingDelay(seconds: Double = 2.0, then completion: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
            completion()
        }
    }

    // Validate audio data format
    func validateAudioData(_ data: Data) -> Bool {
        // Check if data appears to be valid audio
        // For m4a files, check for 'ftyp' signature
        if data.count > 8 {
            let signature = data.prefix(8)
            let ftypRange = signature.range(of: "ftyp".data(using: .utf8)!)
            return ftypRange != nil
        }

        // For raw audio, just check it's not empty and has reasonable size
        return data.count > 1024
    }
}
