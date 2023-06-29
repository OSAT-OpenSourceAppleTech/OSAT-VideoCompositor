//
//  VideoPlayer.swift
//  OSAT-VideoCompositor
//
//  Created by Rohit Sharma on 13/10/22.
//

import AVFoundation
import OSAT_VideoCompositor
import UIKit

public protocol AVPlayerProtocol: AnyObject {
    var delegate: AVPlayerCustomViewDelegate? { get set }
    func play()
    func pause()
    func set(url: URL)
    func seek(to time: CMTime)
    func registerTimeIntervalForObservingPlayer(_ timeInterval: CGFloat)
    func getDuration() async throws -> CMTime?
    func getVideoSize() -> CGSize
    func addWatermark(text: String, image: UIImage?, inputURL: URL, outputURL: URL?, position: OSATWaterMarkPosition, fontSize: Int?, fontColor: UIColor, handler: @escaping (_ exportSession: AVAssetExportSession?)-> Void)
}

public protocol AVPlayerCustomViewDelegate: AnyObject {
    func avPlayerCustomView(_ avPlayerView: AVPlayerCustomView, didReceivePlayBack time: CMTime)
    func avPlayerCustomView(_ avPlayerView: AVPlayerCustomView, didSeek isSuccess: Bool)
}

public typealias AVPlayerCustomView = UIView & AVPlayerProtocol

open class AVPlayerView: AVPlayerCustomView {
    private struct Constants {
        static let notificationRateDidChange = "AVPlayerRateDidChangeNotification"
    }
    private(set) var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private var url: URL?
    private var asset: AVAsset?
    private(set) var avPlayerItem: AVPlayerItem?
    private var timeInterval: CGFloat = 1.0
    private var observer: Any?
    private (set) var oldFrame: CGRect?
    
    // MARK: - Public apis for testing
    public var isVideoPlaying = false
    public weak var delegate: AVPlayerCustomViewDelegate?
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: Notification.Name(Constants.notificationRateDidChange), object: nil)
        if let observer = observer {
            player?.removeTimeObserver(observer)
        }
        
        observer = nil
    }
    
    public override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        setVideoPlayer()
        registerForNotification()
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
    
    open override func layoutIfNeeded() {
        super.layoutIfNeeded()
        
    }
    
    // MARK: - Public Apis
    open override func draw(_ rect: CGRect) {
        super.draw(rect)
        if oldFrame == nil {
            playerLayer?.frame = frame
            oldFrame = frame
        } else {
            playerLayer?.frame = CGRect(origin: frame.origin, size: CGSize(width: frame.width, height: oldFrame?.height ?? 100))
        }
        
    }
    
    open func play() {
        player?.play()
    }
    
    open func pause() {
        player?.pause()
    }
    
    open func set(url: URL) {
        self.url = url
        setVideoPlayer()
    }
    
    open func seek(to time: CMTime) {
        playerLayer?.player?.seek(to: time, completionHandler: { [weak self] isSuccess in
            guard let self = self else { return }
            self.delegate?.avPlayerCustomView(self, didSeek: isSuccess)
        })
    }
    
    open func registerTimeIntervalForObservingPlayer(_ timeInterval: CGFloat) {
        self.timeInterval = timeInterval
        addPeriodicObservers()
    }
    
    open func getVideoSize() -> CGSize {
        let track = asset?.tracks(withMediaType: .video).first
        return track?.naturalSize ?? .zero
    }
    
    public func getDuration() async throws -> CMTime? {
        do {
            let duration = try await asset?.load(.duration)
            return duration
        } catch  {
            NSLog("\(error)", "")
            return nil
        }
    }
    
    public func addWatermark(text: String, image: UIImage?, inputURL: URL, outputURL: URL?, position: OSATWaterMarkPosition, fontSize: Int?, fontColor: UIColor, handler: @escaping (AVAssetExportSession?) -> Void) {
        // TODO: Implement water-mark
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
            playerLayer = AVPlayerLayer(player: player)
            playerLayer?.videoGravity = .resizeAspect
            
            if let playerLayer = playerLayer {
                layer.addSublayer(playerLayer)
            }
        } else {
            player?.replaceCurrentItem(with: avPlayerItem)
            addPeriodicObservers()
        }
    }
    
    private func addPeriodicObservers() {
        if let observer = observer {
            player?.removeTimeObserver(observer)
        }
        observer = nil
        let interval = CMTime(seconds: timeInterval, preferredTimescale: CMTimeScale(NSEC_PER_SEC))

        // Keep the reference to remove
        observer = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self else { return }
            self.delegate?.avPlayerCustomView(self, didReceivePlayBack: time)
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
