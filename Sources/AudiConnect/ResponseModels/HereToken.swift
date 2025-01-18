//
//  HereToken.swift
//  AudiConnect
//
//  Created by William Alexander on 18/01/2025.
//

struct HereToken: Decodable {
    let accessToken: String
    let refreshToken: String?
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
    }
}
