//
//  ViewController.swift
//  OSAT-VideoCompositor
//
//  Created by hdutt on 09/02/2022.
//  Copyright (c) 2022 hdutt. All rights reserved.
//

import OSAT_VideoCompositor
import AVFoundation
import UIKit

class ViewController: UIViewController {
    private var videoPlayer: MoviePlayer!
    private var videoPlayerLayer: AVPlayerView!
    private var duration: CMTime?
    private var videoSourceUrl: URL? {
        didSet {
            updateVideoPlayerUrl()
        }
    }
    
    private struct Constants {
        static let playButton = "play"
        static let pauseButton = "pause"
        static let iconSize: CGFloat = 40
    }
    
    private lazy var playerView: UIView = {
        let view = UIView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var sliderParentView: UIView = {
        let view = UIView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var playbutton: UIButton = {
        let btn = UIButton(frame: .zero)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(handlePlayButtonAction(_:)), for: .touchUpInside)
        btn.accessibilityIdentifier = "playButton"
        return btn
    }()
    
    private lazy var slider: UISlider = {
        let slider = UISlider(frame: .zero)
        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.addTarget(self, action: #selector(handleSliderAction(_:)), for: .touchUpInside)
        return slider
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let url = Bundle.main.url(forResource: "Demo", withExtension: "mp4")!
        videoPlayerLayer = AVPlayerView(frame: .zero)
        
        videoPlayer = MoviePlayer(customPlayerView: videoPlayerLayer)
        videoPlayer?.set(url: url)
        videoPlayer?.delegate = self
        videoPlayer?.registerTimeIntervalForObservingPlayer(1)
        videoPlayerLayer.translatesAutoresizingMaskIntoConstraints = false
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(showImagePicker(_:)))
        videoPlayer?.play()
        addSubviews()
        setButtonProperties()
        setupConstraints()
        Task {
            await getDuration()
        }
    }
    
    @objc func showImagePicker(_ sender: UIBarButtonItem) {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let pickerController = UIImagePickerController()
            pickerController.delegate = self
            pickerController.allowsEditing = true
            pickerController.mediaTypes = ["public.image", "public.movie"]
            pickerController.sourceType = .savedPhotosAlbum
            present(pickerController, animated: true)
        }
    }
    
    private func setupSliderProperties() {
        slider.minimumValue = 0
        slider.maximumValue = Float(duration?.seconds ?? 100)
    }
    
    private func getDuration() async {
        do {
            self.duration = try await videoPlayer?.getDuration()
            setupSliderProperties()
            NSLog("\(String(describing: duration))", "")
            
        } catch {
            NSLog("\(error)", "")
        }
    }
    
    private func addSubviews() {
        view.addSubview(playerView)
        view.addSubview(sliderParentView)
        view.addSubview(playbutton)
        
        sliderParentView.isUserInteractionEnabled = true
        sliderParentView.addSubview(slider)
        playerView.addSubview(videoPlayerLayer)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            playerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            playerView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            playerView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            
            videoPlayerLayer.centerXAnchor.constraint(equalTo: playerView.centerXAnchor),
            videoPlayerLayer.centerXAnchor.constraint(equalTo: playerView.centerXAnchor),
            videoPlayerLayer.leadingAnchor.constraint(equalTo: playerView.leadingAnchor),
            videoPlayerLayer.trailingAnchor.constraint(equalTo: playerView.trailingAnchor),
            videoPlayerLayer.heightAnchor.constraint(equalTo: videoPlayerLayer.widthAnchor, multiplier: 1),
            
            
            sliderParentView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -60),
            sliderParentView.leadingAnchor.constraint(equalTo: videoPlayerLayer.leadingAnchor),
            sliderParentView.trailingAnchor.constraint(equalTo: videoPlayerLayer.trailingAnchor),
            
            slider.leadingAnchor.constraint(equalTo: sliderParentView.leadingAnchor),
            slider.trailingAnchor.constraint(equalTo: sliderParentView.trailingAnchor),
            slider.heightAnchor.constraint(equalTo: sliderParentView.heightAnchor),
            
            playbutton.centerXAnchor.constraint(equalTo: videoPlayerLayer.centerXAnchor),
            playbutton.centerYAnchor.constraint(equalTo: videoPlayerLayer.centerYAnchor),
            playbutton.heightAnchor.constraint(equalToConstant: Constants.iconSize),
            playbutton.widthAnchor.constraint(equalToConstant: Constants.iconSize)
        ])
    }
    
    private func setButtonProperties() {
        playbutton.setImage(UIImage(systemName: Constants.playButton, withConfiguration: UIImage.SymbolConfiguration(pointSize: Constants.iconSize)), for: .selected)
        playbutton.setImage(UIImage(systemName: Constants.pauseButton, withConfiguration: UIImage.SymbolConfiguration(pointSize: Constants.iconSize)), for: .normal)
    }
    
    @objc private func handlePlayButtonAction(_ sender: Any) {
        playbutton.isSelected ? play() : pause()
    }
    
    @objc private func handleSliderAction(_ sender: UISlider) {
        videoPlayerLayer?.seek(to: CMTime(seconds: Double(sender.value), preferredTimescale: 1000))
    }
    
    private func play() {
        videoPlayer?.play()
        playbutton.isSelected = false
    }
    
    private func pause() {
        videoPlayer?.pause()
        playbutton.isSelected = true
    }
    
    private func updateVideoPlayerUrl() {
        guard let videoSourceUrl = videoSourceUrl else { return }
        videoPlayer.set(url: videoSourceUrl)
    }
}

extension ViewController: MoviePlayerDelegate {
    func moviePlayer(_ moviePlayer: OSAT_VideoCompositor.MoviePlayer, didReceivePlayBack time: CMTime) {
        slider.value = Float(time.seconds)
    }
}

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        guard let imageUrl = info["UIImagePickerControllerMediaURL"] else { picker.dismiss(animated: true)
            return }
        videoSourceUrl = (imageUrl as? URL)
        picker.dismiss(animated: true)
    }
}
