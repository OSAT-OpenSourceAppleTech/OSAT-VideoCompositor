//
//  FeatureView.swift
//  OSAT_SwiftUI
//
//  Created by Rohit Sharma on 13/02/23.
//

import SwiftUI
import AVFoundation

struct FeatureView: View {
    @EnvironmentObject var playerInstance: PlayerViewModel
    @State private var value = 0.2
    private var radius: CGFloat = 50
    var body: some View {
        ZStack {
            Color(hex: "#2C2B2C")
                .ignoresSafeArea()
            
            
            VStack (alignment: .leading, spacing: 12) {
                if #available(iOS 16.0, *) {
                    ToolBarUIView()
                        .environmentObject(playerInstance)
                } else {
                    // Fallback on earlier versions
                }
                HStack (spacing: 28) {
                    Button {
                        playerInstance.shouldPlayVideo(!playerInstance.isPlaying)
                    } label: {
                        Image(systemName: playerInstance.isPlaying ? "pause.fill" : "play.fill")
                            .padding()
                            .background(Color(hex: "#7B61FF"))
                            .cornerRadius(16)
                            .frame(width: 50, height: 50)
                            .foregroundColor(.white)
                            .font(.system(size: 25))
                        
                    }
                    
                    Slider(value: Binding(get: { return playerInstance.seekBarValue }, set: { newValue in
                        playerInstance.seekBarValue = newValue
                        let seekTime =  CMTimeMultiplyByFloat64(playerInstance.playerView.playerView.player?.currentItem?.duration ?? CMTime(value: 0, timescale: 1), Float64(playerInstance.seekBarValue))
                        playerInstance.playerView.playerView.player?.seek(to: seekTime, toleranceBefore: CMTime(value: 1, timescale: 1), toleranceAfter: CMTime(value: 1, timescale: 1))
                    }))
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
    @StateObject static var playerInstance = PlayerViewModel()
    static var previews: some View {
        VStack {
            Spacer()
            FeatureView()
                .frame(height: 176)
                .environmentObject(playerInstance)
            
        }
        
    }
}
