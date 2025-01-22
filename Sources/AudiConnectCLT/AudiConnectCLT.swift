//
//  AudiConnectCLT.swift
//  AudiConnect
//
//  Created by William Alexander on 16/01/2025.
//

import ArgumentParser
import Foundation
import AudiConnect

@main
struct AudiConnectCLT: AsyncParsableCommand {
    
    static let configuration = CommandConfiguration(
        abstract: "A command-line tool to call and interact with Audi Connect services.",
        version: "0.1.0",
        subcommands: [
            ListVehicles.self,
            VehicleInformation.self,
            VehicleStatus.self
        ],
        defaultSubcommand: ListVehicles.self
    )
    
    struct Options: ParsableArguments {
        @Option(help: ArgumentHelp("Your AudiConnect username (registered email)."))
        var username: String
        
        @Option(help: ArgumentHelp("Your AudiConnect password."))
        var password: String
        
        @Option(help: ArgumentHelp("Your country code"))
        var country: String = "GB"
        
        @Flag
        var verbose: Bool = false
    }
}

extension AudiConnectCLT {
    
    struct ListVehicles: AsyncParsableCommand {
        
        @OptionGroup()
        var options: Options
        
        func run() async throws {
            let audiConnect = AudiConnect(
                username: options.username,
                password: options.password,
                country: options.country,
                model: .standard,
                isDebugLoggingEnabled: options.verbose
            )
            let vehicles = try await audiConnect.getVehicles()
            print("Vehicles", vehicles, separator: "\n")
        }
    }
}

extension AudiConnectCLT {
    
    struct VehicleInformation: AsyncParsableCommand {
        
        struct Options: ParsableArguments {
            @Option(help: ArgumentHelp("Your AudiConnect username (registered email)."))
            var username: String
            
            @Option(help: ArgumentHelp("Your AudiConnect password."))
            var password: String
            
            @Option(help: ArgumentHelp("Your country code"))
            var country: String = "GB"
            
            @Argument(help: ArgumentHelp("The VIN of the vehicle to retrieve information for."))
            var vin: String
            
            @Flag
            var verbose: Bool = false
        }
        
        @OptionGroup()
        var options: Options
        
        func run() async throws {
            let audiConnect = AudiConnect(
                username: options.username,
                password: options.password,
                country: options.country,
                model: .standard,
                isDebugLoggingEnabled: options.verbose
            )
            let vehicleInformation = try await audiConnect.getVehicleInformation(vin: options.vin)
            print("Vehicle Information", vehicleInformation, separator: "\n")
        }
    }
}

extension AudiConnectCLT {
    
    struct VehicleStatus: AsyncParsableCommand {
        
        struct Options: ParsableArguments {
            @Option(help: ArgumentHelp("Your AudiConnect username (registered email)."))
            var username: String
            
            @Option(help: ArgumentHelp("Your AudiConnect password."))
            var password: String
            
            @Option(help: ArgumentHelp("Your country code"))
            var country: String = "GB"
            
            @Argument(help: ArgumentHelp("The VIN of the vehicle to retrieve information for."))
            var vin: String
            
            @Flag
            var verbose: Bool = false
        }
        
        @OptionGroup()
        var options: Options
        
        func run() async throws {
            let audiConnect = AudiConnect(
                username: options.username,
                password: options.password,
                country: options.country,
                model: .standard,
                isDebugLoggingEnabled: options.verbose
            )
            let vehicleStatus = try await audiConnect.getVehicleStatus(vin: options.vin)
            print("Vehicle Status", vehicleStatus, separator: "\n")
        }
    }
}
