// Placeholder views - full implementation in progress
import SwiftUI

struct BookingsView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("My Bookings")
                    .font(.headline)
                Spacer()
            }
            .navigationTitle("Bookings")
        }
    }
}

struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationView {
            VStack {
                if let user = appState.currentUser {
                    Text("\(user.firstName) \(user.lastName)")
                        .font(.headline)
                    Text(user.email)
                        .foregroundColor(.secondary)
                }
                
                Button(action: {
                    appState.logout()
                }) {
                    Text("Sign Out")
                        .foregroundColor(.red)
                }
                .padding()
                
                Spacer()
            }
            .navigationTitle("Profile")
        }
    }
}

struct ProviderDetailView: View {
    let provider: ProviderProfile
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                Text(provider.displayName)
                    .font(.title)
                    .fontWeight(.bold)
                
                Text(provider.category)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                // Rating
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                    Text("\(String(format: "%.1f", provider.rating)) (\(provider.reviewCount) reviews)")
                }
                
                // Description
                if let description = provider.description {
                    Text(description)
                        .font(.body)
                }
                
                // Services would go here
                
                // Booking button
                if provider.isGhost {
                    Button(action: {
                        // Request provider
                    }) {
                        Text("Request Service")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                } else {
                    NavigationLink(destination: BookingView(provider: provider)) {
                        Text("Book Now")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Provider Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct BookingView: View {
    let provider: ProviderProfile
    
    var body: some View {
        Text("Booking flow for \(provider.displayName)")
    }
}
