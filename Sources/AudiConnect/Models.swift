//
//  VehicleModel.swift
//  AudiConnect
//
//  Created by William Alexander on 10/01/2025.
//

import Foundation

// MARK: - Top-level Model
struct Vehicle: Codable {
    let lastAccess: Date
    var lastUpdate: Date = Date()
    let userCapabilities: UserCapabilities?
    let access: Access?
    let charging: Charging?
    let climatisationTimers: ClimatisationTimers?
    let climatisation: Climatisation?
    let fuelStatus: FuelStatus?
    let oilLevel: OilLevel?
    let vehicleLights: VehicleLights?
    let vehicleHealthInspection: VehicleHealthInspection?
    let measurements: Measurements?
    let vehicleHealthWarnings: VehicleHealthWarnings?
    let location: Location?
    let position: Position?
    let infos: Information?
    let departureProfiles: DepartureProfiles?
}

// MARK: - UserCapabilities
struct UserCapabilities: Codable {
    let capabilitiesStatus: [Capability]?
}

struct Capability: Codable {
    let id: String
    let expirationDate: Date?
}

// MARK: - Access
struct Access: Codable {
    let accessStatus: AccessStatus?
}

struct AccessStatus: Codable {
    let carCapturedTimestamp: Date
    let overallStatus: String?
    let doorLockStatus: Bool?
    let doors: [String: Bool]?
    let windows: [String: Bool]?
}

// MARK: - Charging
struct Charging: Codable {
    let batteryStatus: BatteryStatus?
    let chargingStatus: ChargingStatus?
    let chargingSettings: ChargingSettings?
    let plugStatus: PlugStatus?
    let chargeMode: ChargeMode?
}

struct BatteryStatus: Codable {
    let currentSocPct: Int?
    let cruisingRangeElectricKm: Int?
}

struct ChargingStatus: Codable {
    let remaining: Int?
    let chargingState: Bool?
    let chargeMode: String?
    let chargePowerKw: Double?
    let chargeRateKmph: Int?
    let chargeType: String?
}

struct ChargingSettings: Codable {
    let maxChargeCurrentAC: String?
    let autoUnlockPlugWhenCharged: Bool?
    let targetSocPct: Int?
}

struct PlugStatus: Codable {
    let plugConnectionState: Bool?
    let plugLockState: Bool?
    let externalPower: Bool?
}

struct ChargeMode: Codable {
    let preferredChargeMode: String?
    let availableChargeModes: [String]?
}

// MARK: - Climatisation
struct Climatisation: Codable {
    let climatisationSettings: ClimatisationSettings?
    let climatisationStatus: ClimatisationStatus?
    let windowHeatingStatus: WindowHeatingStatus?
}

struct ClimatisationStatus: Codable {
    let remainingClimatisationTimeMin: Int?
    let climatisationState: String?
}

struct ClimatisationSettings: Codable {
    let targetTemperatureC: Int?
    let targetTemperatureF: Int?
    let unitInCar: String?
}

struct WindowHeatingStatus: Codable {
    let state: [String: Bool]?
}

// MARK: - ClimatisationTimers
struct ClimatisationTimers: Codable {
    let climatisationTimersStatus: ClimatisationTimersStatus?
}

struct ClimatisationTimersStatus: Codable {
    let timeInCar: Date?
    let timers: [Timer]?
}

struct Timer: Codable {
    let id: Int
    let enabled: Bool
    let singleTimer: SingleTimer
}

struct SingleTimer: Codable {
    let start: Date?
    let target: Date?
}

// MARK: - FuelStatus
struct FuelStatus: Codable {
    let rangeStatus: FuelRangeStatus?
}

struct FuelRangeStatus: Codable {
    let carType: String?
    let primaryEngine: Engine?
    let secondaryEngine: Engine?
    let totalRangeKm: Int?
}

struct Engine: Codable {
    let type: String?
    let currentSocPct: Int?
    let remainingRangeKm: Int?
    let currentFuelLevelPct: Int?
}

// MARK: - OilLevel
struct OilLevel: Codable {
    let oilLevelStatus: Bool?
}

// MARK: - VehicleLights
struct VehicleLights: Codable {
    let lightsStatus: [String: Bool]?
}

// MARK: - VehicleHealthInspection
struct VehicleHealthInspection: Codable {
    let maintenanceStatus: MaintenanceStatus?
}

struct MaintenanceStatus: Codable {
    let inspectionDueDays: Int?
    let inspectionDueKm: Int?
    let mileageKm: Int?
    let oilServiceDueDays: Int?
    let oilServiceDueKm: Int?
}

// MARK: - Measurements
struct Measurements: Codable {
    let rangeStatus: RangeStatus?
    let odometerStatus: OdometerStatus?
}

struct RangeStatus: Codable {
    let electricRange: Int?
    let gasolineRange: Int?
    let totalRangeKm: Int?
}

struct OdometerStatus: Codable {
    let odometer: Int?
}

// MARK: - VehicleHealthWarnings
struct VehicleHealthWarnings: Codable {
    let warningLights: [String: Bool]?
}

// MARK: - Location
struct Location: Codable {
    let addresses: [Address]?
}

struct Address: Codable {
    let id: String
    let address: [String: String]?
}

// MARK: - Position
struct Position: Codable {
    let longitude: Double?
    let latitude: Double?
    let lastAccess: Date?
}

// MARK: - Information
struct Information: Codable {
    let core: Core
    let media: Media
}

struct Core: Codable {
    let modelYear: Int
}

struct Media: Codable {
    let shortName: String
    let longName: String
}

// MARK: - DepartureProfiles
struct DepartureProfiles: Codable {
    let departureProfilesStatus: DepartureProfilesStatus?
}

struct DepartureProfilesStatus: Codable {
    let minSocPct: Int?
    let timers: [[String: String]]?
}
