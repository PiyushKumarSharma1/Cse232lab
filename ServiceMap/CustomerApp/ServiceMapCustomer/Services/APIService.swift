//
//  APIService.swift
//  ServiceMapCustomer
//

import Foundation
import Combine

class APIService: ObservableObject {
    static let shared = APIService()
    
    private let baseURL: String
    private var authToken: String?
    
    init(baseURL: String = ProcessInfo.processInfo.environment["API_BASE_URL"] ?? "http://localhost:3000/api") {
        self.baseURL = baseURL
    }
    
    func setAuthToken(_ token: String) {
        self.authToken = token
    }
    
    // MARK: - Authentication
    
    func login(email: String, password: String) async throws -> AuthResponse {
        let endpoint = "\(baseURL)/auth/login"
        let body: [String: String] = ["email": email, "password": password]
        
        let response: AuthResponse = try await request(endpoint: endpoint, method: "POST", body: body)
        setAuthToken(response.token)
        return response
    }
    
    func register(email: String, password: String, role: UserRole, firstName: String, lastName: String, phone: String? = nil) async throws -> AuthResponse {
        let endpoint = "\(baseURL)/auth/register"
        let body: [String: Any] = [
            "email": email,
            "password": password,
            "role": role.rawValue,
            "firstName": firstName,
            "lastName": lastName
        ]
        
        let response: AuthResponse = try await request(endpoint: endpoint, method: "POST", body: body)
        setAuthToken(response.token)
        return response
    }
    
    func refreshToken(_ refreshToken: String) async throws -> AuthResponse {
        let endpoint = "\(baseURL)/auth/refresh"
        let body: [String: String] = ["refreshToken": refreshToken]
        
        let response: AuthResponse = try await request(endpoint: endpoint, method: "POST", body: body)
        setAuthToken(response.token)
        return response
    }
    
    func getCurrentUser(token: String) async throws -> User {
        let endpoint = "\(baseURL)/auth/me"
        let response: [String: User] = try await request(endpoint: endpoint, method: "GET", token: token)
        return response["user"]!
    }
    
    // MARK: - Providers
    
    func getNearbyProviders(
        latitude: Double,
        longitude: Double,
        radius: Double = 25,
        category: String? = nil
    ) async throws -> [ProviderProfile] {
        var components = URLComponents(string: "\(baseURL)/providers/nearby")!
        components.queryItems = [
            URLQueryItem(name: "lat", value: "\(latitude)"),
            URLQueryItem(name: "lng", value: "\(longitude)"),
            URLQueryItem(name: "radius", value: "\(radius)")
        ]
        
        if let category = category {
            components.queryItems?.append(URLQueryItem(name: "category", value: category))
        }
        
        return try await request(endpoint: components.url!.absoluteString, method: "GET")
    }
    
    func getProvider(id: String) async throws -> ProviderProfile {
        let endpoint = "\(baseURL)/providers/\(id)"
        return try await request(endpoint: endpoint, method: "GET")
    }
    
    func searchProviders(query: String, category: String? = nil) async throws -> [ProviderProfile] {
        var components = URLComponents(string: "\(baseURL)/providers/search")!
        components.queryItems = [URLQueryItem(name: "q", value: query)]
        
        if let category = category {
            components.queryItems?.append(URLQueryItem(name: "category", value: category))
        }
        
        return try await request(endpoint: components.url!.absoluteString, method: "GET")
    }
    
    func requestProvider(providerId: String, message: String) async throws {
        let endpoint = "\(baseURL)/providers/\(providerId)/request"
        let body: [String: String] = ["message": message]
        try await request(endpoint: endpoint, method: "POST", body: body)
    }
    
    // MARK: - Services
    
    func getServices(providerId: String) async throws -> [ServiceItem] {
        let endpoint = "\(baseURL)/providers/\(providerId)/services"
        return try await request(endpoint: endpoint, method: "GET")
    }
    
    // MARK: - Bookings
    
    func createBooking(booking: CreateBookingRequest) async throws -> Booking {
        let endpoint = "\(baseURL)/bookings"
        return try await request(endpoint: endpoint, method: "POST", body: booking.toDictionary())
    }
    
    func getBookings() async throws -> [Booking] {
        let endpoint = "\(baseURL)/bookings"
        return try await request(endpoint: endpoint, method: "GET")
    }
    
