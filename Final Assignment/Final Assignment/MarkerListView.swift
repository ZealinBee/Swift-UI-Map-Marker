//
//  MarkerListView.swift
//  Final Assignment
//
//  Created by Zhiyuan Liu on 5.12.2024.
//
import SwiftUI
import MapKit
import CoreLocation

struct MarkerListView: View {
    let markers: [AppMarker]
    let onMarkerSelect: (CLLocationCoordinate2D) -> Void
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            List {
                ForEach(markers) { marker in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(marker.name)
                                .font(.headline)
                            Text("Latitude: \(marker.coordinate.latitude)")
                                .font(.subheadline)
                            Text("Longitude: \(marker.coordinate.longitude)")
                                .font(.subheadline)
                        }
                        Spacer()
                        Button(action: {
                            // Center the map on the selected marker
                            onMarkerSelect(marker.coordinate)
                            // Close the sheet
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Image(systemName: "location.circle.fill")
                                .font(.title2)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Markers")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
