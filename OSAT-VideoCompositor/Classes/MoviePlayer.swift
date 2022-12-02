//
//  MoviePlayer.swift
//  OSAT-VideoCompositor
//
//  Created by Rohit Sharma on 15/11/22.
//

import AVFoundation
import Foundation

public protocol MoviePlayerDelegate: AnyObject {
    func moviePlayer(_ moviePlayer: MoviePlayer, didReceivePlayBack time: CMTime)
}

open class MoviePlayer: NSObject {
    private let customPlayerView: AVPlayerCustomView
    public weak var delegate: MoviePlayerDelegate?
    
    public init(customPlayerView: AVPlayerCustomView) {
        self.customPlayerView = customPlayerView
        super.init()
        
        customPlayerView.delegate = self
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
    
    public func seek(to time: CMTime) {
        customPlayerView.seek(to: time)
    }
    
    public func registerTimeIntervalForObservingPlayer(_ timeInterval: CGFloat) {
        customPlayerView.registerTimeIntervalForObservingPlayer(timeInterval)
    }
    
    public func getDuration() async throws -> CMTime? {
        return try await customPlayerView.getDuration()
    }
}

extension MoviePlayer: AVPlayerCustomViewDelegate {
    public func avPlayerCustomView(_ avPlayerView: AVPlayerCustomView, didSeek isSuccess: Bool) {}
    
    public func avPlayerCustomView(_ avPlayerView: AVPlayerCustomView, didReceivePlayBack time: CMTime) {
        delegate?.moviePlayer(self, didReceivePlayBack: time)
    }
}
