//
//  Auth.swift
//  AudiConnect
//
//  Created by William Alexander on 10/01/2025.
//

import Foundation

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
    private var idkToken: IDKToken?
    private var audiToken: AZSToken?
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
        
        let codeVerifier = PKCE.generateCodeVerifier()
        let codeChallenge = try PKCE.codeChallenge(fromVerifier: codeVerifier)
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
        
        var submitData = hiddenFormElements
        submitData["email"] = username
        
        let submitEmailURL = try extractPostURL(from: idkResponse.0, from: url)
        var submitEmailRequest = URLRequest(url: submitEmailURL)
        submitEmailRequest.httpMethod = "POST"
        submitEmailRequest.httpBody = try formEncodedData(submitData)
        submitEmailRequest.allHTTPHeaderFields = headers
        submitEmailRequest.setValue(true.description, forHTTPHeaderField: "X-APP-FOLLOW-REDIRECTS")
        let submitEmailResponse = try await urlSession.data(for: submitEmailRequest)
        
        let regexPattern = /"hmac"\s*:\s*"[0-9a-fA-F]+/
        guard
            let submitEmailStringResponse = String(data: submitEmailResponse.0, encoding: .utf8),
            let hmacParameter = submitEmailStringResponse.firstMatch(of: regexPattern)?.output,
            let hmac = hmacParameter.split(separator: ":").last?.filter({ $0 != "\"" }) as? String
        else {
            throw FailedToExtractHMACError()
        }
        
        submitData["hmac"] = hmac
        submitData["password"] = password
        
        let submitPasswordURL = submitEmailURL.deletingLastPathComponent().appending(path: "authenticate")
        var submitPasswordRequest = URLRequest(url: submitPasswordURL)
        submitPasswordRequest.httpMethod = "POST"
        submitPasswordRequest.httpBody = try formEncodedData(submitData)
        submitPasswordRequest.allHTTPHeaderFields = headers
        submitPasswordRequest.setFollowRedirects(false)
        let submitPasswordResponse = try await urlSession.data(for: submitPasswordRequest, delegate: SessionDelegate())
        
        // Follow first redirect
        let redirectLocation1 = try extractRedirectLocation(from: submitPasswordResponse.1)
        var followRedirect1Request = URLRequest(url: redirectLocation1)
        followRedirect1Request.httpMethod = "GET"
        followRedirect1Request.allHTTPHeaderFields = headers
        followRedirect1Request.setFollowRedirects(false)
        let followRedirect1Response = try await urlSession.data(for: followRedirect1Request, delegate: SessionDelegate())
        
        // Follow second redirect
        let redirectLocation2 = try extractRedirectLocation(from: followRedirect1Response.1)
        var followRedirect2Request = URLRequest(url: redirectLocation2)
        followRedirect2Request.httpMethod = "GET"
        followRedirect2Request.allHTTPHeaderFields = headers
        followRedirect2Request.setFollowRedirects(false)
        let followRedirect2Response = try await urlSession.data(for: followRedirect2Request, delegate: SessionDelegate())
        
        // Follow third redirect, extract auth code
        let authCodeLocation = try extractRedirectLocation(from: followRedirect2Response.1)
        var authCodeRequest = URLRequest(url: authCodeLocation)
        authCodeRequest.httpMethod = "GET"
        authCodeRequest.allHTTPHeaderFields = headers
        authCodeRequest.setFollowRedirects(false)
        let authCodeResponse = try await urlSession.data(for: authCodeRequest, delegate: SessionDelegate())
        
        let authCodeRedirectLocation = try extractRedirectLocation(from: authCodeResponse.1)
        
        guard
            let userId = URLComponents(url: redirectLocation1, resolvingAgainstBaseURL: false)?
                .queryItems?
                .first(where: { $0.name == "userId" })?
                .value
        else {
            throw UserIdMissingError()
        }
        self.userID = userId
        
        guard
            let authCode = URLComponents(url: authCodeRedirectLocation, resolvingAgainstBaseURL: false)?
                .queryItems?
                .first(where: { $0.name == "code" })?
                .value
        else {
            throw AuthCodeMissingError()
        }
        
        let idkToken = try await getIDKToken(code: authCode, refreshToken: nil, codeVerifier: codeVerifier)
        self.idkToken = idkToken
        
        let audiToken = try await getAZSToken(idToken: idkToken.idToken)
        self.audiToken = audiToken
        
        self.xClientID = try await registerIDK()
        
        print(self.xClientID)
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
    
    private func getIDKToken(code: String, refreshToken: String?, codeVerifier: String?) async throws -> IDKToken {
        guard let clientID = configuration?.clientID, let tokenEndpoint = configuration?.tokenEndpoint else {
            throw MissingClientIDError()
        }
        let data: [String: String]  = if let refreshToken {
            [
                "client_id": clientID,
                "grant_type": "refresh_token",
                "refresh_token": refreshToken,
                "response_type": "token id_token",
            ]
        } else {
            [
                "client_id": clientID,
                "grant_type": "authorization_code",
                "code": code,
                "redirect_uri": "myaudi:///",
                "response_type": "token id_token",
                "code_verifier": codeVerifier ?? "",
            ]
        }
//        let safeData = data.mapValues { $0.replacingOccurrences(of: "+", with: "%20") }
        let encodedData = try formEncodedData(data)
        
        var request = URLRequest(url: tokenEndpoint)
        request.httpMethod = "POST"
        request.httpBody = encodedData
        request.allHTTPHeaderFields = headers()
        request.setFollowRedirects(false)
        return try await urlSession.object(for: request, delegate: SessionDelegate())
    }
    
    private func getAZSToken(idToken: String) async throws -> AZSToken {
        guard let tokenEndpoint = configuration?.audiURL else {
            throw ConfigurationMissingError()
        }
        let data: [String: String]  = [
            "grant_type": "id_token",
            "token": idToken,
            "stage": "live",
            "config": "myaudi",
        ]
        var request = URLRequest(url: tokenEndpoint.appending(path: "token" ))
        request.httpMethod = "POST"
        request.httpBody = try JSONEncoder().encode(data)
        request.allHTTPHeaderFields = headers(appending: ["Content-Type": "application/json"])
        request.setFollowRedirects(false)
        return try await urlSession.object(for: request, delegate: SessionDelegate())
    }
    
    /// Registers the IDK token
    ///
    /// - Returns: X-Client-ID
    private func registerIDK() async throws -> String {
        guard let mbbEndpoint = configuration?.mbbURL else {
            throw ConfigurationMissingError()
        }
        let data = [
            "client_name": "SM-A405FN",
            "platform": "google",
            "client_brand": "Audi",
            "appName": "myAudi",
            "appVersion": AudiConnectConstants.appVersion,
            "appId": "de.myaudi.mobile.assistant",
        ]
        var request = URLRequest(url: mbbEndpoint.appending(path: "mobile/register/v1" ))
        request.httpMethod = "POST"
        request.httpBody = try JSONEncoder().encode(data)
        request.allHTTPHeaderFields = headers(appending: ["Content-Type": "application/json"])
        request.setFollowRedirects(false)
        let response: RegisterIDKTokenResponse = try await urlSession.object(for: request, delegate: SessionDelegate())
        return response.clientID
    }
    
    private func headers(
        tokenType: TokenType? = nil,
        appending extraHeaders: [String: String]? = nil,
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
            case .idk: idkToken?.accessToken
            case .mbb: mbbToken["access_token"]
            case .audi: audiToken?.accessToken
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
struct FailedToExtractHMACError: Error {}
struct LocationHeaderMissingError: Error {}
struct UserIdMissingError: Error {}
struct AuthCodeMissingError: Error {}
struct MissingClientIDError: Error {}
struct ConfigurationMissingError: Error {}

private final class SessionDelegate: NSObject, URLSessionTaskDelegate {
    @objc
    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        willPerformHTTPRedirection response: HTTPURLResponse,
        newRequest request: URLRequest,
        completionHandler: @escaping  @Sendable (URLRequest?) -> Void
    ) {
        guard let headerValue = task.currentRequest?.value(forHTTPHeaderField: "X-APP-FOLLOW-REDIRECTS") else {
            completionHandler(request)
            return
        }
        
        let shouldFollowRedirects = NSString(string: headerValue).boolValue
        let completionHandlerRequest = shouldFollowRedirects ? request : nil
        completionHandler(completionHandlerRequest)
    }
}