    func getBooking(id: String) async throws -> Booking {
        let endpoint = "\(baseURL)/bookings/\(id)"
        return try await request(endpoint: endpoint, method: "GET")
    }
    
    func cancelBooking(id: String, reason: String) async throws {
        let endpoint = "\(baseURL)/bookings/\(id)/cancel"
        let body: [String: String] = ["reason": reason]
        try await request(endpoint: endpoint, method: "POST", body: body)
    }
    
    func confirmBookingCompletion(id: String) async throws {
        let endpoint = "\(baseURL)/bookings/\(id)/confirm"
        try await request(endpoint: endpoint, method: "POST", body: [:])
    }
    
    func disputeBooking(id: String, reason: String) async throws {
        let endpoint = "\(baseURL)/bookings/\(id)/dispute"
        let body: [String: String] = ["reason": reason]
        try await request(endpoint: endpoint, method: "POST", body: body)
    }
    
    // MARK: - Reviews
    
    func createReview(review: CreateReviewRequest) async throws -> Review {
        let endpoint = "\(baseURL)/reviews"
        return try await request(endpoint: endpoint, method: "POST", body: review.toDictionary())
    }
    
    func getProviderReviews(providerId: String) async throws -> [Review] {
        let endpoint = "\(baseURL)/providers/\(providerId)/reviews"
        return try await request(endpoint: endpoint, method: "GET")
    }
    
    // MARK: - Messages
    
    func getMessages(bookingId: String? = nil) async throws -> [Message] {
        var endpoint = "\(baseURL)/messages"
        if let bookingId = bookingId {
            endpoint += "?bookingId=\(bookingId)"
        }
        return try await request(endpoint: endpoint, method: "GET")
    }
    
    func sendMessage(message: CreateMessageRequest) async throws -> Message {
        let endpoint = "\(baseURL)/messages"
        return try await request(endpoint: endpoint, method: "POST", body: message.toDictionary())
    }
    
    // MARK: - Payment
    
    func createPaymentIntent(bookingId: String) async throws -> PaymentIntentResponse {
        let endpoint = "\(baseURL)/payments/create-intent"
        let body: [String: String] = ["bookingId": bookingId]
        return try await request(endpoint: endpoint, method: "POST", body: body)
    }
    
    // MARK: - Request Helpers
    
    private func request<T: Decodable>(
        endpoint: String,
        method: String,
        body: [String: Any]? = nil,
        token: String? = nil
    ) async throws -> T {
        guard let url = URL(string: endpoint) else {
            throw APIError(error: "Invalid URL", details: nil)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let authToken = token ?? self.authToken {
            request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError(error: "Invalid response", details: nil)
        }
        
        if httpResponse.statusCode >= 400 {
            let error = try? JSONDecoder().decode(APIError.self, from: data)
            throw error ?? APIError(error: "Request failed with status \(httpResponse.statusCode)", details: nil)
        }
        
        return try JSONDecoder().decode(T.self, from: data)
    }
}

// MARK: - Request Models

struct CreateBookingRequest {
    let providerId: String
    let serviceId: String
    let scheduledAt: Date
    let serviceAddress: String
    let serviceLatitude: Double
    let serviceLongitude: Double
    let notes: String?
    let addServiceGuarantee: Bool
    
    func toDictionary() -> [String: Any] {
        return [
            "providerId": providerId,
            "serviceId": serviceId,
            "scheduledAt": ISO8601DateFormatter().string(from: scheduledAt),
            "serviceAddress": serviceAddress,
            "serviceLatitude": serviceLatitude,
            "serviceLongitude": serviceLongitude,
            "notes": notes ?? "",
            "addServiceGuarantee": addServiceGuarantee
        ]
    }
}

struct CreateReviewRequest {
    let bookingId: String
    let rating: Int
    let comment: String?
    let photos: [String]?
    let isAnonymous: Bool
    
    func toDictionary() -> [String: Any] {
        return [
            "bookingId": bookingId,
            "rating": rating,
            "comment": comment ?? "",
            "isAnonymous": isAnonymous
        ]
    }
}

struct CreateMessageRequest {
    let bookingId: String?
    let receiverId: String
    let content: String
    let type: MessageType
    
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "receiverId": receiverId,
            "content": content,
            "type": type.rawValue
        ]
        if let bookingId = bookingId {
            dict["bookingId"] = bookingId
        }
        return dict
    }
}

struct PaymentIntentResponse: Codable {
    let clientSecret: String
    let paymentIntentId: String
}
