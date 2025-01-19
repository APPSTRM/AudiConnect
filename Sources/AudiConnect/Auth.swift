//
//  Auth.swift
//  AudiConnect
//
//  Created by William Alexander on 10/01/2025.
//

import Foundation

final class Auth {
    
    private(set) var xClientID: String?
    private(set) var userID = ""
    private(set) var mbbToken: MBBToken?
    private(set) var hereToken: HereToken?
    private(set) var idkToken: IDKToken?
    private(set) var audiToken: AZSToken?
    private(set) var configuration: Configuration? = nil
    private(set) var isAuthenticated = false
    
    private let username: String
    private let password: String
    private let country: String
    private let model: Model
    private let urlSession: URLSession
    
    init(
        username: String,
        password: String,
        country: String,
        model: Model,
        urlSession: URLSession
    ) {
        self.username = username
        self.password = password
        self.country = country
        self.model = model
        self.urlSession = urlSession
    }
    
    func loginIfRequired() async throws {
        if isAuthenticated { return }
        try await login()
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
        
        let redirectLocation1Components = URLComponents(url: redirectLocation1, resolvingAgainstBaseURL: false)
        if redirectLocation1Components?.queryItems?["error"] == "login.error.throttled" {
            throw LoginRequestsThrottledError()
        }
        
        if redirectLocation1Components?.queryItems?["error"] == "login.errors.password_invalid" {
            throw IncorrectPasswordError()
        }
        
        var followRedirect1Request = URLRequest(url: redirectLocation1)
        followRedirect1Request.allHTTPHeaderFields = headers
        followRedirect1Request.setFollowRedirects(false)
        let followRedirect1Response = try await urlSession.data(for: followRedirect1Request, delegate: SessionDelegate())
        
        // Follow second redirect
        let redirectLocation2 = try extractRedirectLocation(from: followRedirect1Response.1)
        var followRedirect2Request = URLRequest(url: redirectLocation2)
        followRedirect2Request.allHTTPHeaderFields = headers
        followRedirect2Request.setFollowRedirects(false)
        let followRedirect2Response = try await urlSession.data(for: followRedirect2Request, delegate: SessionDelegate())
        
        // Follow third redirect, extract auth code
        let authCodeLocation = try extractRedirectLocation(from: followRedirect2Response.1)
        var authCodeRequest = URLRequest(url: authCodeLocation)
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
        
        var mbbToken = try await getMBBToken(idToken: idkToken.idToken, refreshToken: nil)
        self.mbbToken = mbbToken
        
        // Immediately refresh the MBB token
        mbbToken = try await getMBBToken(idToken: nil, refreshToken: mbbToken.refreshToken)
        mbbToken.expiresAt = .now + Double(mbbToken.expiresIn)
        
        let hereToken = try await getHereToken(idToken: idkToken.idToken, refreshToken: nil)
        self.hereToken = hereToken
        
        if let hereRefreshToken = hereToken.refreshToken {
            mbbToken.refreshToken = hereRefreshToken
        }
        
        isAuthenticated = true
        AuthenticationLogger.info("✅ Authentication process completed successfully")
    }
    
