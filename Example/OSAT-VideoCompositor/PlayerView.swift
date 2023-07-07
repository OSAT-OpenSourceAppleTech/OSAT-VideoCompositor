//
//  PlayerView.swift
//  OSAT_SwiftUI
//
//  Created by Rohit Sharma on 09/02/23.
//

import SwiftUI
import PhotosUI

@available(iOS 16.0, *)
struct PlayerView: View, KeyboardReadable {
    @EnvironmentObject var playerInstance: PlayerViewModel
    @State private var value = 0.2
    @State private var sort: Int = 0
    @State var selectedItems: [PhotosPickerItem] = []
    @State var showView = false
    @State var isKeyboardVisible = false
    @State private var isDragging = false
    @State private var location: CGPoint = CGPoint(x: 50, y: 50)
    @State var lastScaleValue: CGFloat = 1.0
    @State var newScaleValue: CGFloat = 1.0
    @State private var locationTwo: CGPoint = CGPoint(x: 50, y: 50)
    @State private var showingExporter = false
    
    init() {
        //Use this if NavigationBarTitle is with displayMode = .inline
        UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: UIColor.white]
    }
    
    var drag: some Gesture {
        DragGesture(coordinateSpace: .local)
            .onChanged { value in
                self.location = value.location
            }
            .onEnded { value in
                print("start loc: \(value.startLocation)")
                self.location = value.location
                playerInstance.textCGPoint = location
            }
    }
    
    var drag2: some Gesture {
        DragGesture()
            .onChanged { value in
                self.locationTwo = value.location
            }
            .onEnded { value in
                
                self.locationTwo = value.location
                playerInstance.imageCGPoint = locationTwo
            }
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
                        playerInstance
                            .playerView
                        ZStack {
                            if let img = playerInstance.currentImage {
                                Image(uiImage: img)
                                    .resizable()
                                    .position(locationTwo)
                                    .gesture(drag2)
                                    .frame(width: 50, height: 50)
                                    .scaledToFit()
                            }
                        }
                        ZStack {
                            Text(playerInstance.currentText)
                                .foregroundColor(.black)
                                .opacity(playerInstance.currentText.isEmpty ? 0 : 1)
                                .opacity(isKeyboardVisible ? 0 : 1)
                                .position(location)
                                .gesture(drag)
                                .frame(width: 100, height: 100)
                            
                        }
                    }.frame(width: 390)
                    Spacer()
                    FeatureView()
                        
                        .environmentObject(playerInstance)
                        .frame(height: 176)
                        .onReceive(keyboardPublisher) { newIsKeyboardVisible in
                            isKeyboardVisible = newIsKeyboardVisible
                        }.opacity(isKeyboardVisible ? 0 : 1)
                }
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarTitle("Video Player")
                .navigationBarBackButtonHidden(true)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showingExporter.toggle()
                        } label: {
                            Text("Export Video")
                        }.sheet(isPresented: $showingExporter) {
                            DocumentPicker()
                        }
                    }
                }.foregroundColor(.blue)
            }
        }
    }
}

struct AVPlayerViewWrapper: UIViewRepresentable {
    let playerView: AVPlayerView
    func updateUIView(_ uiView: UIView, context: UIViewRepresentableContext<AVPlayerViewWrapper>) {
    }
    
    func makeUIView(context: Context) -> UIView {
        return playerView
    }
}

struct PlayerView_Previews: PreviewProvider {
    @StateObject static var playerInstance = PlayerViewModel()
    static var previews: some View {
        if #available(iOS 16.0, *) {
            PlayerView()
                .environmentObject(playerInstance)
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
