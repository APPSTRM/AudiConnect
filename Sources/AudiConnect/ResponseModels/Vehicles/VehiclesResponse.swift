//
//  VehiclesResponse.swift
//  AudiConnect
//
//  Created by William Alexander on 18/01/2025.
//

public struct VehiclesResponse: Decodable {
    let data: [Vehicle]
}

public extension VehiclesResponse {
    struct Vehicle: Decodable {
        public let userRoleStatus: String
        public let vin: String
        public let enrollmentStatus: String
        public let nickname: String
        public let devicePlatform: String
        public let carType: String
        public let engineType: EngineType
    }
}

public extension VehiclesResponse.Vehicle {
    struct EngineType: Decodable {
        let primaryEngineType: String
    }
}
