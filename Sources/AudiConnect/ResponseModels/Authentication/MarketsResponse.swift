//
//  MarketsResponse.swift
//  AudiConnect
//
//  Created by William Alexander on 12/01/2025.
//

struct MarketsResponse: Decodable {
    let published: Bool
    let countries: Countries
}

extension MarketsResponse {
    
    struct Countries: Decodable {
        let defaultCountry: String
        let countrySpecifications: [String: CountrySpecification]
    }
    
    struct CountrySpecification: Decodable {
        let defaultLanguage: String
    }
}
