//
//  LocationManager.swift
//  MapKitDemo-SwiftUI
//
//  Created by Aditya on 25/10/25.
//

import SwiftUI
import Combine
import MapKit
import CoreLocation

class LocationManager: NSObject, ObservableObject {
    
    // MARK: Variables
    private let manager = CLLocationManager()
    @Published var userLocation: CLLocationCoordinate2D?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    // MARK: Init
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    // MARK: Methods
    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }
}

// MARK: CLLocationManager Delegate Methods
extension LocationManager: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        self.authorizationStatus = manager.authorizationStatus
        switch authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
        default:
            manager.stopUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        userLocation = locations.last?.coordinate
    }
}
