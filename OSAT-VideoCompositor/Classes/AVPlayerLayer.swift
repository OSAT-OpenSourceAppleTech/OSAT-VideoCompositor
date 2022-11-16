//
//  VideoPlayer.swift
//  OSAT-VideoCompositor
//
//  Created by Rohit Sharma on 13/10/22.
//

import AVFoundation
import UIKit

public protocol AVPlayerProtocol: AnyObject {
    func play()
    func pause()
    func set(url: URL)
}

public typealias AVPlayerCustomView = UIView & AVPlayerProtocol

open class AVPlayerView: AVPlayerCustomView {
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private var url: URL?
    private var asset: AVAsset?
    private var avPlayerItem: AVPlayerItem?
    
    public override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        setVideoPlayer()
    }
    
    public init(frame: CGRect, url: URL?) {
        self.url = url
        super.init(frame: frame)
        
        setVideoPlayer()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    // MARK: - Public Apis
    open override func draw(_ rect: CGRect) {
        super.draw(rect)
        playerLayer?.frame = bounds
    }
    
    open func play() {
        player?.play()
    }
    
    open func pause() {
        player?.pause()
    }
    
    open func transitionView(to size: CGSize) {
        frame.size = size
        playerLayer?.frame.size = size
    }
    
    open func set(url: URL) {
        self.url = url
        setVideoPlayer()
    }
    
    // For test
    open func getPlayer() -> AVPlayer? {
        return player
    }
    // MARK: - Private Methods
    private func setVideoPlayer() {
        guard let url = url else { return }
        asset = AVAsset(url: url)
        
        guard let asset = asset else { return }

        avPlayerItem = AVPlayerItem(asset: asset)
        player = AVPlayer(playerItem: avPlayerItem)
        
        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.frame = frame
        
        if let playerLayer = playerLayer {
            layer.addSublayer(playerLayer)
        }
    }
}
