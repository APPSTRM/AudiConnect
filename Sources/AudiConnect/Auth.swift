//
//  Auth.swift
//  AudiConnect
//
//  Created by William Alexander on 10/01/2025.
//

import CommonCrypto
import Foundation
import SwiftSoup

final class Auth {
    
    private let username: String
    private let password: String
    private let country: String
    private let model: Model
    
    private var xClientID: String?
    private var userID = ""
    private var mbbToken: [String: Any] = [:]
    private var hereToken: [String: Any] = [:]
    private var mbbTokenExpired: Date?
    private var idkToken: [String: String] = [:]
    private var audiToken: [String: String] = [:]
    private var configuration: Configuration? = nil
    private var binded = false
    
    private let urlSession = URLSession.shared
    
    init(
        username: String,
        password: String,
        country: String,
        model: Model
    ) {
        self.username = username
        self.password = password
        self.country = country
        self.model = model
    }
    
    func login() async throws {
        let configuration = if let configuration = self.configuration {
            configuration
        } else {
            try await retrieveURLService()
        }
        
        let codeVerifier = generateCodeVerifier()
        let codeChallenge = generateCodeChallenge(from: codeVerifier)
        let codeChallengeMethod = "S256"
        
        // Login page
        let headers = headers()
        let data = [
            "response_type": "code",
            "client_id": configuration.clientID,
            "redirect_uri": "myaudi:///",
            "scope": "address badge birthdate birthplace email gallery mbb name nationalIdentifier nationality nickname phone picture profession profile vin openid",
            "state": UUID().uuidString,
            "nonce": UUID().uuidString,
            "prompt": "login",
            "code_challenge": codeChallenge,
            "code_challenge_method": codeChallengeMethod,
            "ui_locales": "\(configuration.language)-\(configuration.language) \(configuration.language)",
        ]
        
        var urlComponents = URLComponents(url: configuration.authorizationEndpoint, resolvingAgainstBaseURL: false)
        urlComponents?.queryItems = data.map { URLQueryItem(name: $0.key, value: $0.value) }
        guard let url = urlComponents?.url else {
            throw FailedToConstructURLError()
        }
        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = headers
        let idkResponse = try await urlSession.data(for: request)
        let hiddenFormElements = try extractHiddenFormData(from: idkResponse.0)
        
        
    }
    
    @discardableResult
    private func retrieveURLService() async throws -> Configuration {
        let marketURL = AudiConnectConstants.marketURL.appending(path: "/markets")
        let markets: MarketsResponse = try await urlSession.object(from: marketURL)
        guard let countrySpecification = markets.countries.countrySpecifications[country] else {
            throw CountryNotFoundError()
        }
        let language = countrySpecification.defaultLanguage
        
        let servicesURL = AudiConnectConstants.marketURL.appending(path: "/market/\(country)/\(language)")
        let services: ServicesResponse = try await urlSession.object(from: servicesURL)
        
        let openIDConfig: OpenIDConfig = try await urlSession.object(from: services.oidcURL)
        
        let configuration = Configuration(
            clientID: services.clientID ?? AudiConnectConstants.clientIDs[model] ?? "",
            audiURL: services.audiURL,
            baseURL: services.baseURL,
            profileURL: services.profileURL.appending(path: "/v3"),
            mbbURL: services.mbbURL ?? AudiConnectConstants.mbbURL,
            hereURL: AudiConnectConstants.hereComURL,
            mdkURL: services.mdkURL,
            cvURL: services.cvvsbURL,
            userURL: AudiConnectConstants.userInfoURL,
            authorizationEndpoint: openIDConfig.authorizationURL,
            tokenEndpoint: openIDConfig.tokenURL,
            revocationEndpoint: openIDConfig.revocationURL,
            language: language,
            country: country
        )
        self.configuration = configuration
        return configuration
    }
    
    private func headers(
        tokenType: TokenType? = nil,
        headers extraHeaders: [String: String]? = nil,
        okHTTP: Bool = false,
        securityToken: String? = nil
    ) -> [String: String] {
        var headers = [
            "Accept": "application/json",
            "Accept-Charset": "utf-8",
            "User-Agent": AudiConnectConstants.userAgent,
            "X-App-Name": "myAudi",
            "X-App-Version": AudiConnectConstants.appVersion,
        ]
        
        var tokenType = tokenType
        if let securityToken {
            headers["User-Agent"] = "okhttp/3.11.0"
            headers["x-mbbSecToken"] = securityToken
            tokenType = .mbb
        }
        if let tokenType {
            // refreshTokens
            let token = switch tokenType {
            case .idk: idkToken["access_token"]
            case .mbb: mbbToken["access_token"]
            case .audi: audiToken["access_token"]
            case .here: hereToken["access_token"]
            }
            if let token {
                headers["Authorization"] = "Bearer \(token)"
            }
        }
        if let xClientID {
            headers["X-Client-ID"] = xClientID
        }
        if okHTTP {
            headers["User-Agent"] = "okhttp/3.11.0"
        }
        if let extraHeaders {
            headers.merge(extraHeaders) { (_, new) in new }
        }
        
        return headers
    }
}

extension Auth {
    struct Configuration {
        let clientID: String
        let audiURL: URL
        let baseURL: URL
        let profileURL: URL
        let mbbURL: URL
        let hereURL: URL
        let mdkURL: URL
        let cvURL: URL
        let userURL: URL
        let authorizationEndpoint: URL
        let tokenEndpoint: URL
        let revocationEndpoint: URL
        let language: String
        let country: String
    }
}

/// Generate a random code_verifier
private func generateCodeVerifier() -> String {
    var randomBytes = [UInt8](repeating: 0, count: 32)
    _ = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
    let codeVerifier = Data(randomBytes).base64EncodedString(options: .urlSafeBase64)
    return codeVerifier.trimmingCharacters(in: CharacterSet(charactersIn: "="))
}

/// Generate code_challenge from code_verifier using SHA256
private func generateCodeChallenge(from codeVerifier: String) -> String {
    guard let verifierData = codeVerifier.data(using: .ascii) else { return "" }
    var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
    verifierData.withUnsafeBytes { buffer in
        _ = CC_SHA256(buffer.baseAddress, CC_LONG(buffer.count), &hash)
    }
    let codeChallenge = Data(hash).base64EncodedString(options: .urlSafeBase64)
    return codeChallenge.trimmingCharacters(in: CharacterSet(charactersIn: "="))
}

extension Data.Base64EncodingOptions {
    static let urlSafeBase64: Data.Base64EncodingOptions = [.endLineWithLineFeed, .endLineWithCarriageReturn]
}

private func extractHiddenFormData(from data: Data) throws -> [String: String] {
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

public enum Model: String, Sendable {
    case standard
    case eTron = "e-tron"
}

enum TokenType: String {
    case idk
    case mbb
    case audi
    case here
}

struct FailedToConstructURLError: Error {}
struct CountryNotFoundError: Error {}
