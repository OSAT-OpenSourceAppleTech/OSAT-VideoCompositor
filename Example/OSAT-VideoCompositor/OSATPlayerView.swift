//
//  OSATPlayerView.swift
//  OSAT-VideoCompositor_Example
//
//  Created by Rohit Sharma on 14/02/23.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import SwiftUI

struct OSATPlayerView: View {
    @StateObject var playerInstance = PlayerViewModel()
    var body: some View {
        if #available(iOS 16.0, *) {
            PlayerView()
                .environmentObject(playerInstance)
        } else {
            Text("Upgrade iOS")
        }
    }
}

struct OSATPlayerView_Previews: PreviewProvider {
    static var previews: some View {
        OSATPlayerView()
    }
}
