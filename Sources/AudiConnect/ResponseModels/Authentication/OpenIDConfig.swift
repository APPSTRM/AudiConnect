//
//  OpenIDConfig.swift
//  AudiConnect
//
//  Created by William Alexander on 12/01/2025.
//

import Foundation

struct OpenIDConfig: Decodable {
    let authorizationURL: URL
    let tokenURL: URL
    let revocationURL: URL
    
    enum CodingKeys: String, CodingKey {
        case authorizationURL = "authorization_endpoint"
        case tokenURL = "token_endpoint"
        case revocationURL = "revocation_endpoint"
    }
}
