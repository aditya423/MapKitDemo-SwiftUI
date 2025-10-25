//
//  MapView.swift
//  MapKitDemo-SwiftUI
//
//  Created by Aditya on 25/10/25.
//

import SwiftUI
import MapKit
import Combine

struct MapView: View {
    private static let defaultCenter: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 19.2062, longitude: 72.8485)
    private static let span: MKCoordinateSpan = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    @StateObject private var locationManager: LocationManager = LocationManager()
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(center: MapView.defaultCenter, span: MapView.span)
    )
    @State private var lastLocation: CLLocationCoordinate2D?
    @State private var annotationCoordinate: CLLocationCoordinate2D = MapView.defaultCenter
    @State private var searchText: String = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var selectedMapItem: MKMapItem?
    
    var body: some View {
        ZStack(alignment: .top) {
            Map(position: $cameraPosition, selection: $selectedMapItem) {
                // Marker - for custom image
                // Annotation - for custom view
                Annotation("Current Location", coordinate: annotationCoordinate) {
                    ZStack {
                        Circle().frame(width: 32, height: 32).foregroundStyle(.blue.opacity(0.25))
                        Circle().frame(width: 20, height: 20).foregroundStyle(.white)
                        Circle().frame(width: 12, height: 12).foregroundStyle(.blue)
                    }
                }
                
                ForEach(searchResults, id: \.self) { item in
                    if #available(iOS 26.0, *) {
                        Marker(item.name ?? "", coordinate: item.location.coordinate)
                    } else {
                        Marker(item.name ?? "", coordinate: item.placemark.coordinate)
                    }
                }
            }
            .mapControls {
                MapCompass()
                MapPitchToggle()
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
            
            TextField("Search for a location", text: $searchText)
                .font(.subheadline)
                .padding()
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding([.top, .bottom], 12)
                .padding([.leading, .trailing], 70)
                .shadow(radius: 5)
                .onSubmit {
                    Task {
                        searchResults = await locationManager.searchPlaces(text: searchText, region: cameraPosition.region ?? MKCoordinateRegion(center: MapView.defaultCenter, span: MapView.span))
                    }
                }
        }
        .onAppear {
            locationManager.requestPermission()
        }
        .onReceive(locationManager.$userLocation.compactMap { $0 }) { newLocation in
            withAnimation {
                cameraPosition = .region(
                    MKCoordinateRegion(center: newLocation, span: MapView.span)
                )
                annotationCoordinate = newLocation
            }
        }
        .onChange(of: selectedMapItem) { oldValue, newValue in
            print("present sheet")
        }
    }
}

#Preview {
    MapView()
}
