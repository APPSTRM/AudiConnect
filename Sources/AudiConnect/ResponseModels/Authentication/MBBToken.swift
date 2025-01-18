//
//  MBBTokenResponse.swift
//  AudiConnect
//
//  Created by William Alexander on 18/01/2025.
//

import Foundation

struct MBBToken: Decodable {
    let accessToken: String
    var refreshToken: String?
    let expiresIn: Int
    
    var expiresAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
    }
}
