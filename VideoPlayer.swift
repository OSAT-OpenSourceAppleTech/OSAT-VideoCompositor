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
    
    private lazy var playbutton: UIButton = {
        let btn = UIButton(frame: .zero)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(handlePlayButtonAction(_:)), for: .touchUpInside)
        return btn
    }()
    
    public convenience init() {
        self.init(frame: .zero)
    }
    
    public override init(frame: CGRect) {
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
        player = AVPlayer(url: url)
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
        layer.addSublayer(playerLayer!)
    }
    
    private func addSubviews() {
        addSubview(playbutton)
    }
    
    private func setButtonProperties() {
        playbutton.setImage(UIImage(systemName: "play", withConfiguration: UIImage.SymbolConfiguration(pointSize: CGFloat(40))), for: .selected)
        playbutton.setImage(UIImage(systemName: "pause", withConfiguration: UIImage.SymbolConfiguration(pointSize: CGFloat(40))), for: .normal)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            playbutton.centerXAnchor.constraint(equalTo: centerXAnchor),
            playbutton.centerYAnchor.constraint(equalTo: centerYAnchor),
            playbutton.heightAnchor.constraint(equalToConstant: 40),
            playbutton.widthAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    @objc private func handlePlayButtonAction(_ sender: Any) {
        playbutton.isSelected ? play() : pause()
        playbutton.isSelected.toggle()
    }
}

