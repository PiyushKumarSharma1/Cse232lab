//
//  MapViewModel.swift
//  ServiceMapCustomer
//

import Foundation
import MapKit
import CoreLocation

@MainActor
class MapViewModel: ObservableObject {
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 42.3314, longitude: -83.0458), // Detroit, MI
        span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2)
    )
    
    @Published var providers: [ProviderProfile] = []
    @Published var selectedProvider: ProviderProfile?
    @Published var selectedCategory: String?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    let categories = [
        "Cleaning",
        "Lawn Care",
        "Auto Detail",
        "Handyman",
        "Painting",
        "Moving",
        "Pest Control",
        "HVAC",
        "Roofing",
        "Flooring",
        "Appliance Repair",
        "Locksmith",
        "Photography",
        "Tutoring",
        "Personal Training",
        "Massage",
        "Hair Salon",
        "Pet Grooming",
        "Childcare",
        "Computer Repair"
    ]
    
    private let apiService = APIService.shared
    private let locationManager = CLLocationManager()
    
    init() {
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        if let location = locationManager.location {
            updateRegion(for: location.coordinate)
        }
    }
    
    func centerOnCurrentLocation() {
        if let location = locationManager.location {
            updateRegion(for: location.coordinate)
        } else {
            // Default to Detroit
            updateRegion(for: CLLocationCoordinate2D(latitude: 42.3314, longitude: -83.0458))
        }
    }
    
    private func updateRegion(for coordinate: CLLocationCoordinate2D) {
        withAnimation {
            region = MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            )
        }
    }
    
    func loadProviders() async {
        isLoading = true
        errorMessage = nil
        
        defer {
            isLoading = false
        }
        
        do {
            let fetchedProviders = try await apiService.getNearbyProviders(
                latitude: region.center.latitude,
                longitude: region.center.longitude,
                radius: 25,
                category: selectedCategory?.lowercased().replacingOccurrences(of: " ", with: "_")
            )
            
            self.providers = fetchedProviders
        } catch {
            self.errorMessage = "Failed to load providers: \(error.localizedDescription)"
        }
    }
    
    func filterByCategory(_ category: String?) {
        selectedCategory = category
        Task {
            await loadProviders()
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension MapViewModel: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        
        Task { @MainActor in
            updateRegion(for: location.coordinate)
            await loadProviders()
        }
    }
    
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
        case .denied, .restricted:
            // Handle permission denied
            break
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        @unknown default:
            break
        }
    }
}
