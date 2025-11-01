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
    
    // MARK: Variables
    private static let defaultCenter: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
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
    @State private var showDetails: Bool = false
    @State private var isGetDirections: Bool = false
    @State private var isRouteDisplaying: Bool = false
    @State private var route: MKRoute?
    @State private var routeDestination: MKMapItem?
    
    // MARK: Body
    var body: some View {
        ZStack(alignment: .top) {
            
            // Map
            mapContent
            .mapControls {
                MapCompass()
                MapPitchToggle()
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
            
            VStack {
                // Search textfield
                searchBar
                
                Spacer()
                
                // Reset buttons
                resetButtons
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
            showDetails = newValue != nil
        }
        .onChange(of: isGetDirections) { oldValue, newValue in
            if newValue {
                fetchRoute()
            }
        }
        .sheet(isPresented: $showDetails) {
            LocationDetails(selectedMapItem: $selectedMapItem, isShow: $showDetails, isGetDirections: $isGetDirections)
                .presentationDetents([.height(340)])
                .presentationBackgroundInteraction(.enabled(upThrough: .height(340)))
                .presentationCornerRadius(FloatConstants.cornerRadius.rawValue)
        }
    }
}

// MARK: MapView SubViews
extension MapView {
    private var mapContent: some View {
        Map(position: $cameraPosition, selection: $selectedMapItem) {
            // Annotation - for custom view
            Annotation(StringConstants.annotation.rawValue, coordinate: annotationCoordinate) {
                ZStack {
                    Circle().frame(width: 32, height: 32).foregroundStyle(.blue.opacity(0.25))
                    Circle().frame(width: 20, height: 20).foregroundStyle(.white)
                    Circle().frame(width: 12, height: 12).foregroundStyle(.blue)
                }
            }
            // Marker - for custom image
            ForEach(searchResults, id: \.self) { item in
                if isRouteDisplaying {
                    if item == routeDestination {
                        if #available(iOS 26.0, *) {
                            Marker(item.name ?? "", coordinate: item.location.coordinate)
                        } else {
                            Marker(item.name ?? "", coordinate: item.placemark.coordinate)
                        }
                    }
                } else {
                    if #available(iOS 26.0, *) {
                        Marker(item.name ?? "", coordinate: item.location.coordinate)
                    } else {
                        Marker(item.name ?? "", coordinate: item.placemark.coordinate)
                    }
                }
            }
            if let route {
                MapPolyline(route.polyline)
                    .stroke(.blue, lineWidth: 5)
            }
        }
    }
    
    private var searchBar: some View {
        TextField(StringConstants.searchPlaceholder.rawValue, text: $searchText)
            .font(.subheadline)
            .padding()
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: FloatConstants.cornerRadius.rawValue))
            .padding([.top, .bottom], 12)
            .padding([.leading, .trailing], 70)
            .shadow(radius: 5)
            .onSubmit {
                Task {
                    searchResults = await searchPlaces()
                }
            }
    }
    
    private var resetButtons: some View {
        HStack {
            if cameraPosition != .region(
                MKCoordinateRegion(center: locationManager.userLocation ?? MapView.defaultCenter, span: MapView.span)
            ) {
                CustomButtonView(title: ButtonTitles.recenter.rawValue, bgColor: .green) {
                    resetCamera()
                }
            }
            if !searchResults.isEmpty {
                CustomButtonView(title: ButtonTitles.reset.rawValue, bgColor: .red) {
                    resetMap()
                }
            }
        }
        .padding([.top, .bottom], 12)
        .padding([.leading, .trailing], 70)
        .shadow(radius: 5)
    }
}

// MARK: MapView Methods
extension MapView {
    func searchPlaces() async -> [MKMapItem] {
        let request = MKLocalSearch.Request()
        request.region = cameraPosition.region ?? MKCoordinateRegion(center: MapView.defaultCenter, span: MapView.span)
        request.naturalLanguageQuery = searchText
        let results = try? await MKLocalSearch(request: request).start()
        return results?.mapItems ?? []
    }
    
    func fetchRoute() {
        if let selectedMapItem {
            let request = MKDirections.Request()
            request.source = MKMapItem(placemark: .init(coordinate: cameraPosition.region?.center ?? MapView.defaultCenter))
            request.destination = selectedMapItem
            Task {
                let results = try? await MKDirections(request: request).calculate()
                route = results?.routes.first
                routeDestination = selectedMapItem
                withAnimation(.snappy) {
                    isRouteDisplaying = true
                    showDetails = false
                    if let polyline = route?.polyline, isRouteDisplaying {
                        var rect = polyline.boundingMapRect
                        let insetRatio = 0.2
                        let widthInset = rect.size.width * insetRatio
                        let heightInset = rect.size.height * insetRatio
                        rect = rect.insetBy(dx: -widthInset, dy: -heightInset)
                        cameraPosition = .rect(rect)
                    }
                }
            }
        }
    }
    
    func resetCamera() {
        withAnimation(.snappy) {
            let userLocation = locationManager.userLocation ?? MapView.defaultCenter
            cameraPosition = .region(
                MKCoordinateRegion(center: userLocation, span: MapView.span)
            )
            annotationCoordinate = userLocation
        }
    }
    
    func resetMap() {
        withAnimation(.snappy) {
            let userLocation = locationManager.userLocation ?? MapView.defaultCenter
            cameraPosition = .region(
                MKCoordinateRegion(center: userLocation, span: MapView.span)
            )
            annotationCoordinate = userLocation
            searchResults.removeAll()
            selectedMapItem = nil
            route = nil
            routeDestination = nil
            isRouteDisplaying = false
            isGetDirections = false
            showDetails = false
            searchText = ""
        }
    }
}

#Preview {
    MapView()
}
