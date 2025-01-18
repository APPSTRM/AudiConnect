//
//  URLSession+Decodable.swift
//  AudiConnect
//
//  Created by William Alexander on 12/01/2025.
//

import Foundation

extension URLSession {
    
    func object<Response: Decodable>(
        from url: URL,
        decoder: JSONDecoder = JSONDecoder(),
        delegate: (any URLSessionTaskDelegate)? = nil
    ) async throws -> Response {
        let (data, _) = try await data(from: url, delegate: delegate)
#if DEBUG
        logResponse(data, forUrl: url)
#endif
        return try decoder.decode(Response.self, from: data)
    }
    
    func object<Response: Decodable>(
        for request: URLRequest,
        decoder: JSONDecoder = JSONDecoder(),
        delegate: (any URLSessionTaskDelegate)? = nil
    ) async throws -> Response {
        let (data, _) = try await data(for: request, delegate: delegate)
#if DEBUG
        logResponse(data, forUrl: request.url)
#endif
        return try decoder.decode(Response.self, from: data)
    }
}

private func logResponse(_ data: Data, forUrl url: URL?) {
    do {
        let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
        let prettyJSONData = try JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted])
        guard let prettyJSONString = String(data: prettyJSONData, encoding: .utf8) else { return }
        print(
            "---------------",
            "🌐 JSON for url \(url?.debugDescription ?? "-")",
            "---------------",
            prettyJSONString,
            "---------------",
            separator: "\n"
        )
    } catch {
        print(
            "---------------",
            "🌐 Response for url \(url?.debugDescription ?? "-")",
            "---------------",
            String(data: data, encoding: .utf8) ?? "None",
            "---------------",
            separator: "\n"
        )
    }
}
