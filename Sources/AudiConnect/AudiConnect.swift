
import Foundation

public final class AudiConnect {
    
    let auth: Auth
    
    public init(username: String, password: String, country: String, model: Model) {
        self.auth = Auth(username: username, password: password, country: country, model: model)
    }
    
//    func getVehicleData(vin: String) async throws -> VehicleData {
//        try await refreshTokenIfNeeded()
//        let url = baseURL.appendingPathComponent("/vehicles/\(vin)/data")
//        var request = URLRequest(url: url)
//        request.httpMethod = "GET"
//        request.setValue("Bearer \(token.accessToken)", forHTTPHeaderField: "Authorization")
//        request.setValue("application/json", forHTTPHeaderField: "Accept")
//        
//        let (data, response) = try await URLSession.shared.data(for: request)
//        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
//            throw AudiConnectError.failedToFetchData
//        }
//        
//        let vehicleData = try JSONDecoder().decode(VehicleData.self, from: data)
//        return vehicleData
//    }
    
    public func getVehicles() async throws -> [VehicleSummary] {
//        try await refreshTokenIfNeeded()
//        let url = AudiConnectConstants.vehicleInfoURL.appendingPathComponent("/vehicles")
//        var request = URLRequest(url: url)
//        request.httpMethod = "GET"
//        request.setValue("Bearer \(token.accessToken)", forHTTPHeaderField: "Authorization")
//        request.setValue("application/json", forHTTPHeaderField: "Accept")
//        
//        let (data, response) = try await URLSession.shared.data(for: request)
//        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
//            throw AudiConnectError.failedToFetchData
//        }
//        
//        let vehicles = try JSONDecoder().decode([VehicleSummary].self, from: data)
//        return vehicles
        try await auth.login()
        return []
    }
    
//    func updateVehicleStatus(vin: String, status: VehicleStatusUpdate) async throws {
//        try await refreshTokenIfNeeded()
//        let url = baseURL.appendingPathComponent("/vehicles/\(vin)/status")
//        var request = URLRequest(url: url)
//        request.httpMethod = "POST"
//        request.setValue("Bearer \(token.accessToken)", forHTTPHeaderField: "Authorization")
//        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//        
//        request.httpBody = try JSONEncoder().encode(status)
//        
//        let (_, response) = try await URLSession.shared.data(for: request)
//        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 204 else {
//            throw AudiConnectError.failedToUpdateStatus
//        }
//    }
//    
//    func refreshTokenIfNeeded() async throws {
//        let expirationThreshold: TimeInterval = 300 // 5 minutes before expiry
//        let currentTime = Date().timeIntervalSince1970
//        let tokenExpiryTime = currentTime + TimeInterval(token.expiresIn)
//        
//        if tokenExpiryTime - currentTime < expirationThreshold {
//            token = try await oauthService.refreshToken(refreshToken: token.refreshToken)
//        }
//    }
}

enum AudiConnectError: Error, LocalizedError {
    case failedToFetchData
    case failedToUpdateStatus
    case invalidResponse
    case tokenRefreshFailed
    
    var errorDescription: String? {
        switch self {
        case .failedToFetchData:
            return "Failed to fetch vehicle data."
        case .failedToUpdateStatus:
            return "Failed to update vehicle status."
        case .invalidResponse:
            return "Received an invalid response from the server."
        case .tokenRefreshFailed:
            return "Failed to refresh the token."
        }
    }
}

struct VehicleData: Codable {
    let vin: String
    let model: String
    let year: Int
    let mileage: Int
}

public struct VehicleSummary: Codable {
    let vin: String
    let model: String
}

struct VehicleStatusUpdate: Codable {
    let status: String
}
