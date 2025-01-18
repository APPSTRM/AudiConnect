//
//  VehicleStatusResponse.swift
//  AudiConnect
//
//  Created by William Alexander on 18/01/2025.
//

import Foundation

public struct VehicleStatusResponse: Decodable {
    let vehicleLights: VehicleLights
    let access: Access
    let measurements: Measurements
    let vehicleHealthInspection: VehicleHealthInspection
    let oilLevel: OilLevel
    let fuelStatus: FuelStatus
}

public extension VehicleStatusResponse {
    struct VehicleLights: Decodable {
        public struct LightsStatus: Decodable {
            public struct Value: Decodable {
                public struct Light: Decodable {
                    let name: String
                    let status: String
                }
                
                public let lights: [Light]
                public let carCapturedTimestamp: Date
            }
            
            public let value: Value
        }
        
        public let lightsStatus: LightsStatus
    }
    
    struct Access: Decodable {
        public struct AccessStatus: Decodable {}
        
        public let accessStatus: AccessStatus
    }
    
    struct Measurements: Decodable {
        public struct RangeStatus: Decodable {}
        public struct FuelLevelStatus: Decodable {}
        
        public struct OdometerStatus: Decodable {
            public struct Value: Decodable {
                public let odometer: Int
                public let carCapturedTimestamp: Date
            }
            public let value: Value
        }
        
        public let rangeStatus: RangeStatus
        public let fuelLevelStatus: FuelLevelStatus
        public let odometerStatus: OdometerStatus
    }
    
    struct VehicleHealthInspection: Decodable {
        public struct MaintenanceStatus: Decodable {}
        
        public let maintenanceStatus: MaintenanceStatus
    }
    
    struct OilLevel: Decodable {
        public struct OilLevelStatus: Decodable {}
        
        public let oilLevelStatus: OilLevelStatus
    }
    
    struct FuelStatus: Decodable {
        public struct RangeStatus: Decodable {}
        public let rangeStatus: RangeStatus
    }
}
