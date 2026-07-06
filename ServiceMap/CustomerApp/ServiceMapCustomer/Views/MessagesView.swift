//
//  MessagesView.swift
//  ServiceMapCustomer
//

import SwiftUI

struct MessagesView: View {
    @StateObject private var viewModel = MessagesViewModel()
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.conversations.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "message")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        
                        Text("No messages yet")
                            .font(.headline)
                        
                        Text("Messages with providers will appear here")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                } else {
                    List(viewModel.conversations) { conversation in
                        NavigationLink(destination: ChatView(conversation: conversation)) {
                            HStack(spacing: 12) {
                                Image(systemName: "person.crop.circle")
                                    .font(.title)
                                    .foregroundColor(.blue)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(conversation.providerName)
                                        .font(.headline)
                                    
                                    Text(conversation.lastMessage)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                                
                                Spacer()
                                
                                VStack(spacing: 4) {
                                    Text(conversation.timeAgo)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    if !conversation.isRead {
                                        Circle()
                                            .fill(Color.blue)
                                            .frame(width: 8, height: 8)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("Messages")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct ChatView: View {
    let conversation: Conversation
    @StateObject private var viewModel = ChatViewModel()
    @State private var messageText = ""
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Messages list
            ScrollViewReader { proxy in
                ScrollView {
                    ForEach(viewModel.messages) { message in
                        MessageBubble(message: message, isCurrentUser: message.senderId == "current")
                    }
                    .id("messages")
                }
                .onAppear {
                    proxy.scrollTo("messages", anchor: .bottom)
                }
            }
            
            Divider()
            
            // Input field
            HStack(spacing: 12) {
                TextField("Type a message...", text: $messageText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .focused($isInputFocused)
                
                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                        .font(.title2)
                        .foregroundColor(messageText.isEmpty ? .gray : .blue)
                }
                .disabled(messageText.isEmpty)
            }
            .padding()
            .background(Color(.systemBackground))
        }
        .navigationTitle(conversation.providerName)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadMessages(for: conversation.id)
        }
    }
    
    private func sendMessage() {
        guard !messageText.isEmpty else { return }
        
        Task {
            try? await viewModel.sendMessage(
                to: conversation.providerId,
                content: messageText,
                bookingId: conversation.bookingId
            )
            messageText = ""
        }
    }
}

struct MessageBubble: View {
    let message: Message
    let isCurrentUser: Bool
    
    var body: some View {
        HStack {
            if !isCurrentUser {
                Spacer()
            }
            
            Text(message.content)
                .padding(12)
                .background(isCurrentUser ? Color.blue : Color.gray.opacity(0.2))
                .foregroundColor(isCurrentUser ? .white : .primary)
                .cornerRadius(16)
                .frame(maxWidth: 300, alignment: isCurrentUser ? .trailing : .leading)
            
            if isCurrentUser {
                Spacer()
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
}

#Preview {
    MessagesView()
        .environmentObject(AppState())
}
