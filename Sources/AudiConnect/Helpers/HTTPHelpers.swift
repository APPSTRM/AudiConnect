//
//  HTTPHelpers.swift
//  AudiConnect
//
//  Created by William Alexander on 17/01/2025.
//

import Foundation
import SwiftSoup

func extractHiddenFormData(from data: Data) throws -> [String: String] {
    guard let string = String(data: data, encoding: .utf8) else {
        throw FailedToGetStringFromDataError()
    }
    let document = try SwiftSoup.parseBodyFragment(string)
    return try document.getElementsByTag("input")
        .filter { input in
            try input.attr("type") == "hidden"
        }
        .reduce(into: [String: String]()) { result, input in
            result[try input.attr("name")] = try input.val()
        }
}

struct FailedToGetStringFromDataError: Error {}

func extractPostURL(from data: Data, from url: URL) throws -> URL {
    guard let string = String(data: data, encoding: .utf8) else {
        throw FailedToGetStringFromDataError()
    }
    let document = try SwiftSoup.parseBodyFragment(string)
    guard let action = try document.getElementsByTag("form").first()?.attr("action") else {
        throw FailedToGetFormActionElement()
    }
    if action.hasPrefix("http") {
        guard let url = URL(string: action) else {
            throw FailedToConstructURLError()
        }
        return url
    } else if action.hasPrefix("/") {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            throw FailedToConstructURLError()
        }
        components.path = action
        components.queryItems = nil
        guard let url = components.url else {
            throw FailedToConstructURLError()
        }
        return url
    } else {
        throw FailedToConstructURLError()
    }
}

struct FailedToGetFormActionElement: Error {}

func formEncodedData(_ entries: [String: String]) throws -> Data {
    let data = entries
        .map { key, value in
            [key, value].joined(separator: "=")
        }
        .joined(separator: "&")
        .data(using: .utf8)
    guard let data else {
        throw FailedToCreateFormEncodedDataError()
    }
    return data
}

struct FailedToCreateFormEncodedDataError: Error {}

func extractRedirectLocation(from urlResponse: URLResponse) throws -> URL {
    guard
        let httpURLResponse = urlResponse as? HTTPURLResponse,
        let location = httpURLResponse.value(forHTTPHeaderField: "Location"),
        let url = URL(string: location)
    else {
        throw FailedToExtractRedirectLocationError(urlResponse: urlResponse)
    }
    return url
}

struct FailedToExtractRedirectLocationError: Error {
    let urlResponse: URLResponse
    
    var debugDescription: String {
        "Failed to extract redirect location from \(urlResponse)"
    }
}

extension URLRequest {
    mutating func setFollowRedirects(_ followRedirects: Bool) {
        setValue(followRedirects.description, forHTTPHeaderField: "X-APP-FOLLOW-REDIRECTS")
    }
}
