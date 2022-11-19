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
    private struct Constants {
        static let notificationRateDidChange = "AVPlayerRateDidChangeNotification"
    }
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private var url: URL?
    private var asset: AVAsset?
    private var avPlayerItem: AVPlayerItem?
    
    // MARK: - Public apis for testing
    public var isVideoPlaying = false
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: Notification.Name(Constants.notificationRateDidChange), object: nil)
    }
    public override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        setVideoPlayer()
    }
    
    public init(frame: CGRect, url: URL?) {
        self.url = url
        super.init(frame: frame)
        
        setVideoPlayer()
        registerForNotification()
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
        if player == nil {
            player = AVPlayer(playerItem: avPlayerItem)
        } else {
            player?.replaceCurrentItem(with: avPlayerItem)
        }
        
        
        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.frame = frame
        
        if let playerLayer = playerLayer {
            layer.addSublayer(playerLayer)
        }
    }
    
    private func registerForNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.didReceiveNotification(notification:)), name: Notification.Name(Constants.notificationRateDidChange), object: nil)
    }
    
    @objc private func didReceiveNotification(notification: Notification) {
        guard notification.name.rawValue == Constants.notificationRateDidChange else { return }
        guard let rate = (notification.object as? AVPlayer)?.rate else { return }
        isVideoPlaying = rate == .zero ? false : true
    }
}
