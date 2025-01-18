//
//  Constants.swift
//  AudiConnect
//
//  Created by William Alexander on 10/01/2025.
//

import Foundation

struct Constants {
    static let brand = "Audi"
    
    // Client IDs for different models
    static let clientIDs: [Model: String] = [
        .standard: "09b6cbec-cd19-4589-82fd-363dfa8c24da@apps_vw-dilab_com",
        .eTron: "f4d0934f-32bf-4ce4-b3c4-699a7049ad26@apps_vw-dilab_com"
    ]
    
    // URLs
    static let marketURL = URL(string: "https://content.app.my.audi.com/service/mobileapp/configurations")!
    static let mbbURL = URL(string: "https://mbboauth-1d.prd.ece.vwg-connect.com/mbbcoauth")!
    static let vehicleInfoURL = URL(string: "https://app-api.live-my.audi.com/vgql/v1/graphql")!
    static let hereComURL = URL(string: "https://csm.cc.api.here.com/api/v1")!
    static let userInfoURL = URL(string: "https://userinformationservice.apps.emea.vwapps.io")!
    
    // Header values
    static let userAgent = "Android/4.24.2 (Build 800240338.root project 'onetouch-android'.ext.buildTime) Android/11"
    static let appVersion = "4.24.2"
}
