//
//  ServiceMapCustomerApp.swift
//  ServiceMap Customer App
//

import SwiftUI

@main
struct ServiceMapCustomerApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
    }
}

// MARK: - App State

class AppState: ObservableObject {
    @Published var isLoggedIn = false
    @Published var currentUser: User?
    @Published var selectedRole: UserRole = .customer
    
    let apiService = APIService.shared
    let socketService = SocketService.shared
    
    init() {
        checkAuthStatus()
    }
    
    func checkAuthStatus() {
        // Check for stored auth token
        if let token = KeychainHelper.loadToken(),
           !token.isEmpty {
            // Validate token and load user
            Task {
                await validateToken(token)
            }
        }
    }
    
    @MainActor
    func validateToken(_ token: String) async {
        do {
            let user = try await apiService.getCurrentUser(token: token)
            self.currentUser = user
            self.isLoggedIn = true
        } catch {
            // Token invalid, clear it
            KeychainHelper.deleteToken()
            self.isLoggedIn = false
        }
    }
    
    func login(email: String, password: String) async throws {
        let result = try await apiService.login(email: email, password: password)
        self.currentUser = result.user
        self.isLoggedIn = true
        
        // Store tokens
        KeychainHelper.saveToken(result.token)
        KeychainHelper.saveRefreshToken(result.refreshToken)
    }
    
    func register(email: String, password: String, firstName: String, lastName: String) async throws {
        let result = try await apiService.register(
            email: email,
            password: password,
            role: .customer,
            firstName: firstName,
            lastName: lastName
        )
        self.currentUser = result.user
        self.isLoggedIn = true
        
        // Store tokens
        KeychainHelper.saveToken(result.token)
        KeychainHelper.saveRefreshToken(result.refreshToken)
    }
    
    func logout() {
        KeychainHelper.deleteToken()
        KeychainHelper.deleteRefreshToken()
        self.currentUser = nil
        self.isLoggedIn = false
    }
}
