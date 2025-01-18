//
//  VehicleInformationResponse.swift
//  AudiConnect
//
//  Created by William Alexander on 18/01/2025.
//

import Foundation

public struct VehicleInformationResponse: Decodable {
    public let data: Data
}

public extension VehicleInformationResponse {
    struct Data: Decodable {
        public let userVehicle: UserVehicle
    }
}

public extension VehicleInformationResponse.Data {
    struct UserVehicle: Decodable {
        public let vehicle: Vehicle
    }
}

public extension VehicleInformationResponse.Data.UserVehicle {
    struct Vehicle: Decodable {
        public let core: Core
        public let classification: Classification
        public let renderPictures: [RenderPicture]
        public let media: Media
    }
}

public extension VehicleInformationResponse.Data.UserVehicle {
    struct Core: Decodable {
        public let modelYear: Int
    }
    
    struct Classification: Decodable {
        public let modelRange: String
    }
    
    struct RenderPicture: Decodable {
        public let mediaType: String
        public let url: URL
    }
    
    struct Media: Decodable {
        public let shortName: String
        public let longName: String
    }
}
