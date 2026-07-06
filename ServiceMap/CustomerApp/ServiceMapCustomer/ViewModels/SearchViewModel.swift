//
//  SearchViewModel.swift
//  ServiceMapCustomer
//

import Foundation

@MainActor
class SearchViewModel: ObservableObject {
    @Published var results: [ProviderProfile] = []
    @Published var isSearching = false
    @Published var selectedCategory: String?
    
    let categories = [
        "Cleaning", "Lawn Care", "Auto Detail", "Handyman",
        "Painting", "Moving", "Pest Control", "HVAC",
        "Roofing", "Flooring", "Appliance Repair", "Locksmith",
        "Photography", "Tutoring", "Personal Training", "Massage",
        "Hair Salon", "Pet Grooming", "Childcare", "Computer Repair"
    ]
    
    private let apiService = APIService.shared
    
    func search(query: String) {
        guard !query.isEmpty else {
            clearSearch()
            return
        }
        
        isSearching = true
        
        Task {
            do {
                let providers = try await apiService.searchProviders(
                    query: query,
                    category: selectedCategory?.lowercased().replacingOccurrences(of: " ", with: "_")
                )
                self.results = providers
            } catch {
                print("Search error: \(error)")
            }
            
            self.isSearching = false
        }
    }
    
    func filterByCategory(_ category: String) {
        selectedCategory = category
        search(query: "")
    }
    
    func clearSearch() {
        results = []
        isSearching = false
    }
}
