//
//  RegisterIDKTokenResponse.swift
//  AudiConnect
//
//  Created by William Alexander on 18/01/2025.
//

struct RegisterIDKTokenResponse: Decodable {
    let clientID: String
    
    enum CodingKeys: String, CodingKey {
        case clientID = "client_id"
    }
}
