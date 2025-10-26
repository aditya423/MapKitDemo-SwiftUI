//
//  CustomButtonView.swift
//  MapKitDemo-SwiftUI
//
//  Created by Aditya on 26/10/25.
//

import SwiftUI

struct CustomButtonView: View {
    let title: String
    let bgColor: Color
    var action: () -> ()
    
    var body: some View {
        Button {
            action()
        } label: {
            Text(title)
                .font(.headline)
                .foregroundStyle(.white)
                .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: 45)
        .background(bgColor)
        .clipShape(RoundedRectangle(cornerRadius: FloatConstants.cornerRadius.rawValue))
    }
}

#Preview {
    CustomButtonView(title: "", bgColor: .blue, action: {})
}