    func headers(
        tokenType: TokenType? = nil,
        appending extraHeaders: [String: String]? = nil,
        okHTTP: Bool = false,
        securityToken: String? = nil
    ) -> [String: String] {
        var headers = [
            "Accept": "application/json",
            "Accept-Charset": "utf-8",
            "User-Agent": Constants.userAgent,
            "X-App-Name": "myAudi",
            "X-App-Version": Constants.appVersion,
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
            case .mbb: mbbToken?.accessToken
            case .audi: audiToken?.accessToken
            case .here: hereToken?.accessToken
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
    
    @discardableResult
    private func retrieveURLService() async throws -> Configuration {
        let marketURL = Constants.marketURL.appending(path: "/markets")
        let markets: MarketsResponse = try await urlSession.object(from: marketURL)
        guard let countrySpecification = markets.countries.countrySpecifications[country] else {
            throw CountryNotFoundError()
        }
        let language = countrySpecification.defaultLanguage
        
        let servicesURL = Constants.marketURL.appending(path: "/market/\(country)/\(language)")
        let services: ServicesResponse = try await urlSession.object(from: servicesURL)
        
        let openIDConfig: OpenIDConfig = try await urlSession.object(from: services.oidcURL)
        
        let configuration = Configuration(
            clientID: services.clientID ?? Constants.clientIDs[model] ?? "",
            audiURL: services.audiURL,
            baseURL: services.baseURL,
            profileURL: services.profileURL.appending(path: "/v3"),
            mbbURL: services.mbbURL ?? Constants.mbbURL,
            hereURL: Constants.hereComURL,
            mdkURL: services.mdkURL,
            cvURL: services.cvvsbURL,
            userURL: Constants.userInfoURL,
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
        } else if let codeVerifier {
            [
                "client_id": clientID,
                "grant_type": "authorization_code",
                "code": code,
                "redirect_uri": "myaudi:///",
                "response_type": "token id_token",
                "code_verifier": codeVerifier,
            ]
        } else {
            throw AccessOrIDTokenMustBeProvided()
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
            "appVersion": Constants.appVersion,
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
    
    private func getMBBToken(idToken: String?, refreshToken: String?) async throws -> MBBToken {
        guard let mbbEndpoint = configuration?.mbbURL else {
            throw ConfigurationMissingError()
        }
        let data: [String: String] = if let refreshToken {
            [
                "grant_type": "refresh_token",
                "token": refreshToken,
                "scope": "sc2:fal",
                // "vin": vin, // App uses a dedicated VIN here, but it works without, don't know
            ]
        } else if let idToken {
            [
                "grant_type": "id_token",
                "token": idToken,
                "scope": "sc2:fal",
            ]
        } else {
            throw AccessOrIDTokenMustBeProvided()
        }
//        let safeData = data.mapValues { $0.replacingOccurrences(of: "+", with: "%20") }
        let encodedData = try formEncodedData(data)
        var request = URLRequest(url: mbbEndpoint.appending(path: "mobile/oauth2/v1/token" ))
        request.httpMethod = "POST"
        request.httpBody = encodedData
        request.allHTTPHeaderFields = headers()
        request.setFollowRedirects(false)
        return try await urlSession.object(for: request, delegate: SessionDelegate())
    }
    
    private func getHereToken(idToken: String?, refreshToken: String?) async throws -> HereToken {
        guard let mbbEndpoint = configuration?.mbbURL else {
            throw ConfigurationMissingError()
        }
        let data: [String: String] = if let refreshToken {
            [
                "grant_type": "refresh_token",
                "token": refreshToken,
                "scope": "sc2:here_a_t21-s",
            ]
        } else if let idToken {
            [
                "grant_type": "id_token",
                "token": idToken,
                "scope": "sc2:here_a_t21-s",
            ]
        } else {
            throw AccessOrIDTokenMustBeProvided()
        }
//        let safeData = data.mapValues { $0.replacingOccurrences(of: "+", with: "%20") }
        let encodedData = try formEncodedData(data)
        var request = URLRequest(url: mbbEndpoint.appending(path: "mobile/oauth2/v1/token" ))
        request.httpMethod = "POST"
        request.httpBody = encodedData
        request.allHTTPHeaderFields = headers()
        request.setFollowRedirects(false)
        return try await urlSession.object(for: request, delegate: SessionDelegate())
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
struct LoginRequestsThrottledError: Error {
    var errorDescription: String? { "Login requests have been throttled, please try again later." }
}
struct IncorrectPasswordError: LocalizedError {
    var errorDescription: String? { "Incorrect password, please try again." }
}
struct FailedToExtractHMACError: Error {}
struct LocationHeaderMissingError: Error {}
struct UserIdMissingError: Error {}
struct AuthCodeMissingError: Error {}
struct MissingClientIDError: Error {}
struct ConfigurationMissingError: Error {}
struct AccessOrIDTokenMustBeProvided: Error {}

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
