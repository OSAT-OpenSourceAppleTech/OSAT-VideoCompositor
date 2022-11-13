//
//  VideoPlayer.swift
//  OSAT-VideoCompositor
//
//  Created by Rohit Sharma on 13/10/22.
//

import AVFoundation
import UIKit

open class VideoPlayer: UIView {
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private var url: URL?
    
    private struct Constants {
        static let playButton = "play"
        static let pauseButton = "pause"
        static let iconSize: CGFloat = 40
    }
    
    private lazy var playbutton: UIButton = {
        let btn = UIButton(frame: .zero)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(handlePlayButtonAction(_:)), for: .touchUpInside)
        btn.accessibilityIdentifier = "playButton"
        return btn
    }()
    
    public override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        setVideoPlayer()
    }
    
    public init(frame: CGRect, url: URL?) {
        self.url = url
        super.init(frame: frame)
        
        setVideoPlayer()
        addSubviews()
        setButtonProperties()
        setupConstraints()
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
        playbutton.isSelected = false
    }
    
    open func pause() {
        player?.pause()
        playbutton.isSelected = true
    }
    
    open func transitionView(to size: CGSize) {
        frame.size = size
        playerLayer?.frame.size = size
    }
    
    open func set(url: URL) {
        self.url = url
        player = AVPlayer(url: url)
    }
    
    // For test
    open func getPlayer() -> AVPlayer? {
        return player
    }
    
    open func getPlayButton() -> UIButton {
        return playbutton
    }
    
    // MARK: - Private Methods
    private func setVideoPlayer() {
        if let url = url {
            player = AVPlayer(url: url)
        } else {
            player = AVPlayer()
        }
        
        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.frame = frame
        if let playerLayer = playerLayer {
            layer.addSublayer(playerLayer)
        }
    }
    
    private func addSubviews() {
        addSubview(playbutton)
    }
    
    private func setButtonProperties() {
        playbutton.setImage(UIImage(systemName: Constants.playButton, withConfiguration: UIImage.SymbolConfiguration(pointSize: Constants.iconSize)), for: .selected)
        playbutton.setImage(UIImage(systemName: Constants.pauseButton, withConfiguration: UIImage.SymbolConfiguration(pointSize: Constants.iconSize)), for: .normal)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            playbutton.centerXAnchor.constraint(equalTo: centerXAnchor),
            playbutton.centerYAnchor.constraint(equalTo: centerYAnchor),
            playbutton.heightAnchor.constraint(equalToConstant: Constants.iconSize),
            playbutton.widthAnchor.constraint(equalToConstant: Constants.iconSize)
        ])
    }
    
    @objc private func handlePlayButtonAction(_ sender: Any) {
        playbutton.isSelected ? play() : pause()
    }
}

