//
//  FeatureView.swift
//  OSAT_SwiftUI
//
//  Created by Rohit Sharma on 13/02/23.
//

import SwiftUI

struct FeatureView: View {
    @State private var value = 0.2
    private var radius: CGFloat = 50
    var body: some View {
        ZStack {
            Color(hex: "#2C2B2C")
                .ignoresSafeArea()
            
            
            VStack (alignment: .leading, spacing: 12) {
                ToolBarUIView()
                HStack (spacing: 28) {
                    Button {
                        print("yo")
                    } label: {
                        Image(systemName: "play.fill")
                            .padding()
                            .background(Color(hex: "#7B61FF"))
                            .cornerRadius(16)
                            .frame(width: 50, height: 50)
                            .foregroundColor(.white)
                            .font(.system(size: 25))
                        
                    }
                    
                    Slider(value: $value) {
                        Text("value: \(value)")
                    }
                    .tint(.white)
                    .frame(width: 250)
                    Spacer()
                }.padding(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 0))
                Spacer()
            }.padding()
        }
        .padding(.bottom, radius)
        .cornerRadius(radius)
        .padding(.bottom, -radius)
    }
}

struct FeatureView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Spacer()
            FeatureView().frame(height: 176)
        }
        
    }
}
