//
//  CapabilitiesResponse.swift
//  AudiConnect
//
//  Created by William Alexander on 18/01/2025.
//

import Foundation

struct CapabilitiesResponse: Decodable {
    let userCapabilities: UserCapabilities
}

extension CapabilitiesResponse {
    struct UserCapabilities: Decodable {
        let capabilitiesStatus: CapabilitiesStatus
    }
}

extension CapabilitiesResponse.UserCapabilities {
    struct CapabilitiesStatus: Decodable {
        let value: [Value]
    }
}

extension CapabilitiesResponse.UserCapabilities.CapabilitiesStatus {
    struct Value: Decodable {
        let id: String
        let expirationDate: Date?
        let userDisablingAllowed: Bool?
        let status: [Int]?
    }
}
