//
//  MainTabView.swift
//  ServiceMapCustomer
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            MapView()
                .tabItem {
                    Image(systemName: "map")
                    Text("Map")
                }
                .tag(0)
            
            SearchView()
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("Search")
                }
                .tag(1)
            
            MessagesView()
                .tabItem {
                    Image(systemName: "message")
                    Text("Messages")
                }
                .tag(2)
            
            BookingsView()
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Bookings")
                }
                .tag(3)
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person.circle")
                    Text("Profile")
                }
                .tag(4)
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(AppState())
}
