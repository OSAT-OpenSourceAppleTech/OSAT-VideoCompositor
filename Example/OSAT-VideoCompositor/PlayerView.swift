//
//  PlayerView.swift
//  OSAT_SwiftUI
//
//  Created by Rohit Sharma on 09/02/23.
//

import SwiftUI
import PhotosUI

@available(iOS 16.0, *)
struct PlayerView: View {
    @State private var value = 0.2
    @State private var sort: Int = 0
    @State var selectedItems: [PhotosPickerItem] = []
    @State var showView = false
    
    init() {
        //Use this if NavigationBarTitle is with displayMode = .inline
        UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: UIColor.white]
    }
    
    var body: some View {
        NavigationStack {
            ZStack (alignment: .center) {
                // For background color
                Color.black.ignoresSafeArea()
                
                // Player
                VStack (spacing: 70) {
                    Spacer()
                    
                    ZStack (alignment: .center) {
                        Image("banner-1544x500")
                            .renderingMode(.original)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 390, height: 200)
                            .clipped()
                        
                        // Play button
                        Button {
                            showView.toggle()
                        } label: {
                            Image(systemName: "play.rectangle").font(.system(size: 60)).foregroundColor(.white)
                        }.sheet(isPresented: $showView) {
                            
                        }
                    }
                    Spacer()
                    FeatureView()
                        .frame(height: 176)
                }
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarTitle("Video Player")
                .navigationBarBackButtonHidden(true)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            print("add video")
                        } label: {
                            Text("Add Video")
                        }
                    }
                }.foregroundColor(.blue)
            }
        }
    }
}
/*
 ToolbarItem(placement: .navigationBarLeading) {
 Menu {
 Section {
 Button {
 
 } label: {
 Label("Save Video", systemImage: "icloud.and.arrow.down")
 }
 Button {
 print("change resolution")
 } label: {
 Label("Resolution", systemImage: "icloud.and.arrow.down")
 }
 Button {
 print("change framerate")
 } label: {
 Label("Frame Rate", systemImage: "icloud.and.arrow.down")
 }
 }
 Section {
 Button {
 print("change format")
 } label: {
 Label("Format", systemImage: "icloud.and.arrow.down")
 }
 }
 } label: {
 Image(systemName: "square.and.arrow.up")
 }
 
 }
 */

struct SheetView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        Button("Press to dismiss") {
            dismiss()
        }
        .font(.title)
        .padding()
        .background(.black)
    }
}

@available(iOS 16.0, *)
struct PickerView: View {
    @State var selectedItems: [PhotosPickerItem] = []
    @Environment(\.presentationMode) var presentationMode
    var body: some View {
        if #available(iOS 16.0, *) {
            PhotosPicker(selection: $selectedItems) {
                Text("hey")
            }
        } else {
            // Fallback on earlier versions
        }
    }
}

struct PlayerView_Previews: PreviewProvider {
    static var previews: some View {
        if #available(iOS 16.0, *) {
            PlayerView()
        } else {
            // Fallback on earlier versions
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
