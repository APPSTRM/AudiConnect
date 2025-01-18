//
//  Cryptography.swift
//  AudiConnect
//
//  Created by William Alexander on 17/01/2025.
//

import CommonCrypto
import CryptoKit
import Foundation

///
/// An easy-to-use implementation of the client side of the [PKCE standard](https://datatracker.ietf.org/doc/html/rfc7636).
/// https://gist.github.com/travisnewby/b030cf862862c0c55777e3db50eaccf8
///
struct PKCE {
    
    typealias PKCECode = String
    
    /// A high-entropy cryptographic random value, as described in [Section 4.1](https://datatracker.ietf.org/doc/html/rfc7636#section-4.1) of the PKCE standard.
    let codeVerifier: PKCECode
    
    /// A transformation of the codeVerifier, as defined in [Section 4.2](https://datatracker.ietf.org/doc/html/rfc7636#section-4.2) of the PKCE standard.
    let codeChallenge: PKCECode
    
    init() throws {
        
        codeVerifier = PKCE.generateCodeVerifier()
        codeChallenge = try PKCE.codeChallenge(fromVerifier: codeVerifier)
    }
    
    static func codeChallenge(fromVerifier verifier: PKCECode) throws -> PKCECode {
        
        guard let verifierData = verifier.data(using: .ascii) else { throw PKCEError.improperlyFormattedVerifier }
        
        let challengeHashed = SHA256.hash(data: verifierData)
        let challengeBase64Encoded = Data(challengeHashed).base64URLEncodedString
        
        return challengeBase64Encoded
    }
    
    ///
    /// Generates a random code verifier (as defined in [Seciton 4.1 of the PKCE standard](https://datatracker.ietf.org/doc/html/rfc7636#section-4.1)).
    ///
    /// This method first attempts to use CryptoKit to generate random bytes. If it fails to generate those random bytes, it falls back on a generic
    /// Base64 random string generator.
    ///
    static func generateCodeVerifier() -> PKCECode {
        
        do {
            
            let rando = try PKCE.generateCryptographicallySecureRandomOctets(count: 32)
            return Data(bytes: rando, count: rando.count).base64URLEncodedString
            
        } catch {
            
            return generateBase64RandomString(ofLength: 43)
        }
    }
    
    private static func generateCryptographicallySecureRandomOctets(count: Int) throws -> [UInt8] {
        
        var octets = [UInt8](repeating: 0, count: count)
        let status = SecRandomCopyBytes(kSecRandomDefault, octets.count, &octets)
        
        if status == errSecSuccess {
            
            return octets
            
        } else {
            
            throw PKCEError.failedToGenerateRandomOctets
        }
    }
    
    private static func generateBase64RandomString(ofLength length: UInt8) -> PKCECode {
        
        let base64 = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map{ _ in base64.randomElement()! })
    }
    
    enum PKCEError: Error {
        
        case failedToGenerateRandomOctets
        case improperlyFormattedVerifier
    }
}

extension Data {
    
    ///
    /// Returns a Base64 URL-encoded string _without_ padding.
    ///
    /// This string is compatible with the PKCE Code generation process, and uses the algorithm as defined in the [PKCE standard](https://datatracker.ietf.org/doc/html/rfc7636#appendix-A).
    ///
    var base64URLEncodedString: String {
        
        base64EncodedString()
            .replacingOccurrences(of: "=", with: "") // Remove any trailing '='s
            .replacingOccurrences(of: "+", with: "-") // 62nd char of encoding
            .replacingOccurrences(of: "/", with: "_") // 63rd char of encoding
            .trimmingCharacters(in: .whitespaces)
    }
}
