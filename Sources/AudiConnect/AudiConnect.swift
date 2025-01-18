
import Foundation

public final class AudiConnect {
    
    private let auth: Auth
    private let urlSession: URLSession
    
    private var vehicleURLs: [VIN: FillRegion] = [:]
    
    public init(username: String, password: String, country: String, model: Model, urlSession: URLSession = .shared) {
        self.auth = Auth(username: username, password: password, country: country, model: model, urlSession: urlSession)
        self.urlSession = urlSession
    }
    
    public func getVehicles() async throws -> [VehiclesResponse.Vehicle] {
        try await auth.loginIfRequired()
        let configuration = try auth.getConfiguration()
        var request = URLRequest(url: configuration.mdkURL.appending(path: "vehicle/v2/vehicles"))
        request.allHTTPHeaderFields = auth.headers(tokenType: .idk)
        let vehicles: VehiclesResponse = try await urlSession.object(for: request)
        return vehicles.data
    }
    
    public func getVehicleInformation(vin: String) async throws -> VehicleInformationResponse {
        try await auth.loginIfRequired()
        let configuration = try auth.getConfiguration()
        let language = configuration.language
        let country = configuration.country
        let headers = auth.headers(tokenType: .audi, appending: [
            "Accept-Language": "\(language)-\(country)",
            "Content-Type": "application/json",
            "X-User-Country": country,
        ])
        
        struct Body: Encodable {
            let query: String
            let variables: [String: String]
        }
        let data = Body(
            query: "query ($vin: String!) {userVehicle(vehicleCoreId: $vin) {vehicle {core {modelYear} classification {modelRange} media {shortName longName} renderPictures(mediaTypes: \"MYAPN1NB\") { mediaType url}}}}",
            variables: ["vin": vin]
        )
        
        var request = URLRequest(url: configuration.baseURL.appending(path: "vgql/v1/graphql"))
        request.httpMethod = "POST"
        request.httpBody = try JSONEncoder().encode(data)
        request.allHTTPHeaderFields = headers
        return try await urlSession.object(for: request)
    }
    
    public func getVehicleStatus(vin: String) async throws -> VehicleStatusResponse {
        try await auth.loginIfRequired()
        let configuration = try auth.getConfiguration()
        
        let headers = auth.headers(tokenType: .idk)
        guard var capabilitiesURLComponents = URLComponents(url: configuration.mdkURL, resolvingAgainstBaseURL: false) else {
            throw FailedToConstructURLError()
        }
        capabilitiesURLComponents.path = "/vehicle/v1/vehicles/\(vin)/selectivestatus"
        capabilitiesURLComponents.queryItems = [
            URLQueryItem(name: "jobs", value: "userCapabilities")
        ]
        guard let capabilitiesURL = capabilitiesURLComponents.url else {
            throw FailedToConstructURLError()
        }
        var capabilitiesRequest = URLRequest(url: capabilitiesURL)
        capabilitiesRequest.allHTTPHeaderFields = headers
        let capabilitiesResponse: CapabilitiesResponse = try await urlSession.object(for: capabilitiesRequest)
        
        let statusJobs = capabilitiesResponse.userCapabilities.capabilitiesStatus.value
            .map(\.id)
            .joined(separator: ",")
        
        guard var statusURLComponents = URLComponents(url: configuration.mdkURL, resolvingAgainstBaseURL: false) else {
            throw FailedToConstructURLError()
        }
        statusURLComponents.path = "/vehicle/v1/vehicles/\(vin)/selectivestatus"
        statusURLComponents.queryItems = [
            URLQueryItem(name: "jobs", value: statusJobs)
        ]
        guard let capabilitiesURL = statusURLComponents.url else {
            throw FailedToConstructURLError()
        }
        var statusRequest = URLRequest(url: capabilitiesURL)
        statusRequest.allHTTPHeaderFields = headers
        return try await urlSession.object(for: statusRequest)
    }
}

private extension AudiConnect {
    
    func createVehicleURL(vin: String) async throws -> FillRegion {
        if let urls = vehicleURLs[vin] {
            return urls
        }
        
        var urlRaw = "https://msg.volkswagen.de/fs-car"
        var urlSetterRaw = "https://mal-1a.prd.ece.vwg-connect.com/api"
        guard let urlSetter = URL(string: urlSetterRaw) else {
            throw FailedToConstructURLError()
        }
        var request = URLRequest(url: urlSetter.appending(path: "cs/vds/v1/vehicles/\(vin)/homeRegion"))
        request.allHTTPHeaderFields = auth.headers(tokenType: .mbb)
        let homeRegion: HomeRegionResponse = try await urlSession.object(for: request)
        let vehicleURL = homeRegion.homeRegion.baseURL
        
        if vehicleURL != urlSetterRaw {
            urlRaw = vehicleURL
                .replacingOccurrences(of: "mal-", with: "fal-")
                .replacingOccurrences(of: "/api", with: "/fs-car")
            urlSetterRaw = vehicleURL
        }
        guard let url = URL(string: urlRaw), let urlSetter = URL(string: urlSetterRaw) else {
            throw FailedToConstructURLError()
        }
        vehicleURLs[vin] = (url, urlSetter)
        return (url, urlSetter)
    }
}

private extension Auth {
    func getConfiguration() throws -> Configuration {
        guard let configuration else {
            throw ConfigurationMissingError()
        }
        return configuration
    }
}

public struct VehicleData: Codable {
    
}

typealias VIN = String

typealias FillRegion = (url: URL, urlSetter: URL)
