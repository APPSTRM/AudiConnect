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
        @Argument(help: ArgumentHelp("Your AudiConnect username (registered email)."))
        var username: String
        
        @Argument(help: ArgumentHelp("Your AudiConnect password."))
        var password: String
        
//        @Option(help: ArgumentHelp(NSLocalizedString(
//            "The locale to use when making API calls. "
//            + "Defaults to the system locale if possible, otherwise defaults to Germany. ",
//            comment: ""
//        )))
//        var locale: SupportedLocale? = nil
        
//        private var resolvedLocale: Locale {
//            // Prioritize the provided locale option, if one was given.
//            if let givenLocale = locale {
//                return Locale(identifier: givenLocale.rawValue)
//            }
//            return SupportedLocale.default
//        }
        
//        var resolvedEnvironment: Environment {
//            return .init(locale: resolvedLocale) ?? .germany
//        }
    }
}

extension AudiConnectCLT {
    
    struct ListVehicles: AsyncParsableCommand {
        
        @OptionGroup()
        var options: Options
        
        func run() async throws {
            let audiConnect = AudiConnect(username: options.username, password: options.password, country: "GB", model: .standard)
            let vehicles = try await audiConnect.getVehicles()
            print("Vehicles", vehicles, separator: "\n")
        }
    }
}

extension AudiConnectCLT {
    
    struct VehicleInformation: AsyncParsableCommand {
        
        struct Options: ParsableArguments {
            @Argument(help: ArgumentHelp("Your AudiConnect username (registered email)."))
            var username: String
            
            @Argument(help: ArgumentHelp("Your AudiConnect password."))
            var password: String
            
            @Argument(help: ArgumentHelp("The VIN of the vehicle to retrieve information for."))
            var vin: String
        }
        
        @OptionGroup()
        var options: Options
        
        func run() async throws {
            let audiConnect = AudiConnect(username: options.username, password: options.password, country: "GB", model: .standard)
            let vehicleInformation = try await audiConnect.getVehicleInformation(vin: options.vin)
            print("Vehicle Information", vehicleInformation, separator: "\n")
        }
    }
}

extension AudiConnectCLT {
    
    struct VehicleStatus: AsyncParsableCommand {
        
        struct Options: ParsableArguments {
            @Argument(help: ArgumentHelp("Your AudiConnect username (registered email)."))
            var username: String
            
            @Argument(help: ArgumentHelp("Your AudiConnect password."))
            var password: String
            
            @Argument(help: ArgumentHelp("The VIN of the vehicle to retrieve information for."))
            var vin: String
        }
        
        @OptionGroup()
        var options: Options
        
        func run() async throws {
            let audiConnect = AudiConnect(username: options.username, password: options.password, country: "GB", model: .standard)
            let vehicleStatus = try await audiConnect.getVehicleStatus(vin: options.vin)
            print("Vehicle Status", vehicleStatus, separator: "\n")
        }
    }
}
