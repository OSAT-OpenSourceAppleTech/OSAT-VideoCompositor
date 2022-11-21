//
//  ViewController.swift
//  OSAT-VideoCompositor
//
//  Created by hdutt on 09/02/2022.
//  Copyright (c) 2022 hdutt. All rights reserved.
//

import OSAT_VideoCompositor
import UIKit

class ViewController: UIViewController {
    private var videoPlayer: MoviePlayer?
    private var videoPlayerLayer: AVPlayerView?
    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let url = Bundle.main.url(forResource: "Demo", withExtension: "mp4")!
        let videoPlayerLayer = AVPlayerView(frame: .zero)
        self.videoPlayerLayer = videoPlayerLayer
        videoPlayer = MoviePlayer(customPlayerView: videoPlayerLayer)
        videoPlayer?.set(url: url)
        videoPlayerLayer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(videoPlayerLayer)
        
        NSLayoutConstraint.activate([
            videoPlayerLayer.heightAnchor.constraint(equalTo: view.heightAnchor),
            videoPlayerLayer.widthAnchor.constraint(equalTo: view.widthAnchor)
        ])
        
        videoPlayer?.play()
        addSubviews()
        setButtonProperties()
        setupConstraints()
    }
    
    private func addSubviews() {
        view.addSubview(playbutton)
    }
    
    private func setButtonProperties() {
        playbutton.setImage(UIImage(systemName: Constants.playButton, withConfiguration: UIImage.SymbolConfiguration(pointSize: Constants.iconSize)), for: .selected)
        playbutton.setImage(UIImage(systemName: Constants.pauseButton, withConfiguration: UIImage.SymbolConfiguration(pointSize: Constants.iconSize)), for: .normal)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            playbutton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            playbutton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            playbutton.heightAnchor.constraint(equalToConstant: Constants.iconSize),
            playbutton.widthAnchor.constraint(equalToConstant: Constants.iconSize)
        ])
    }
    
    @objc private func handlePlayButtonAction(_ sender: Any) {
        playbutton.isSelected ? play() : pause()
    }
    
    private func play() {
        videoPlayer?.play()
        playbutton.isSelected = false
    }
    
    private func pause() {
        videoPlayer?.pause()
        playbutton.isSelected = true
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { (context) in
        }) { [weak self] (context) in
            guard let self = self else { return }
            self.videoPlayerLayer?.transitionView(to: size)
        }
    }
}

