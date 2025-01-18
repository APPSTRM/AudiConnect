//
//  AZSToken.swift
//  AudiConnect
//
//  Created by William Alexander on 18/01/2025.
//

struct AZSToken: Decodable {
    let grantType: String
    let accessToken: String
    let tokenType: String
    let refreshToken: String
    let expiresIn: Int
    let scope: String
    
    enum CodingKeys: String, CodingKey {
        case grantType = "grant_type"
        case accessToken = "access_token"
        case tokenType = "token_type"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case scope
    }
}
