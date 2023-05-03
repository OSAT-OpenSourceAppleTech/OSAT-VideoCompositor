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
    private struct Constants {
        static let playButton = "play.circle.fill"
        static let pauseButton = "pause.circle.fill"
        static let iconSize: CGFloat = 40
    }
    
    // MARK: - Private variables
    private var duration: CMTime?
    private var videoSourceUrl: URL? {
        didSet {
            updateVideoPlayerUrl()
        }
    }
    
    private var waterMarkPosition: OSATWaterMarkPosition = .LeftTopCorner
    private var exportUrl: URL?
    private var selectedImageSrc: UIImage?
    private var originalVideoUrl: URL?
    private var tmpVideoSrcUrl: URL? {
        didSet {
            updateVideoPlayerUrl()
        }
    }
    
    // MARK: - Default Text WaterMark properties
    private var text: String = ""
    private var fontSize: Int = 20
    private var fontColor: UIColor = .yellow
    
    // MARK: - UI
    private var videoPlayerLayer: AVPlayerView!
    
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
        view.backgroundColor = .systemBackground
        
        videoPlayerLayer?.set(url: url)
        videoPlayerLayer?.delegate = self
        videoPlayerLayer?.registerTimeIntervalForObservingPlayer(1)
        videoPlayerLayer.translatesAutoresizingMaskIntoConstraints = false
        
        navigationItem.title = "OSAT Video Compositer"
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "ellipsis.circle"), style: .plain, target: self, action: nil)
        navigationItem.rightBarButtonItem?.menu = createVideoImageMenu()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: nil)
        navigationItem.leftBarButtonItem?.menu = createWaterMarkMenu()
        navigationController?.navigationBar.barStyle = .default
        
        videoPlayerLayer.backgroundColor = .systemGroupedBackground
        addSubviews()
        setButtonProperties()
        setupConstraints()
        Task {
            await getDuration()
        }
    }
    
    private func addSubviews() {
        view.addSubview(playerView)
        view.addSubview(sliderParentView)
        
        sliderParentView.isUserInteractionEnabled = true
        sliderParentView.addSubview(slider)
        sliderParentView.addSubview(playbutton)
        
        playerView.addSubview(videoPlayerLayer)
        playerView.addSubview(spinner)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            playerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            playerView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            playerView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            
            videoPlayerLayer.centerXAnchor.constraint(equalTo: playerView.centerXAnchor),
            videoPlayerLayer.centerYAnchor.constraint(equalTo: playerView.centerYAnchor),
            videoPlayerLayer.leadingAnchor.constraint(equalTo: playerView.leadingAnchor),
            videoPlayerLayer.trailingAnchor.constraint(equalTo: playerView.trailingAnchor),
            videoPlayerLayer.heightAnchor.constraint(equalTo: videoPlayerLayer.widthAnchor, multiplier: 1),
            
            spinner.centerYAnchor.constraint(equalTo: playerView.centerYAnchor),
            spinner.centerXAnchor.constraint(equalTo: playerView.centerXAnchor),
            
            sliderParentView.topAnchor.constraint(equalTo: playerView.bottomAnchor, constant: 10),
            sliderParentView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 0),
            sliderParentView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            sliderParentView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            sliderParentView.heightAnchor.constraint(equalToConstant: 100.0),
            
            playbutton.centerYAnchor.constraint(equalTo: sliderParentView.centerYAnchor),
            playbutton.leadingAnchor.constraint(equalTo: sliderParentView.safeAreaLayoutGuide.leadingAnchor),
            playbutton.heightAnchor.constraint(equalToConstant: Constants.iconSize),
            playbutton.widthAnchor.constraint(equalToConstant: Constants.iconSize),
            
            slider.centerYAnchor.constraint(equalTo: sliderParentView.centerYAnchor),
            slider.leadingAnchor.constraint(equalTo: playbutton.safeAreaLayoutGuide.trailingAnchor, constant: 10),
            slider.trailingAnchor.constraint(equalTo: sliderParentView.safeAreaLayoutGuide.trailingAnchor, constant: -10)
            
        ])
    }
    
    private func updateMenu() {
        navigationItem.leftBarButtonItem?.menu = createWaterMarkMenu()
    }
    
    private func createWaterMarkMenu() -> UIMenu? {
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
        videoPlayerLayer.pause()
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
        
        let multiVideo = UIAction(title: "Merge & Trim", image: nil, identifier: UIAction.Identifier("leftBtm1"), attributes: [], state: .off) { action in
            self.mergeTrimVideoExample()
        }
        
        let selectImage = UIAction(title: "Select an Image", image: UIImage(systemName: "photo"), attributes: [], state: .off) { action in
            self.showImagePickerForWaterMark()
        }
        
        let pickFontColor = UIAction(title: "Select Font Color", image: UIImage(systemName: "pencil.tip"), identifier: UIAction.Identifier("pick font color"), attributes: [], state: .off) { action in
            self.showColorPicker()
        }
        
        let addTextItem = UIAction(title: "Add Text", image: UIImage(systemName: "pencil"), attributes: [], state: .off) { action in
            self.showTextFieldAlertToAddAsWaterMark()
        }
        
        let addOnlyImageItem = UIAction(title: "Add only image Watermark", image: UIImage(systemName: "photo.circle.fill"), attributes: [], state: .off) { action in
            self.handleComposeButtonButtonAction()
        }
        
        let setExportUrlItem = UIAction(title: "Set Export Url", image: UIImage(systemName: "square.and.arrow.up.circle.fill"), attributes: [], state: .off) { action in
            self.handleExportButtonAction()
        }
        
        let deferredMenu2 = UIDeferredMenuElement { (menuElements) in
            let menu = UIMenu(title: "Image/Font Color", options: .displayInline,  children: [addTextItem, selectImage, pickFontColor, addOnlyImageItem, setExportUrlItem])
            menuElements([menu])
        }
        
        let deferredMenu1 = UIDeferredMenuElement { (menuElements) in
            let menu = UIMenu(title: "Feature Example", options: .displayInline,  children: [multiVideo])
            menuElements([menu])
        }
        
        let elements: [UIAction] = [selectVideo]
        var menu = UIMenu(title: "Select Video", children: elements)
        menu = menu.replacingChildren([selectVideo, deferredMenu1, deferredMenu2])
        return menu
    }
    
    private func showImagePickerForWaterMark() {
        videoPlayerLayer.pause()
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
            self.duration = try await videoPlayerLayer?.getDuration()
            setupSliderProperties()
            NSLog("\(String(describing: duration))", "")
            
        } catch {
            NSLog("\(error)", "")
        }
    }
    
    private func setButtonProperties() {
        playbutton.setImage(UIImage(systemName: Constants.pauseButton, withConfiguration: UIImage.SymbolConfiguration(pointSize: Constants.iconSize)), for: .normal)
        playbutton.setImage(UIImage(systemName: Constants.playButton, withConfiguration: UIImage.SymbolConfiguration(pointSize: Constants.iconSize)), for: .selected)
    }
    
    @objc private func handlePlayButtonAction(_ sender: Any) {
        playbutton.isSelected ? play() : pause()
    }
    
    @objc private func handleComposeButtonButtonAction() {
        text = ""
        addWaterMark()
    }
    
    private func handleExportButtonAction() {
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
        videoPlayerLayer?.play()
        playbutton.isSelected = false
    }
    
    private func pause() {
        videoPlayerLayer.pause()
        playbutton.isSelected = true
    }
    
    private func updateVideoPlayerUrl() {
        guard let videoSourceUrl = tmpVideoSrcUrl else { return }
        videoPlayerLayer.set(url: videoSourceUrl)
        play()
        Task {
            await getDuration()
        }
    }
    
    @objc private func showTextFieldAlertToAddAsWaterMark() {
        showAlertWithTextField()
    }
    
    private func createImageAnnotation() -> OSATImageAnnotation? {
        guard let img = selectedImageSrc else { return nil }
        let imageFrame = addImage(image: img, videoSize: videoPlayerLayer.getVideoSize(), fontSize: 15, isText: false)
        let annotation = OSATImageAnnotation(image: img, frame: imageFrame, timeRange: nil, caption: "", attributedCaption: nil)
        return annotation
    }
    
    private func addImage(image: UIImage?, videoSize: CGSize, fontSize: Int?, isText: Bool, positionOfWaterMark: OSATWaterMarkPosition = .LeftTopCorner) -> CGRect {
        guard let image = image else { return  .zero }
        
        let aspect: CGFloat = image.size.width / image.size.height
        
        let width: CGFloat = videoSize.width / 6
        let height = width / aspect
        
        let wd = width
        let startX = (videoSize.width - width)
        
        var rect = CGRect(x: startX, y: 0, width: wd, height: height)
        let currentFontSize = isText ? (30 + (fontSize ?? 0)) : 10
        
        // custom logic for positioning
        switch positionOfWaterMark {
        case .LeftBottomCorner:
            rect = CGRect(x: 10, y: CGFloat(currentFontSize), width: wd, height: height)
        case .RightBottomCorner:
            rect = CGRect(x: startX, y: CGFloat(currentFontSize), width: wd - 10, height: height)
        case .LeftTopCorner:
            rect = CGRect(x: 10, y: videoSize.height - (height + 10), width: wd, height: height)
        case .RightTopCorner:
            rect = CGRect(x: startX, y: videoSize.height - (height + 10), width: wd - 10, height: height)
        }
        
        return rect
    }
    
    private func showExportUrlNotPresent() {
        let alertController = UIAlertController(title: "Please Select Export Url", message: nil, preferredStyle: .alert)
        let confirmAction = UIAlertAction(title: "Add Export Url", style: .default) { (_) in
            self.handleExportButtonAction()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in }
        
        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    private func mergeTrimVideoExample() {
        guard let portraitURL = Bundle.main.url(forResource: "portrait", withExtension: "MOV"),
              let landscapeURL = Bundle.main.url(forResource: "landscape", withExtension: "MOV")
        else { return }
        
        guard let exportUrl = exportUrl else {
            showExportUrlNotPresent()
            return
        }
        
        videoPlayerLayer.isHidden = true
        videoPlayerLayer.pause()
        
        spinner.isHidden = false
        spinner.startAnimating()
        
        let portraitAsset = OSATVideoSource(videoURL: portraitURL, startTime: 2, duration: 5)
        let landscapeAsset = OSATVideoSource(videoURL: landscapeURL, startTime: 2, duration: 5)
        
        DispatchQueue.global().async {
            let compositor = OSATVideoComposition()
            compositor.makeMultiVideoComposition(from: [portraitAsset, landscapeAsset], exportURL: exportUrl) { [weak self ] session in
                guard let self = self else { return }
                switch session.status {
                case .completed:
                    guard let sessionOutputUrl = session.outputURL, NSData(contentsOf: sessionOutputUrl) != nil else { return }
                    DispatchQueue.main.async {
                        self.videoPlayerLayer.set(url: sessionOutputUrl)
                        self.play()
                        self.videoPlayerLayer.isHidden = false
                        self.spinner.isHidden = true
                        self.spinner.stopAnimating()
                        Task {
                            await self.getDuration()
                        }
                    }
                
                case .failed:
                    NSLog("error: \(String(describing: session.error))", "")
                
                default: break
                }
            } errorHandler: { error in
                NSLog("\(error)", "")
            }
        }
    }
    
    private func addWaterMark() {
        guard let inputURL = originalVideoUrl else { return }
        
        var imgFrame: CGRect = .zero
        var annotations = [OSATAnnotationProtocol]()
        if selectedImageSrc != nil,  let imageAnnotation = createImageAnnotation() {
            imgFrame = addImage(image: selectedImageSrc, videoSize: videoPlayerLayer.getVideoSize(), fontSize: 20, isText: true)
            annotations.append(imageAnnotation)
        }
        
        if !text.isEmpty {
            let textAnnotation = AnnotationLayerUtils.createTextLayer(text: text, videoSize: videoPlayerLayer.getVideoSize(), fontSize: 20, imageSize: imgFrame, fontColor: fontColor, positionOfWaterMark: waterMarkPosition)
            annotations.append(textAnnotation)
        }
       
        guard !annotations.isEmpty else { return }
        
        guard let exportUrl = exportUrl else {
            showExportUrlNotPresent()
            return
        }
        
        videoPlayerLayer.isHidden = true
        videoPlayerLayer.pause()
        
        spinner.isHidden = false
        spinner.startAnimating()
        
        let osatVideoComposition = OSATVideoComposition()
        osatVideoComposition.createVideoComposition(sourceVideoURL: inputURL, exportURL: exportUrl, annotations: annotations) { [weak self ] session in
            guard let self = self else { return }
            
            switch session.status {
            case .completed:
                guard let sessionOutputUrl = session.outputURL, NSData(contentsOf: sessionOutputUrl) != nil else { return }
                self.videoPlayerLayer.set(url: sessionOutputUrl)
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
        } errorHandler: { error in
            NSLog("\(error)", "")
        }
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

// MARK: - AVPlayerCustomViewDelegate
extension ViewController: AVPlayerCustomViewDelegate {
    func avPlayerCustomView(_ avPlayerView: AVPlayerCustomView, didReceivePlayBack time: CMTime) {
        slider.value = Float(time.seconds)
    }
    
    func avPlayerCustomView(_ avPlayerView: AVPlayerCustomView, didSeek isSuccess: Bool) {}
}
