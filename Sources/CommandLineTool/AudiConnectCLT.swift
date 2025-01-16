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
            ListVehicles.self
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
        }
    }
}
