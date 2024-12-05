//
//  ContentView.swift
//  Final Assignment
//
//  Created by Zhiyuan Liu on 2.12.2024.
//

import SwiftUI
import MapKit
import CoreLocation


struct ContentView: View {
    @State private var viewModel = ContentViewModel()
    @State private var isPromptingForLocation = true
    @State var position: MapCameraPosition = .region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 61.49, longitude: 23.75),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    ))
    @State private var markers : [AppMarker] = []
    @State private var newMarkerCoordinate: CLLocationCoordinate2D?
    @State private var newMarkerPrompt = false
    @State private var markerName = ""
    @State private var showMarkersList = false
    @State private var showDuplicateAlertPrompt = false
    private var latOffset = -0.0675

    var body: some View {
        ZStack {
            MapReader { proxy in
                Map(position: $position) {
                    ForEach(markers) { marker in
                        Marker(marker.name, coordinate: marker.coordinate)
                    }
                    UserAnnotation()
                }
                .edgesIgnoringSafeArea(.all)
                .onAppear {
                    viewModel.checkIfLocationServicesIsEnabled()
                    loadMarkers()
                }
                .onMapCameraChange { context in
                    position = MapCameraPosition.region(
                        MKCoordinateRegion(
                            center: context.region.center,
                            span: context.region.span
                        )
                    )
                }
                .onTapGesture { location in
            

                    if let coordinate = proxy.convert(location, from: .global) {
                        guard let span = position.region?.span else {return }
                        
                        let adjustedCoordinate = CLLocationCoordinate2D(
                            latitude: coordinate.latitude + latOffset * span.latitudeDelta ,
                            longitude: coordinate.longitude
                        )
                        
                        newMarkerCoordinate = adjustedCoordinate
                        newMarkerPrompt = true
                    }
                }
                .alert("New Marker", isPresented: $newMarkerPrompt) {
                    TextField("Put the name for the location", text: $markerName)
                    Button("Add", action: addMarker)
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("Please enter a name for this marker.")
                }
                .alert(isPresented: $showDuplicateAlertPrompt) {
                    Alert(
                        title: Text("Duplicate Marker Name"),
                        message: Text("A marker with this name already exists. Please choose a different name."),
                        dismissButton: .default(Text("OK"))
                    )
                }
            }
            
            // Floating button in the bottom-right corner
            VStack {
                Spacer() // Push the button to the bottom
                HStack {
                    Spacer() // Push the button to the right
                    Button(action: storeUserLocation) {
                        Text("Save Current Location")
                            .font(.system(size: 18))
                            .foregroundColor(.green)
                            .padding()
                            .background(Color.white)
                            .clipShape(Capsule()) // Using Capsule for rounded edges
                            .shadow(radius: 4)
                    }
                    .padding(.trailing, 8)
                    Button(action: showUserLocation) {
                        Image(systemName: "location")
                            .font(.system(size: 24))
                            .foregroundColor(.green)
                            .padding()
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(radius: 4)
                    }
                    .padding(.trailing, 8)
                    Button(action: { showMarkersList.toggle() }) {
                        Image(systemName: "folder")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .clipShape(Circle())
                            .shadow(radius: 4)
                    }
                    .padding()
                    
                    
                    Button(action: clearAllMarkers) {
                        Image(systemName: "trash")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.red)
                            .clipShape(Circle())
                            .shadow(radius: 4)
                    }
                    .padding()
                }
            }
            .sheet(isPresented: $showMarkersList) {
                MarkerListView(markers: markers) { selectedCoordinate in
                    moveToLocation(selectedCoordinate)
                }
            }
        }
    }
    private func addMarker() {
        guard let coordinate = newMarkerCoordinate, !markerName.isEmpty else {return }
        let newMarker = AppMarker(name: markerName, coordinate: coordinate)
        if(markers.contains(where: {$0.name == markerName})) {
            showDuplicateAlertPrompt = true
            return
        }
        markers.append(newMarker)
        markerName = ""
        newMarkerCoordinate = nil
        
        saveMarkers(markers: markers)
    }
    
    private func saveMarkers(markers: [AppMarker]) {
        let ids = markers.map { $0.id.uuidString }
        let names = markers.map { $0.name }
        let latitudes = markers.map { $0.coordinate.latitude }
        let longitudes = markers.map { $0.coordinate.longitude }
        
        UserDefaults.standard.set(ids, forKey: "markerIDs")
        UserDefaults.standard.set(names, forKey: "markerNames")
        UserDefaults.standard.set(latitudes, forKey: "markerLatitudes")
        UserDefaults.standard.set(longitudes, forKey: "markerLongitudes")
    }
    
    private func loadMarkers() {
        // Retrieve data from UserDefaults
            let ids = UserDefaults.standard.stringArray(forKey: "markerIDs") ?? []
            let names = UserDefaults.standard.stringArray(forKey: "markerNames") ?? []
            let latitudes = UserDefaults.standard.array(forKey: "markerLatitudes") as? [Double] ?? []
            let longitudes = UserDefaults.standard.array(forKey: "markerLongitudes") as? [Double] ?? []
            
            // Check if all arrays have the same count
            guard ids.count == names.count, ids.count == latitudes.count, ids.count == longitudes.count else {
                print("Error: Mismatched data lengths in UserDefaults.")
                return
            }
            
            // Clear existing markers
            markers.removeAll()
            
            // Loop through the data and create markers
            for i in 0..<ids.count {
                let coordinate = CLLocationCoordinate2D(latitude: latitudes[i], longitude: longitudes[i])
                let marker = AppMarker(name: names[i], coordinate: coordinate)
                markers.append(marker)
            }
    }
    
    private func clearAllMarkers() {
        UserDefaults.standard.removeObject(forKey: "markerIDs")
        UserDefaults.standard.removeObject(forKey: "markerNames")
        UserDefaults.standard.removeObject(forKey: "markerLatitudes")
        UserDefaults.standard.removeObject(forKey: "markerLongitudes")
        markers.removeAll()
    }
    
    private func moveToLocation(_ coordinate: CLLocationCoordinate2D) {
        position = MapCameraPosition.region(
            MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        )
    }
    
    private func showUserLocation() {
        position = viewModel.userLocation
    }
    
    private func storeUserLocation() {
        guard let lastKnownCoordinates = viewModel.lastKnownCoordinates else {return }
        let newMarker = AppMarker(name: "Users Location", coordinate: lastKnownCoordinates)
        if(markers.contains(where: {$0.name == "Users Location"})) {
            showDuplicateAlertPrompt = true
            return
        }
        markers.append(newMarker)
    }
}


final class ContentViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    var locationManager: CLLocationManager?
    @Published var userLocation = MapCameraPosition.region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 61.5, longitude: 23.8),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    ))
    @Published var lastKnownCoordinates: CLLocationCoordinate2D?
    
    func checkIfLocationServicesIsEnabled() {
        if CLLocationManager.locationServicesEnabled() {
            locationManager = CLLocationManager()
            locationManager!.delegate = self
            locationManager?.startUpdatingLocation()
        }else {
            print("Your location service is off")
        }
    }
    
    private func checkLocationAuthorization() {
        guard let locationManager = locationManager else {return }
        
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .restricted:
            print("location is restricted because oops")
        case .denied:
            print("womp then no using this app")
        case .authorizedAlways, .authorizedWhenInUse:
            lastKnownCoordinates = locationManager.location?.coordinate
        @unknown default:
            break
            
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        checkLocationAuthorization()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.last else {return }
        DispatchQueue.main.async {
            self.userLocation = MapCameraPosition.region(MKCoordinateRegion(
                   center: newLocation.coordinate,
                   span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
               ))
           }
    }
}


struct AppMarker: Identifiable{
    let id = UUID()
    let name: String
    let coordinate: CLLocationCoordinate2D
}

#Preview {
    ContentView()
}
