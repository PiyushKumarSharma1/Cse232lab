//
//  MessagesViewModel.swift
//  ServiceMapCustomer
//

import Foundation

struct Conversation: Identifiable {
    let id: String
    let bookingId: String?
    let providerId: String
    let providerName: String
    let lastMessage: String
    let timeAgo: String
    let isRead: Bool
}

@MainActor
class MessagesViewModel: ObservableObject {
    @Published var conversations: [Conversation] = []
    
    private let apiService = APIService.shared
    
    init() {
        Task {
            await loadConversations()
        }
    }
    
    func loadConversations() async {
        // Load from API - for now using mock data
        conversations = [
            Conversation(
                id: "1",
                bookingId: "booking-1",
                providerId: "provider-1",
                providerName: "Mike's Cleaning Service",
                lastMessage: "I'll be there at 2pm tomorrow",
                timeAgo: "5m",
                isRead: false
            ),
            Conversation(
                id: "2",
                bookingId: "booking-2",
                providerId: "provider-2",
                providerName: "Detroit Lawn Care",
                lastMessage: "Thanks for booking!",
                timeAgo: "1h",
                isRead: true
            )
        ]
    }
}

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    
    private let apiService = APIService.shared
    
    func loadMessages(for conversationId: String) async {
        do {
            let fetchedMessages = try await apiService.getMessages(bookingId: conversationId)
            self.messages = fetchedMessages
        } catch {
            print("Error loading messages: \(error)")
        }
    }
    
    func sendMessage(to receiverId: String, content: String, bookingId: String?) async throws {
        let request = CreateMessageRequest(
            bookingId: bookingId,
            receiverId: receiverId,
            content: content,
            type: .text
        )
        
        let message = try await apiService.sendMessage(message: request)
        messages.append(message)
        
        // Also send via WebSocket for real-time delivery
        SocketService.shared.sendMessage(
            receiverId: receiverId,
            content: content,
            bookingId: bookingId
        )
    }
}
