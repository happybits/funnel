import Foundation

enum Constants {
    enum API {
        static let localPort = 9000
        static let localHost = "127.0.0.1"
        static let localBaseURL = "http://\(localHost):\(localPort)"
        static let productionBaseURL = "https://funnel-api.deno.dev"

        static let useLocalServer = true

        static var baseURL: String {
            useLocalServer ? localBaseURL : productionBaseURL
        }

        static var webSocketScheme: String {
            useLocalServer ? "ws" : "wss"
        }

        static var webSocketHost: String {
            useLocalServer ? "\(localHost):\(localPort)" : "funnel-api.deno.dev"
        }
    }
}
