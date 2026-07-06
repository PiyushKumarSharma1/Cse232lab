//
//  Models.swift
//  ServiceMapCustomer
//

import Foundation

// MARK: - User

struct User: Codable, Identifiable {
    let id: String
    let email: String
    let firstName: String
    let lastName: String
    let phone: String?
    let role: UserRole
    let avatarUrl: String?
    let isEmailVerified: Bool
    let isPhoneVerified: Bool
}

enum UserRole: String, Codable {
    case customer
    case provider
    case admin
}

// MARK: - Auth Response

struct AuthResponse: Codable {
    let user: User
    let token: String
    let refreshToken: String
}

// MARK: - Provider Profile

struct ProviderProfile: Codable, Identifiable {
    let id: String
    let userId: String
    let businessName: String
    let description: String?
    let category: String
    let categories: [String]
    let serviceRadiusKm: Double
    let latitude: Double
    let longitude: Double
    let address: String
    let city: String
    let state: String
    let zipCode: String
    let isGhost: Bool
    let status: ProviderStatus
    let rating: Double
    let reviewCount: Int
    let completionRate: Double
    let responseTimeMinutes: Int?
    let verified: Bool
    let backgroundCheckPassed: Bool
    let insuranceVerified: Bool
    let videoVerified: Bool
    let requestCount: Int
    let totalJobs: Int
    let totalRevenue: Double
    
    var displayName: String {
        businessName.isEmpty ? "\(category) Provider" : businessName
    }
    
    var distanceText: String {
        // Calculate based on current location (implemented in ViewModel)
        return "0.5 mi"
    }
}

enum ProviderStatus: String, Codable {
    case pending
    case active
    case suspended
    case inactive
}

// MARK: - Service

struct ServiceItem: Codable, Identifiable {
    let id: String
    let providerId: String
    let name: String
    let description: String?
    let category: String
    let priceType: PriceType
    let price: Double?
    let priceMin: Double?
    let priceMax: Double?
    let duration: Int?
    let isActive: Bool
    
    var displayPrice: String {
        switch priceType {
        case .fixed:
            return "$\(price ?? 0)"
        case .hourly:
            return "$\(price ?? 0)/hr"
        case .range:
            return "$\(Int(priceMin ?? 0)) - $\(Int(priceMax ?? 0))"
        case .quote:
            return "Request Quote"
        }
    }
}

enum PriceType: String, Codable {
    case fixed
    case hourly
    case range
    case quote
}

// MARK: - Booking

struct Booking: Codable, Identifiable {
    let id: String
    let customerId: String
    let providerId: String
    let serviceId: String
    let status: BookingStatus
    let scheduledAt: Date
    let serviceAddress: String
    let serviceLatitude: Double
    let serviceLongitude: Double
    let notes: String?
    let subtotal: Double
    let platformFee: Double
    let buyerServiceFee: Double
    let serviceGuaranteeFee: Double?
    let total: Double
    let commissionAmount: Double
    let paymentIntentId: String?
    let payoutId: String?
    let completedAt: Date?
    let disputeDeadlineAt: Date?
    let cancelledAt: Date?
    let cancelReason: String?
    
    var statusDisplay: String {
        switch status {
        case .pending: return "Pending"
        case .accepted: return "Accepted"
        case .declined: return "Declined"
        case .scheduled: return "Scheduled"
        case .enRoute: return "En Route"
        case .inProgress: return "In Progress"
        case .completed: return "Completed"
        case .disputed: return "Disputed"
        case .cancelled: return "Cancelled"
        }
    }
}

enum BookingStatus: String, Codable {
    case pending
    case accepted
    case declined
    case scheduled
    case enRoute = "en_route"
    case inProgress = "in_progress"
    case completed
    case disputed
    case cancelled
}

// MARK: - Review

struct Review: Codable, Identifiable {
    let id: String
    let bookingId: String
    let customerId: String
    let providerId: String
    let rating: Int
    let comment: String?
    let photos: [String]?
    let isAnonymous: Bool
    let providerResponse: String?
    let providerResponseAt: Date?
    let createdAt: Date
}

// MARK: - Message

struct Message: Codable, Identifiable {
    let id: String
    let bookingId: String?
    let senderId: String
    let receiverId: String
    let content: String
    let type: MessageType
    let mediaUrl: String?
    let isRead: Bool
    let readAt: Date?
    let createdAt: Date
}

enum MessageType: String, Codable {
    case text
    case image
    case file
}

// MARK: - Location

struct Location: Codable {
    let latitude: Double
    let longitude: Double
    let address: String
}

// MARK: - API Error

struct APIError: Codable, Error {
    let error: String
    let details: [String]?
}
