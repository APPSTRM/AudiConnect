//
//  IDKToken.swift
//  AudiConnect
//
//  Created by William Alexander on 18/01/2025.
//

struct IDKToken: Decodable {
    let tokenType: String
    let expiresIn: Int
    let idToken: String
    let accessToken: String
    let refreshToken: String
    
    enum CodingKeys: String, CodingKey {
        case tokenType = "token_type"
        case expiresIn = "expires_in"
        case idToken = "id_token"
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
    }
}
