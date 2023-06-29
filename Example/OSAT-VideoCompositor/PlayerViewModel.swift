//
//  PlayerViewModel.swift
//  OSAT-VideoCompositor_Example
//
//  Created by Rohit Sharma on 18/02/23.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import OSAT_VideoCompositor
import AVFoundation

import Foundation
import SwiftUI
import UIKit

class PlayerViewModel: ObservableObject {
    @Published var inputVideoURL: URL?
    @Published var outputVideoURL: URL?
    @Published var seekBarValue: Float = 0.0
    @Published var loopButtonState: Bool = false
    @Published var isPlaying: Bool = false
    @Published var readyToPlay: Bool = false
    @Published var isProcessingVideo: Bool = false
    @Published var currentText: String = ""
    @Published var currentImage: UIImage? = nil
    var textCGPoint: CGPoint = .zero {
        didSet {
            whassup()
        }
    }
    var imageCGPoint: CGPoint = .zero
    var exportUrl: URL? {
        didSet {
            exportVideo()
        }
    }
    
    private var jobsList: [OSATAnnotationProtocol] = []
    private var layers: [CALayer] = []
    let playerView = AVPlayerViewWrapper(playerView: AVPlayerView(frame: .zero))
    
    init(inputVideoURL: URL? = nil, outputVideoURL: URL? = nil) {
        self.inputVideoURL = inputVideoURL
        self.outputVideoURL = outputVideoURL
        playerView.playerView.delegate = self
        loadVideo()
    }
    
    func whassup() {
        print("point: \(textCGPoint)")
    }
    
    func loadVideo() {
        inputVideoURL = Bundle.main.url(forResource: "Test", withExtension: ".mp4")
        initialiseVideoPlayer(with: inputVideoURL!)
        shouldPlayVideo(true)
    }
    
    func initialiseVideoPlayer(with url: URL) {
        playerView.playerView.set(url: url)
        playerView.playerView.registerTimeIntervalForObservingPlayer(1)
        inputVideoURL = url
        resetUI()
        readyToPlay = true
    }
    
    func resetUI() {
        seekBarValue = 0.0
        loopButtonState = false
        isPlaying = false
        readyToPlay = false
        isProcessingVideo = false
    }
    
    func updateLoopValue(_ value: Bool) {
        loopButtonState = value
        updateSeekPosition()
        if !loopButtonState {
            shouldPlayVideo(loopButtonState)
        }
    }
    
    func shouldPlayVideo(_ play: Bool) {
        isPlaying = play
        play ? playerView.playerView.play() : playerView.playerView.pause()
        updateSeekPosition()
    }
    
    func didChangeUrl(_ inputUrl: URL?) {
        self.inputVideoURL = inputUrl
        initialiseVideoPlayer(with: inputUrl!)
    }
    
    func addTextLayer(layer: CATextLayer) {
        let adjustedFrame = CGRect(x: 50, y: 50, width: 100, height: 100)
        layer.frame = adjustedFrame
        layers.append(layer)
        currentText = layer.string as? String ?? ""
    }
    
    func showPreview(layer: CALayer, image: UIImage) {
        let adjustedFrame = CGRect(x: 50, y: 50, width: 100, height: 100)
        layer.frame = adjustedFrame
        layers.append(layer)
        jobsList.append(OSATImageAnnotation(image: image, frame: adjustedFrame, timeRange: nil, caption: "", attributedCaption: nil))
    }
    
    func removePreviews() {
        layers.forEach({ $0.removeFromSuperlayer() })
        currentImage = nil
        currentText = ""
    }
    
    func updateSeekPosition() {
        let elapsedSeconds = playerView.playerView.player?.currentTime().seconds ?? 0
        let totalSeconds = playerView.playerView.player?.currentItem?.duration.seconds ?? 0
        seekBarValue = Float(elapsedSeconds / totalSeconds);
        if (seekBarValue == 1 && isPlaying) {
            playerView.playerView.player?.seek(to: kCMTimeZero)
            if (loopButtonState) {
                playerView.playerView.play()
            } else {
                isPlaying = false
            }
        }
    }
    
    func exportVideo() {
        print("exported video")
        // (0,0) x = -110, y = 139 (0,0)
        // (0, 317) top left = x = -115, y = -55
        // (390, 317) -> (205, -55)
        // (390, 0) -> 213, 141
        
        let videoSize = playerView.playerView.getVideoSize()
        let px = textCGPoint.x + 130
        let py = textCGPoint.y - 150
        let newx = playerView.playerView.frame.minX + 0
        let newy = playerView.playerView.frame.minY + 0
        let attributedText = NSAttributedString(
            string: currentText,
            attributes: [
                .font: UIFont(name: "ArialRoundedMTBold", size: CGFloat(70)) as Any,
                .foregroundColor: UIColor.white])
        
        let layerTwo = OSATTextAnnotation(text: "", frame: CGRect(x: px, y: py, width: 300, height: 300), timeRange: nil, attributedText: attributedText, textColor: .white, backgroundColor: .clear, font: nil)
        jobsList.append(layerTwo)
        
        guard let exportUrl = exportUrl, let inputVideoURL = inputVideoURL else {
            print("error video")
            return
        }
        
        let osatVideoComposition = OSATVideoComposition()
        osatVideoComposition.createVideoComposition(sourceVideoURL: inputVideoURL, exportURL: exportUrl, annotations: jobsList) { [weak self ] session in
            guard let self = self else { return }
            
            switch session.status {
            case .completed:
                guard let sessionOutputUrl = session.outputURL, NSData(contentsOf: sessionOutputUrl) != nil else { return }
            
            case .failed:
                NSLog("error: \(String(describing: session.error))", "")
            
            default: break
            }
        } errorHandler: { error in
            NSLog("\(error)", "")
        }
    }
}
extension PlayerViewModel: AVPlayerCustomViewDelegate {
    func avPlayerCustomView(_ avPlayerView: AVPlayerCustomView, didReceivePlayBack time: CMTime) {
        updateSeekPosition()
    }
    
    func avPlayerCustomView(_ avPlayerView: AVPlayerCustomView, didSeek isSuccess: Bool) {
        
    }
    
    
}

struct DocumentPicker: UIViewControllerRepresentable {
    @EnvironmentObject var playerInstance: PlayerViewModel
    
    func makeCoordinator() -> DocumentPicker.Coordinator {
        return DocumentPicker.Coordinator(parent: self)
    }
    func makeUIViewController(context: UIViewControllerRepresentableContext<DocumentPicker>) -> UIDocumentPickerViewController {
        let documentPicker =
            UIDocumentPickerViewController(forOpeningContentTypes: [.folder])
        documentPicker.allowsMultipleSelection = false
        documentPicker.directoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        documentPicker.delegate = context.coordinator
        return documentPicker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: UIViewControllerRepresentableContext<DocumentPicker>) {}
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker
        init(parent: DocumentPicker) {
            self.parent = parent
        }
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {

            parent.playerInstance.exportUrl = urls.first
            controller.dismiss(animated: true)
        }
    }
    
}
