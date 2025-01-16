//
//  ServicesResponse.swift
//  AudiConnect
//
//  Created by William Alexander on 12/01/2025.
//

import Foundation

//base_url = services.get("commonsBaseURLLive")
//client_id = services.get("idkClientIDAndroidLive", CLIENT_IDS[self.model])
//audi_url = services.get("myAudiAuthorizationServerProxyServiceURLProduction")
//profil_url = services.get("idkCustomerProfileMicroserviceBaseURLLive")
//mbb_url = services.get("mbbOAuthBaseURLLive", MBB_URL)
//mdk_url = services.get("mobileDeviceKeyBaseURLProduction")
//cvvsb_url = services.get("connectedVehicleVehicleServiceBaseURLProduction")
//oidc_url = services.get("idkLoginServiceConfigurationURLProduction")

struct ServicesResponse: Decodable {
    
    let baseURL: URL
    let clientID: String?
    let audiURL: URL
    let profileURL: URL
    let mbbURL: URL?
    let mdkURL: URL
    let cvvsbURL: URL
    let oidcURL: URL
    
    enum CodingKeys: String, CodingKey {
        case baseURL = "commonsBaseURLLive"
        case clientID = "idkClientIDAndroidLive"
        case audiURL = "myAudiAuthorizationServerProxyServiceURLProduction"
        case profileURL = "idkCustomerProfileMicroserviceBaseURLLive"
        case mbbURL = "mbbOAuthBaseURLLive"
        case mdkURL = "mobileDeviceKeyBaseURLProduction"
        case cvvsbURL = "connectedVehicleVehicleServiceBaseURLProduction"
        case oidcURL = "idkLoginServiceConfigurationURLProduction"
    }
}
