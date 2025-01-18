//
//  HomeRegionResponse.swift
//  AudiConnect
//
//  Created by William Alexander on 18/01/2025.
//

import Foundation

struct HomeRegionResponse: Decodable {
    let homeRegion: HomeRegion
}

extension HomeRegionResponse {
    struct HomeRegion: Decodable {
        let baseURL: String
    }
}
