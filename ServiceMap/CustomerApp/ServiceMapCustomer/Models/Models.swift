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
    
    // Provider Tier & AI Features
    let providerTier: ProviderTier
    let lastTransactionDate: Date?
    let totalLifetimeTransactions: Int
    let consecutiveMonthsZeroTransactions: Int
    let aiFeaturesUnlocked: AIFeatures
    
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
    
    // Helper to check if a specific AI feature is unlocked
    func isFeatureUnlocked(_ feature: AIFeature) -> Bool {
        switch feature {
        case .autoInvoice: return aiFeaturesUnlocked.autoInvoice
        case .aiScheduler: return aiFeaturesUnlocked.aiScheduler
        case .autoBookingAgent: return aiFeaturesUnlocked.autoBookingAgent
        case .revenueForecast: return aiFeaturesUnlocked.revenueForecast
        case .taxAssistant: return aiFeaturesUnlocked.taxAssistant
        case .winBackCampaigns: return aiFeaturesUnlocked.winBackCampaigns
        case .supplyAgent: return aiFeaturesUnlocked.supplyAgent
        case .marketingAgent: return aiFeaturesUnlocked.marketingAgent
        }
    }
}

enum ProviderStatus: String, Codable {
    case pending
    case active
    case suspended
    case inactive
}

enum ProviderTier: String, Codable {
    case new
    case basic
    case active
    case elite
}

struct AIFeatures: Codable {
    var autoInvoice: Bool = false
    var aiScheduler: Bool = false
    var autoBookingAgent: Bool = false
    var revenueForecast: Bool = false
    var taxAssistant: Bool = false
    var winBackCampaigns: Bool = false
    var supplyAgent: Bool = false
    var marketingAgent: Bool = false
}

enum AIFeature: String, CaseIterable {
    case autoInvoice = "Auto Invoice"
    case aiScheduler = "AI Scheduler"
    case autoBookingAgent = "Auto Booking Agent"
    case revenueForecast = "Revenue Forecast"
    case taxAssistant = "Tax Assistant"
    case winBackCampaigns = "Win-Back Campaigns"
    case supplyAgent = "Supply Agent"
    case marketingAgent = "Marketing Agent"
    
    var unlockRequirement: String {
        switch self {
        case .autoInvoice: return "1 completed job"
        case .aiScheduler: return "3 completed jobs"
        case .autoBookingAgent: return "5 completed jobs"
        case .revenueForecast: return "5 completed jobs"
        case .taxAssistant: return "10 completed jobs"
        case .winBackCampaigns: return "10 completed jobs"
        case .supplyAgent: return "20 completed jobs"
        case .marketingAgent: return "20 completed jobs"
        }
    }
    
    var description: String {
        switch self {
        case .autoInvoice: return "Automatically generate professional invoices after each job"
        case .aiScheduler: return "AI-powered schedule optimization to minimize drive time"
        case .autoBookingAgent: return "Let AI automatically accept bookings that match your rules"
        case .revenueForecast: return "Predictive earnings forecasts and business insights"
        case .taxAssistant: return "Track expenses, mileage, and generate tax reports"
        case .winBackCampaigns: return "Automatically re-engage past customers"
        case .supplyAgent: return "Smart supply ordering with affiliate discounts"
        case .marketingAgent: return "Auto-generate social media posts from your work"
        }
    }
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
