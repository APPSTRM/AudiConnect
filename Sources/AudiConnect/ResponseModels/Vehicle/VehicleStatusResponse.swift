//
//  VehicleStatusResponse.swift
//  AudiConnect
//
//  Created by William Alexander on 18/01/2025.
//

import Foundation

public struct VehicleStatusResponse: Decodable {
    public let lights: VehicleLights
    public let access: Access
    public let measurements: Measurements
    public let healthInspection: VehicleHealthInspection
    public let oilLevel: OilLevel
    public let fuel: FuelStatus
    
    enum CodingKeys: String, CodingKey {
        case lights = "vehicleLights"
        case access, measurements
        case healthInspection = "vehicleHealthInspection"
        case oilLevel = "oilLevel"
        case fuel = "fuelStatus"
    }
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
        public struct AccessStatus: Decodable {
            public struct Value: Decodable {
                public struct Window: Decodable {
                    let name: String
                    let status: [String]
                }
                
                public struct Door: Decodable {
                    let name: String
                    let status: [String]
                }
                
                public let overallStatus: String
                public let windows: [Window]
                public let doors: [Door]
                public let carCapturedTimestamp: Date
                public let doorLockStatus: String
            }
            
            public let value: Value
        }
        
        public let accessStatus: AccessStatus
    }
    
    struct Measurements: Decodable {
        public struct RangeStatus: Decodable {
            public struct Value: Decodable {
                public let totalRange: Int
                public let gasolineRange: Int
                public let carCapturedTimestamp: Date
                
                enum CodingKeys: String, CodingKey {
                    case totalRange = "totalRange_km"
                    case gasolineRange, carCapturedTimestamp
                }
            }
            
            public let value: Value
        }
        
        public struct FuelLevelStatus: Decodable {
            public struct Value: Decodable {
                public let currentFuelLevel: Int
                public let primaryEngineType: String
                public let carCapturedTimestamp: Date
                public let carType: String
                
                enum CodingKeys: String, CodingKey {
                    case currentFuelLevel = "currentFuelLevel_pct"
                    case primaryEngineType, carCapturedTimestamp, carType
                }
            }
            
            public let value: Value
        }
        
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
        public struct MaintenanceStatus: Decodable {
            public struct Value: Decodable {
                public let mileage: Int
                public let inspectionDueKM: Int
                public let inspectionDueDays: Int
                public let oilServiceDueKM: Int
                public let oilServiceDueDays: Int
                public let carCapturedTimestamp: Date
                
                enum CodingKeys: String, CodingKey {
                    case mileage = "mileage_km"
                    case inspectionDueDays = "inspectionDue_days"
                    case inspectionDueKM = "inspectionDue_km"
                    case oilServiceDueKM = "oilServiceDue_km"
                    case oilServiceDueDays = "oilServiceDue_days"
                    case carCapturedTimestamp
                }
            }
            
            public let value: Value
        }
        
        public let maintenanceStatus: MaintenanceStatus
    }
    
    struct OilLevel: Decodable {
        public struct OilLevelStatus: Decodable {
            public struct Value: Decodable {
                public let value: Bool
                public let carCapturedTimestamp: Date
            }
            
            public let value: Value
        }
        
        public let oilLevelStatus: OilLevelStatus
    }
    
    struct FuelStatus: Decodable {
        public struct RangeStatus: Decodable {
            public struct Value: Decodable {
                public struct Engine: Decodable {
                    public let currentSOC: Int
                    public let currentFuelLevel: Int
                    public let remainingRange: Int
                    public let type: String
                    
                    enum CodingKeys: String, CodingKey {
                        case currentSOC = "currentSOC_pct"
                        case currentFuelLevel = "currentFuelLevel_pct"
                        case remainingRange = "remainingRange_km"
                        case type
                    }
                }
                
                public let primaryEngine: Engine
                public let carCapturedTimestamp: Date
                public let carType: String
                public let totalRange: Int
                
                enum CodingKeys: String, CodingKey {
                    case primaryEngine, carCapturedTimestamp, carType
                    case totalRange = "totalRange_km"
                }
            }
            
            public let value: Value
        }
        public let rangeStatus: RangeStatus
    }
}
