//
//  URLSession+Decodable.swift
//  AudiConnect
//
//  Created by William Alexander on 12/01/2025.
//

import Foundation

let decoder: JSONDecoder = {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    return decoder
}()

extension URLSession {
    
    func object<Response: Decodable>(
        from url: URL,
        decoder: JSONDecoder = decoder,
        delegate: (any URLSessionTaskDelegate)? = nil,
        isDebugLoggingEnabled: Bool = false
    ) async throws -> Response {
        let (data, _) = try await data(from: url, delegate: delegate)
        if isDebugLoggingEnabled {
            logResponse(data, forUrl: url)
        }
        return try decoder.decode(Response.self, from: data)
    }
    
    func object<Response: Decodable>(
        for request: URLRequest,
        decoder: JSONDecoder = decoder,
        delegate: (any URLSessionTaskDelegate)? = nil,
        isDebugLoggingEnabled: Bool = false
    ) async throws -> Response {
        let (data, _) = try await data(for: request, delegate: delegate)
        if isDebugLoggingEnabled {
            logResponse(data, forUrl: request.url)
        }
        return try decoder.decode(Response.self, from: data)
    }
}

private func logResponse(_ data: Data, forUrl url: URL?) {
    do {
        let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
        let prettyJSONData = try JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted])
        guard let prettyJSONString = String(data: prettyJSONData, encoding: .utf8) else { return }
        NetworkingLogger.debug(
            """
---------------
🌐 JSON for url \(url?.debugDescription ?? "-")
---------------
\(prettyJSONString)
---------------
"""
        )
    } catch {
        NetworkingLogger.debug(
            """
---------------
🌐 JSON for url \(url?.debugDescription ?? "-")
---------------
\(String(data: data, encoding: .utf8) ?? "None")
---------------
"""
        )
    }
}
