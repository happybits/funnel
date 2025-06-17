//
//  APIClient.swift
//  Funnel
//
//  Created by Claude on 6/17/25.
//

import Foundation

class APIClient {
    static let shared = APIClient()

    private let session: URLSession
    private let baseURL: String
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 300 // 5 minutes for large uploads

        session = URLSession(configuration: configuration)
        decoder = JSONDecoder()
        encoder = JSONEncoder()

        // Use environment-based URL
        #if DEBUG
            // For local development - use 127.0.0.1 for simulator
            #if targetEnvironment(simulator)
                baseURL = "http://127.0.0.1:8000"
            #else
                baseURL = "http://localhost:8000"
            #endif
        #else
            // TODO: Update with production URL when deployed
            baseURL = "https://funnel-api.deno.dev"
        #endif
    }

    // MARK: - Generic Request Methods

    func request<T: Decodable>(_ endpoint: String,
                               method: String = "GET",
                               body: Data? = nil,
                               headers: [String: String]? = nil) async throws -> T
    {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = body

        // Default headers
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if body != nil && headers?["Content-Type"] == nil {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        // Custom headers
        headers?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.networkError("Invalid response")
            }

            if httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 {
                do {
                    return try decoder.decode(T.self, from: data)
                } catch {
                    throw APIError.decodingError(error.localizedDescription)
                }
            } else {
                // Try to decode error response
                if let errorResponse = try? decoder.decode(ErrorResponse.self, from: data) {
                    throw APIError.serverError(errorResponse.error, details: errorResponse.details)
                } else {
                    throw APIError.serverError("HTTP \(httpResponse.statusCode)", details: nil)
                }
            }
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error.localizedDescription)
        }
    }

    // MARK: - Multipart Upload

    func uploadMultipart<T: Decodable>(_ endpoint: String,
                                       fileURL: URL,
                                       fieldName: String = "audio",
                                       additionalFields: [String: String]? = nil) async throws -> T
    {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            throw APIError.invalidURL
        }
        
        print("APIClient: Uploading to \(url.absoluteString)")

        let boundary = UUID().uuidString
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        // Create multipart body
        var body = Data()

        // Add file data
        do {
            let fileData = try Data(contentsOf: fileURL)
            let fileName = fileURL.lastPathComponent
            let mimeType = mimeType(for: fileURL.pathExtension)

            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
            body.append(fileData)
            body.append("\r\n".data(using: .utf8)!)
        } catch {
            throw APIError.uploadFailed("Failed to read file: \(error.localizedDescription)")
        }

        // Add additional fields
        additionalFields?.forEach { key, value in
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }

        // End boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        do {
            print("APIClient: Starting upload with request to \(request.url?.absoluteString ?? "unknown")")
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.networkError("Invalid response")
            }
            
            print("APIClient: Response status code: \(httpResponse.statusCode)")

            if httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 {
                do {
                    let result = try decoder.decode(T.self, from: data)
                    print("APIClient: Successfully decoded response")
                    return result
                } catch {
                    print("APIClient: Decoding error: \(error)")
                    print("APIClient: Response data: \(String(data: data, encoding: .utf8) ?? "unable to decode")")
                    throw APIError.decodingError(error.localizedDescription)
                }
            } else {
                print("APIClient: Server error response: \(String(data: data, encoding: .utf8) ?? "unable to decode")")
                if let errorResponse = try? decoder.decode(ErrorResponse.self, from: data) {
                    throw APIError.serverError(errorResponse.error, details: errorResponse.details)
                } else {
                    throw APIError.serverError("HTTP \(httpResponse.statusCode)", details: nil)
                }
            }
        } catch let error as APIError {
            print("APIClient: API error: \(error)")
            throw error
        } catch {
            print("APIClient: Network error: \(error)")
            throw APIError.networkError(error.localizedDescription)
        }
    }

    // MARK: - Helper Methods

    private func mimeType(for pathExtension: String) -> String {
        switch pathExtension.lowercased() {
        case "m4a":
            return "audio/m4a"
        case "mp3":
            return "audio/mpeg"
        case "wav":
            return "audio/wav"
        case "mp4":
            return "audio/mp4"
        default:
            return "application/octet-stream"
        }
    }
}
