//
//  SearchView.swift
//  ServiceMapCustomer
//

import SwiftUI

struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Search services...", text: $searchText)
                        .onChange(of: searchText) { newValue in
                            viewModel.search(query: newValue)
                        }
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                            viewModel.clearSearch()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(12)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .padding()
                
                // Category grid
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        ForEach(viewModel.categories, id: \.self) { category in
                            CategoryCard(category: category)
                                .onTapGesture {
                                    viewModel.filterByCategory(category)
                                }
                        }
                    }
                    .padding()
                }
                
                // Results list
                if viewModel.isSearching || !viewModel.results.isEmpty {
                    List {
                        if viewModel.isSearching {
                            ProgressView("Searching...")
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding()
                        } else {
                            ForEach(viewModel.results) { provider in
                                ProviderListRow(provider: provider)
                                    .onTapGesture {
                                        // Navigate to provider detail
                                    }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct CategoryCard: View {
    let category: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: categoryIcon(for: category))
                .font(.system(size: 32))
                .foregroundColor(.blue)
                .frame(width: 60, height: 60)
                .background(Color.blue.opacity(0.1))
                .clipShape(Circle())
            
            Text(category)
                .font(.caption)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    private func categoryIcon(for category: String) -> String {
        switch category {
        case "Cleaning": return "sparkles"
        case "Lawn Care": return "leaf"
        case "Auto Detail": return "car"
        case "Handyman": return "hammer"
        case "Painting": return "paintbrush"
        case "Moving": return "box"
        case "Pest Control": return "ladybug"
        case "HVAC": return "wind"
        case "Roofing": return "house"
        case "Flooring": return "square.grid.2x2"
        case "Appliance Repair": return "wrench"
        case "Locksmith": return "key"
        case "Photography": return "camera"
        case "Tutoring": return "book"
        case "Personal Training": return "figure.run"
        case "Massage": return "hand.wave"
        case "Hair Salon": return "scissors"
        case "Pet Grooming": return "pawprint"
        case "Childcare": return "teddybear"
        case "Computer Repair": return "laptopcomputer"
        default: return "star"
        }
    }
}

struct ProviderListRow: View {
    let provider: ProviderProfile
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.crop.circle")
                .font(.title)
                .foregroundColor(.blue)
                .frame(width: 50, height: 50)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(provider.displayName)
                    .font(.headline)
                
                Text(provider.category)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundColor(.yellow)
                    Text("\(String(format: "%.1f", provider.rating)) (\(provider.reviewCount))")
                        .font(.caption)
                }
                
                Text("📍 \(provider.address)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            if provider.isGhost {
                Text("Request")
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    SearchView()
        .environmentObject(AppState())
}
