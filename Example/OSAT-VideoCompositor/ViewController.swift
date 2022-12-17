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
    
    private var waterMarkPosition: WaterMarkPosition = .LeftBottomCorner
    private var exportUrl: URL?
    private var tmpUrl: URL?
    private var selectedImageSrc: UIImage?
    private var originalVideoUrl: URL?
    private var tmpVideoSrcUrl: URL? {
        didSet {
            updateVideoPlayerUrl()
        }
    }
    
    // Text WaterMark properties
    private var text: String = ""
    private var fontSize: Int = 20
    private var fontColor: UIColor = .black
    
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
        view.isUserInteractionEnabled = true
        return view
    }()
    
    private lazy var playbutton: UIButton = {
        let btn = UIButton(frame: .zero)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(handlePlayButtonAction(_:)), for: .touchUpInside)
        btn.accessibilityIdentifier = "playButton"
        return btn
    }()
    
    private lazy var exportButton: UIButton = {
        let btn = UIButton(frame: .zero)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(handleExportButtonAction(_:)), for: .touchUpInside)
        btn.accessibilityIdentifier = "exportButton"
        return btn
    }()
    
    private lazy var composebutton: UIButton = {
        let btn = UIButton(frame: .zero)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(showAddWatermark(_:)), for: .touchUpInside)
        btn.accessibilityIdentifier = "composebutton"
        return btn
    }()
    
    private lazy var composeForOnlyImageButton: UIButton = {
        let btn = UIButton(frame: .zero)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(handleComposeButtonButtonAction(_:)), for: .touchUpInside)
        btn.accessibilityIdentifier = "composeForOnlyImageButton"
        return btn
    }()
    
    private lazy var spinner: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(activityIndicatorStyle: .large)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        return view
    }()
    
    private lazy var slider: UISlider = {
        let slider = UISlider(frame: .zero)
        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.addTarget(self, action: #selector(handleSliderAction(_:)), for: .touchUpInside)
        return slider
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let url = Bundle.main.url(forResource: "videoplayback", withExtension: "mp4")!
        videoPlayerLayer = AVPlayerView(frame: .zero)
        originalVideoUrl = url
        view.backgroundColor = .black
        
        videoPlayer = MoviePlayer(customPlayerView: videoPlayerLayer)
        videoPlayer?.set(url: url)
        videoPlayer?.delegate = self
        videoPlayer?.registerTimeIntervalForObservingPlayer(1)
        videoPlayerLayer.translatesAutoresizingMaskIntoConstraints = false
        
        navigationItem.title = "OSAT Video Compositer"
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: nil)
        navigationItem.rightBarButtonItem?.menu = createVideoImageMenu()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: nil)
        navigationItem.leftBarButtonItem?.menu = createMenu()
        
        videoPlayerLayer.backgroundColor = .systemGray
        videoPlayer?.play()
        addSubviews()
        setButtonProperties()
        setupConstraints()
        Task {
            await getDuration()
        }
    }
    
    private func updateMenu() {
        navigationItem.leftBarButtonItem?.menu = createMenu()
    }
    
    private func createMenu() -> UIMenu? {
        let leftBottomCornerPosition = UIAction(title: "Left Corner bottom Position", image: UIImage(systemName: "pencil.circle"), identifier: UIAction.Identifier("leftBtm"), attributes: [], state: waterMarkPosition == .LeftBottomCorner ? .on : .off) { action in
            self.waterMarkPosition = .LeftBottomCorner
            self.updateMenu()
        }
        
        let rightBottomCornerPosition = UIAction(title: "Right Corner bottom Position", image: UIImage(systemName: "pencil.circle"), attributes: [], state: waterMarkPosition == .RightBottomCorner ? .on : .off) { action in
            self.waterMarkPosition = .RightBottomCorner
            self.updateMenu()
        }
        
        let leftTopCornerPosition = UIAction(title: "Left Corner Top Position", image: UIImage(systemName: "pencil.circle"), attributes: [], state: waterMarkPosition == .LeftTopCorner ? .on : .off) { action in
            self.waterMarkPosition = .LeftTopCorner
            self.updateMenu()
        }
        
        let rightTopCornerPosition = UIAction(title: "Right Corner Top Position", image: UIImage(systemName: "pencil.circle"), attributes: [], state: waterMarkPosition == .RightTopCorner ? .on : .off) { action in
            self.waterMarkPosition = .RightTopCorner
            self.updateMenu()
        }

        let elements: [UIAction] = [leftBottomCornerPosition, rightBottomCornerPosition, leftTopCornerPosition, rightTopCornerPosition]
        let menu = UIMenu(title: "Water Mark Position", children: elements)
        return menu
    }
    
    private func showImagePicker() {
        videoPlayer.pause()
        let pickerController = UIImagePickerController()
        pickerController.delegate = self
        pickerController.mediaTypes = ["public.movie"]
        pickerController.sourceType = .savedPhotosAlbum
        DispatchQueue.main.async {
            self.present(pickerController, animated: true)
        }
       
    }
    
    private func createVideoImageMenu() -> UIMenu? {
        // Deferred menu
        let selectVideo = UIAction(title: "Select a Video", image: UIImage(systemName: "video"), identifier: UIAction.Identifier("leftBtm"), attributes: [], state: .off) { action in
            self.showImagePicker()
        }
        
        let selectImage = UIAction(title: "Select an Image", image: UIImage(systemName: "photo"), attributes: [], state: .off) { action in
            self.showImagePickerForWaterMark()
        }
        
        let pickFontColor = UIAction(title: "Select Font Color", image: UIImage(systemName: "pencil.tip"), identifier: UIAction.Identifier("pick font color"), attributes: [], state: .off) { action in
            self.showColorPicker()
        }
        
        let deferredMenu = UIDeferredMenuElement { (menuElements) in
            let menu = UIMenu(title: "Image/Font Color", options: .displayInline,  children: [selectImage, pickFontColor])
            menuElements([menu])
        }
        
        let elements: [UIAction] = [selectVideo]
        var menu = UIMenu(title: "Select Video", children: elements)
        menu = menu.replacingChildren([selectVideo, deferredMenu])
        return menu
    }
    
    private func showImagePickerForWaterMark() {
        videoPlayer.pause()
        let pickerController = UIImagePickerController()
        pickerController.delegate = self
        pickerController.sourceType = .savedPhotosAlbum
        DispatchQueue.main.async {
            self.present(pickerController, animated: true)
        }
       
    }
    
    private func showColorPicker() {
        let pickerController = UIColorPickerViewController()
        pickerController.delegate = self
        DispatchQueue.main.async {
            self.present(pickerController, animated: true)
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
        
        sliderParentView.isUserInteractionEnabled = true
        sliderParentView.addSubview(slider)
        sliderParentView.addSubview(playbutton)
        sliderParentView.addSubview(composebutton)
        sliderParentView.addSubview(exportButton)
        sliderParentView.addSubview(composeForOnlyImageButton)
        
        playerView.addSubview(videoPlayerLayer)
        playerView.addSubview(spinner)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            playerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            playerView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            playerView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            playerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -300),
            
            videoPlayerLayer.centerXAnchor.constraint(equalTo: playerView.centerXAnchor),
            videoPlayerLayer.centerXAnchor.constraint(equalTo: playerView.centerXAnchor),
            videoPlayerLayer.leadingAnchor.constraint(equalTo: playerView.leadingAnchor),
            videoPlayerLayer.trailingAnchor.constraint(equalTo: playerView.trailingAnchor),
            videoPlayerLayer.heightAnchor.constraint(equalTo: videoPlayerLayer.widthAnchor, multiplier: 1),
            
            spinner.centerYAnchor.constraint(equalTo: playerView.centerYAnchor),
            spinner.centerXAnchor.constraint(equalTo: playerView.centerXAnchor),
            
            sliderParentView.topAnchor.constraint(equalTo: playerView.bottomAnchor, constant: 10),
            sliderParentView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -60),
            sliderParentView.leadingAnchor.constraint(equalTo: videoPlayerLayer.leadingAnchor),
            sliderParentView.trailingAnchor.constraint(equalTo: videoPlayerLayer.trailingAnchor),
            
            slider.leadingAnchor.constraint(equalTo: sliderParentView.leadingAnchor, constant: 10),
            slider.trailingAnchor.constraint(equalTo: sliderParentView.trailingAnchor, constant: -10),
            slider.heightAnchor.constraint(equalTo: sliderParentView.heightAnchor),
            
            playbutton.topAnchor.constraint(equalTo: sliderParentView.topAnchor, constant: 20),
            playbutton.heightAnchor.constraint(equalToConstant: Constants.iconSize),
            playbutton.widthAnchor.constraint(equalToConstant: Constants.iconSize),
            
            exportButton.centerXAnchor.constraint(equalTo: sliderParentView.centerXAnchor),
            exportButton.topAnchor.constraint(equalTo: sliderParentView.topAnchor, constant: 20),
            exportButton.widthAnchor.constraint(equalToConstant: Constants.iconSize),
            exportButton.heightAnchor.constraint(equalToConstant: Constants.iconSize),
            
            composebutton.heightAnchor.constraint(equalToConstant: Constants.iconSize),
            composebutton.widthAnchor.constraint(equalToConstant: Constants.iconSize),
            composebutton.trailingAnchor.constraint(equalTo: sliderParentView.trailingAnchor, constant: -10),
            composebutton.centerYAnchor.constraint(equalTo: playbutton.centerYAnchor),
            
            composeForOnlyImageButton.heightAnchor.constraint(equalToConstant: Constants.iconSize),
            composeForOnlyImageButton.widthAnchor.constraint(equalToConstant: Constants.iconSize),
            composeForOnlyImageButton.topAnchor.constraint(equalTo: sliderParentView.topAnchor, constant: 160)
        ])
    }
    
    private func setButtonProperties() {
        playbutton.setImage(UIImage(systemName: Constants.playButton, withConfiguration: UIImage.SymbolConfiguration(pointSize: Constants.iconSize)), for: .selected)
        playbutton.setImage(UIImage(systemName: Constants.pauseButton, withConfiguration: UIImage.SymbolConfiguration(pointSize: Constants.iconSize)), for: .normal)
        
        composebutton.setImage(UIImage(systemName: "square.and.pencil.circle.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: Constants.iconSize)), for: .selected)
        composebutton.setImage(UIImage(systemName: "square.and.pencil.circle", withConfiguration: UIImage.SymbolConfiguration(pointSize: Constants.iconSize)), for: .normal)
        
        exportButton.setImage(UIImage(systemName: "arrow.down.app", withConfiguration: UIImage.SymbolConfiguration(pointSize: Constants.iconSize)), for: .normal)
        
        composeForOnlyImageButton.setImage(UIImage(systemName: "photo.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: Constants.iconSize)), for: .normal)
    }
    
    @objc private func handlePlayButtonAction(_ sender: Any) {
        playbutton.isSelected ? play() : pause()
    }
    
    @objc private func handleComposeButtonButtonAction(_ sender: Any) {
        text = ""
        addWaterMark()
    }
    
    @objc private func handleExportButtonAction(_ sender: Any) {
        // Create a document picker for directories.
        let documentPicker =
            UIDocumentPickerViewController(forOpeningContentTypes: [.folder])
        documentPicker.delegate = self

        // Set the initial directory.
        documentPicker.directoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]

        // Present the document picker.
        present(documentPicker, animated: true, completion: nil)
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
        guard let videoSourceUrl = tmpVideoSrcUrl else { return }
        videoPlayer.set(url: videoSourceUrl)
        play()
        Task {
            await getDuration()
        }
    }
    
    @objc private func showAddWatermark(_ sender: UIButton) {
        showAlertWithTextField()
    }
    
    private func addWaterMark() {
        guard let inputURL = originalVideoUrl else { return }
        
        videoPlayerLayer.isHidden = true
        videoPlayer.pause()
        spinner.isHidden = false
        spinner.startAnimating()
        
        videoPlayer.addWatermark(text: text, image: selectedImageSrc, inputURL: inputURL, outputURL: nil, position: waterMarkPosition, fontSize: fontSize, fontColor: fontColor, handler: { [weak self] (exportSession) in
            guard let session = exportSession, let self = self else { return }
            
            switch session.status {
            case .completed:
                guard NSData(contentsOf: session.outputURL!) != nil else { return }
                self.tmpUrl = session.outputURL
                self.videoPlayer.set(url: session.outputURL!)
                self.play()
                self.videoPlayerLayer.isHidden = false
                self.spinner.isHidden = true
                self.spinner.stopAnimating()
                self.selectedImageSrc = nil
                self.fontSize = 20
                self.fontColor = .black
                Task {
                    await self.getDuration()
                }
            
            case .failed:
                NSLog("error: \(String(describing: session.error))", "")
            
            default: break
            }
        })
    }
    
    private func showAlertWithTextField() {
        let alertController = UIAlertController(title: "Add WaterMark Text", message: nil, preferredStyle: .alert)
        let confirmAction = UIAlertAction(title: "Add", style: .default) { (_) in
            if let txtField = alertController.textFields?.first, let text = txtField.text {
                self.text = text
            }
            
            if let txtField = alertController.textFields?[1], let text = txtField.text {
                self.fontSize = Int(text) ?? 20
            }
            self.addWaterMark()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in }
        alertController.addTextField { (textField) in
            textField.placeholder = "Add watermark text"
            textField.delegate = self
            textField.accessibilityIdentifier = "textIdentifier"
        }
        
        alertController.addTextField { (textField) in
            textField.placeholder = "Add font size"
            textField.delegate = self
            textField.keyboardType = .numberPad
            textField.accessibilityIdentifier = "numIdentifier"
            textField.text = "20"
        }
        
        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true, completion: nil)
    }
}

extension ViewController: MoviePlayerDelegate {
    func moviePlayer(_ moviePlayer: OSAT_VideoCompositor.MoviePlayer, didReceivePlayBack time: CMTime) {
        slider.value = Float(time.seconds)
    }
}

// MARK: - UIImagePickerControllerDelegate
extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        DispatchQueue.main.async {
            picker.dismiss(animated: true)
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let imageAva = info["UIImagePickerControllerOriginalImage"] {
            self.selectedImageSrc = imageAva as? UIImage
        } else {
            guard let imageUrl = info["UIImagePickerControllerMediaURL"] else { picker.dismiss(animated: true)
                return }
            tmpVideoSrcUrl = (imageUrl as? URL)
            originalVideoUrl = tmpVideoSrcUrl
        }

        DispatchQueue.main.async {
            picker.dismiss(animated: true)
        }
    }
}

// MARK: - UIDocumentPickerDelegate
extension ViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        exportUrl = urls.first
        controller.dismiss(animated: true)
        let videoName = UUID().uuidString
        
        let finalUrl = exportUrl!
          .appendingPathComponent(videoName)
          .appendingPathExtension("mov")
        
        do {
            guard let atUrl = tmpUrl else { return }
            try FileManager.default.moveItem(at: atUrl, to: finalUrl)
        } catch {
            print("error: \(error)")
        }
    }
}

// MARK: - UITextFieldDelegate
extension ViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let maxLength = 25
        let currentString = textField.text ?? ""
        let newString =  currentString + string
        
        return newString.count <= maxLength
    }
}

// MARK: - UIColorPickerViewControllerDelegate
extension ViewController: UIColorPickerViewControllerDelegate {
    func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
        self.fontColor = viewController.selectedColor
    }
}
