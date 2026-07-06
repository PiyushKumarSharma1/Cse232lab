//
//  MapView.swift
//  ServiceMapCustomer
//

import SwiftUI
import MapKit

struct MapView: View {
    @StateObject private var viewModel = MapViewModel()
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationView {
            ZStack {
                // Map
                Map(coordinateRegion: $viewModel.region, annotationItems: viewModel.providers) { provider in
                    MapAnnotation(coordinate: CLLocationCoordinate2D(latitude: provider.latitude, longitude: provider.longitude)) {
                        ProviderPin(provider: provider)
                            .onTapGesture {
                                viewModel.selectedProvider = provider
                            }
                    }
                }
                
                // Bottom sheet for selected provider
                if let provider = viewModel.selectedProvider {
                    ProviderBottomSheet(provider: provider)
                        .transition(.move(edge: .bottom))
                }
                
                // Category filter chips
                VStack {
                    HStack {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                FilterChip(title: "All", isSelected: viewModel.selectedCategory == nil) {
                                    viewModel.selectedCategory = nil
                                }
                                
                                ForEach(viewModel.categories, id: \.self) { category in
                                    FilterChip(title: category, isSelected: viewModel.selectedCategory == category) {
                                        viewModel.selectedCategory = category
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(12)
                        .shadow(radius: 4)
                    }
                    
                    Spacer()
                }
            }
            .navigationTitle("Nearby Services")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        viewModel.centerOnCurrentLocation()
                    }) {
                        Image(systemName: "location.fill")
                    }
                }
            }
            .task {
                await viewModel.loadProviders()
            }
        }
    }
}

// MARK: - Provider Pin

struct ProviderPin: View {
    let provider: ProviderProfile
    
    var body: some View {
        VStack {
            Circle()
                .fill(provider.isGhost ? Color.gray : Color.blue)
                .frame(width: 16, height: 16)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 2)
                )
            
            if !provider.isGhost {
                Text("⭐ \(String(format: "%.1f", provider.rating))")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(4)
            }
        }
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color.gray.opacity(0.2))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

// MARK: - Provider Bottom Sheet

struct ProviderBottomSheet: View {
    let provider: ProviderProfile
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading) {
                    Text(provider.displayName)
                        .font(.headline)
                    
                    Text(provider.category)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text("\(String(format: "%.1f", provider.rating)) (\(provider.reviewCount) reviews)")
                            .font(.caption)
                    }
                    
                    Text("📍 \(provider.distanceText)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
            }
            
            HStack(spacing: 12) {
                if provider.isGhost {
                    Button(action: {
                        // Request provider
                    }) {
                        Label("Request", systemImage: "paperplane")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                } else {
                    NavigationLink(destination: ProviderDetailView(provider: provider)) {
                        Label("View Profile", systemImage: "eye")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(radius: 10)
        .padding()
    }
}

#Preview {
    MapView()
        .environmentObject(AppState())
}
