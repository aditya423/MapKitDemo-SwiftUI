//
//  LocationDetails.swift
//  MapKitDemo-SwiftUI
//
//  Created by Aditya on 25/10/25.
//

import SwiftUI
import MapKit

struct LocationDetails: View {
    
    @Binding var selectedMapItem: MKMapItem?
    @Binding var isShow: Bool
    @State private var lookAroundScene: MKLookAroundScene?
    
    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading) {
                    Text(selectedMapItem?.name ?? "")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text(selectedMapItem?.placemark.title ?? "")
                        .font(.footnote)
                        .foregroundStyle(.gray)
                        .lineLimit(3)
                }
                
                Spacer()
                
                Button {
                    isShow.toggle()
                    selectedMapItem = nil
                } label: {
                    Image(systemName: ImageConstants.systemCancel.rawValue)
                        .resizable()
                        .frame(width: 24, height: 24)
                        .foregroundStyle(.gray)
                }
            }
            
            if let lookAroundScene {
                LookAroundPreview(initialScene: lookAroundScene)
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: FloatConstants.cornerRadius.rawValue))
            } else {
                ContentUnavailableView(StringConstants.noPreviewAvailable.rawValue, systemImage: ImageConstants.systemNoPreview.rawValue)
            }
            
            HStack {
                CustomButtonView(title: ButtonTitles.openInMaps.rawValue, bgColor: .green) {
                    if let selectedMapItem {
                        selectedMapItem.openInMaps()
                    }
                }
                
                Spacer()
                    .frame(width: FloatConstants.cornerRadius.rawValue)
                
                CustomButtonView(title: ButtonTitles.getDirections.rawValue, bgColor: .blue) {
                    print()
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 5)
        }
        .onAppear {
            fetchLookAroundPreview()
        }
        .onChange(of: selectedMapItem) { oldValue, newValue in
            fetchLookAroundPreview()
        }
        .padding()
    }
    
    private func fetchLookAroundPreview() {
        if let selectedMapItem {
            lookAroundScene = nil
            Task {
                let request = MKLookAroundSceneRequest(mapItem: selectedMapItem)
                lookAroundScene = try? await request.scene
            }
        }
    }
}

#Preview {
    LocationDetails(selectedMapItem: .constant(nil), isShow: .constant(false))
}
