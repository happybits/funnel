import Foundation
import Combine

class LiveTranscriptionService: NSObject, ObservableObject {
    @Published var isConnected = false
    @Published var currentTranscript = ""
    @Published var fullTranscript = ""
    @Published var error: String?
    
    private var webSocketTask: URLSessionWebSocketTask?
    private var urlSession: URLSession!
    private let baseURL: String
    
    override init() {
        #if DEBUG
        let useLocalServer = true // Toggle this to switch between local and production
        self.baseURL = useLocalServer ? "ws://localhost:8000" : "wss://funnel-api.deno.dev"
        #else
        self.baseURL = "wss://funnel-api.deno.dev"
        #endif
        super.init()
        
        let configuration = URLSessionConfiguration.default
        self.urlSession = URLSession(configuration: configuration, delegate: self, delegateQueue: .main)
    }
    
    func connect() {
        disconnect() // Ensure we're not already connected
        
        guard let url = URL(string: "\(baseURL)/api/live-transcription") else {
            self.error = "Invalid WebSocket URL"
            return
        }
        
        webSocketTask = urlSession.webSocketTask(with: url)
        webSocketTask?.resume()
        
        // Start receiving messages
        receiveMessage()
    }
    
    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        isConnected = false
        error = nil
    }
    
    func sendAudioData(_ data: Data) {
        guard isConnected else { return }
        
        let message = URLSessionWebSocketTask.Message.data(data)
        webSocketTask?.send(message) { [weak self] error in
            if let error = error {
                self?.error = "Failed to send audio: \(error.localizedDescription)"
            }
        }
    }
    
    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    self.handleMessage(text)
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        self.handleMessage(text)
                    }
                @unknown default:
                    break
                }
                
                // Continue receiving messages
                self.receiveMessage()
                
            case .failure(let error):
                self.error = "WebSocket error: \(error.localizedDescription)"
                self.isConnected = false
            }
        }
    }
    
    private func handleMessage(_ jsonString: String) {
        guard let data = jsonString.data(using: .utf8) else { return }
        
        do {
            let message = try JSONDecoder().decode(TranscriptionMessage.self, from: data)
            
            switch message.type {
            case "ready":
                isConnected = true
                error = nil
                
            case "transcript":
                if let transcript = message.transcript {
                    currentTranscript = transcript
                    
                    // Append to full transcript if it's a final transcript
                    if message.isFinal == true {
                        fullTranscript += transcript + " "
                    }
                }
                
            case "error":
                error = message.message
                
            case "deepgram_closed":
                isConnected = false
                
            default:
                break
            }
        } catch {
            self.error = "Failed to decode message: \(error.localizedDescription)"
        }
    }
}

// MARK: - URLSessionWebSocketDelegate
extension LiveTranscriptionService: URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print("WebSocket connected")
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        print("WebSocket disconnected")
        isConnected = false
    }
}

// MARK: - Message Types
private struct TranscriptionMessage: Codable {
    let type: String
    let message: String?
    let transcript: String?
    let isFinal: Bool?
    let speechFinal: Bool?
    let confidence: Double?
    let duration: Double?
    let start: Double?
    
    enum CodingKeys: String, CodingKey {
        case type, message, transcript
        case isFinal = "is_final"
        case speechFinal = "speech_final"
        case confidence, duration, start
    }
}