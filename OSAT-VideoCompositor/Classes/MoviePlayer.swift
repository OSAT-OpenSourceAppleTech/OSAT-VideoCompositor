//
//  MoviePlayer.swift
//  OSAT-VideoCompositor
//
//  Created by Rohit Sharma on 15/11/22.
//

import Foundation

open class MoviePlayer: NSObject {
    private let customPlayerView: AVPlayerCustomView
    
    public init(customPlayerView: AVPlayerCustomView) {
        self.customPlayerView = customPlayerView
        super.init()
    }
    
    public func set(url: URL) {
        customPlayerView.set(url: url)
    }
    
    public func play() {
        customPlayerView.play()
    }
    
    public func pause() {
        customPlayerView.pause()
    }
}
