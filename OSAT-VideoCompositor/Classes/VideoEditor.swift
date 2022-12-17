//
//  VideoEditor.swift
//  OSAT-VideoCompositor
//
//  Created by Rohit Sharma on 17/12/22.
//

import AVFoundation

class VideoEditor {
    private var positionOfWaterMark: WaterMarkPosition = .LeftBottomCorner
    
    public func addWatermark(text: String, image: UIImage? = nil, inputURL: URL, outputURL: URL? = nil, position: WaterMarkPosition = .RightBottomCorner, fontSize: Int? = 20, fontColor: UIColor = .black, handler: @escaping (_ exportSession: AVAssetExportSession?) -> Void) {
        let composition = AVMutableComposition()
        let asset = AVAsset(url: inputURL)
        self.positionOfWaterMark = position
        guard let compositionTrack = composition.addMutableTrack(
            withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid),
              let assetTrack = asset.tracks(withMediaType: .video).first
        else {
            NSLog("Something is wrong with the asset.", "")
            handler(nil)
            return
        }
        do {
            let timeRange = CMTimeRange(start: .zero, duration: asset.duration)
            try compositionTrack.insertTimeRange(timeRange, of: assetTrack, at: .zero)
            
            if let audioAssetTrack = asset.tracks(withMediaType: .audio).first,
               let compositionAudioTrack = composition.addMutableTrack(
                withMediaType: .audio,
                preferredTrackID: kCMPersistentTrackID_Invalid) {
                try compositionAudioTrack.insertTimeRange(
                    timeRange,
                    of: audioAssetTrack,
                    at: .zero)
            }
        } catch {
            NSLog("error occurred: \(error)", "")
            handler(nil)
            return
        }
        
        compositionTrack.preferredTransform = assetTrack.preferredTransform
        let videoInfo = orientation(from: assetTrack.preferredTransform)
        
        let videoSize: CGSize
        if videoInfo.isPortrait {
            videoSize = CGSize(
                width: assetTrack.naturalSize.height,
                height: assetTrack.naturalSize.width)
        } else {
            videoSize = assetTrack.naturalSize
        }
        
        
        let backgroundLayer = CALayer()
        backgroundLayer.frame = CGRect(origin: .zero, size: videoSize)
        let videoLayer = CALayer()
        videoLayer.frame = CGRect(origin: .zero, size: videoSize)
        let overlayLayer = CALayer()
        overlayLayer.frame = CGRect(origin: .zero, size: videoSize)
        
        videoLayer.frame = CGRect(
            x: 0,
            y: 0,
            width: videoSize.width,
            height: videoSize.height)
        
        //backgroundLayer.contents = UIImage(named: "background")?.cgImage
        backgroundLayer.contentsGravity = .resizeAspectFill
        
        
        let outputLayer = CALayer()
        outputLayer.frame = CGRect(origin: .zero, size: videoSize)
        outputLayer.addSublayer(backgroundLayer)
        outputLayer.addSublayer(videoLayer)
        outputLayer.addSublayer(overlayLayer)
        
        let imgSize = addImage(image: image, to: overlayLayer, videoSize: videoSize, fontSize: fontSize, isText: !text.isEmpty)
        if !text.isEmpty {
            add(
                text: text,
                to: overlayLayer,
                videoSize: videoSize, fontSize: fontSize, imageSize: imgSize, fontColor: fontColor)
        }
        
        
        let videoComposition = AVMutableVideoComposition()
        videoComposition.renderSize = videoSize
        videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
        videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(
            postProcessingAsVideoLayer: videoLayer,
            in: outputLayer)
        
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRange(
            start: .zero,
            duration: composition.duration)
        videoComposition.instructions = [instruction]
        let layerInstruction = compositionLayerInstruction(
            for: compositionTrack,
            assetTrack: assetTrack)
        instruction.layerInstructions = [layerInstruction]
        
        guard let export = AVAssetExportSession(
            asset: composition,
            presetName: AVAssetExportPresetHighestQuality)
        else {
            NSLog("Cannot create export session.", "")
            handler(nil)
            return
        }
        
        let videoName = UUID().uuidString
        let exportURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(videoName)
            .appendingPathExtension("mov")
        
        export.videoComposition = videoComposition
        export.outputFileType = .mov
        export.outputURL = exportURL
        
        export.exportAsynchronously {
            DispatchQueue.main.async {
                switch export.status {
                case .completed:
                    handler(export)
                default:
                    handler(nil)
                    break
                }
            }
        }
    }
    
    private func compositionLayerInstruction(for track: AVCompositionTrack, assetTrack: AVAssetTrack) -> AVMutableVideoCompositionLayerInstruction {
        let instruction = AVMutableVideoCompositionLayerInstruction(assetTrack: track)
        let transform = assetTrack.preferredTransform
        
        instruction.setTransform(transform, at: .zero)
        
        return instruction
    }
    
    private func add(text: String, to layer: CALayer, videoSize: CGSize, fontSize: Int?, imageSize: CGRect? = nil, fontColor: UIColor = .black) {
        let currentFontSize = fontSize ?? 20
        let attributedText = NSAttributedString(
            string: text,
            attributes: [
                .font: UIFont(name: "ArialRoundedMTBold", size: CGFloat(currentFontSize)) as Any,
                .foregroundColor: fontColor])
        
        let textLayer = CATextLayer()
        textLayer.string = attributedText
        textLayer.shouldRasterize = true
        textLayer.rasterizationScale = UIScreen.main.scale
        textLayer.backgroundColor = UIColor.clear.cgColor
        textLayer.alignmentMode = .center
        
        let height: CGFloat = CGFloat((30 + currentFontSize))
        let wd = attributedText.width(containerHeight: height)
        
        let startX = (videoSize.width - wd)
        var rect = CGRect(x: startX, y: 0, width: wd, height: height)
        var yPos: CGFloat = .zero
        
        if let imageSize = imageSize {
            yPos = imageSize.height + 10
        }
        
        // custom logic for positioning, still requires fixing
        switch positionOfWaterMark {
        case .LeftBottomCorner:
            rect = CGRect(x: 10, y: 0, width: wd, height: height)
        case .RightBottomCorner:
            rect = CGRect(x: startX - 10, y: 0, width: wd, height: height)
        case .LeftTopCorner:
            rect = CGRect(x: 10, y: videoSize.height - (yPos + height), width: wd, height: height)
        case .RightTopCorner:
            rect = CGRect(x: startX - 10, y: videoSize.height - (yPos + height), width: wd + 10, height: height)
        }
        
        textLayer.frame = rect
        textLayer.displayIfNeeded()
        
        layer.addSublayer(textLayer)
    }
    
    private func orientation(from transform: CGAffineTransform) -> (orientation: UIImage.Orientation, isPortrait: Bool) {
        var assetOrientation = UIImage.Orientation.up
        var isPortrait = false
        if transform.a == 0 && transform.b == 1.0 && transform.c == -1.0 && transform.d == 0 {
            assetOrientation = .right
            isPortrait = true
        } else if transform.a == 0 && transform.b == -1.0 && transform.c == 1.0 && transform.d == 0 {
            assetOrientation = .left
            isPortrait = true
        } else if transform.a == 1.0 && transform.b == 0 && transform.c == 0 && transform.d == 1.0 {
            assetOrientation = .up
        } else if transform.a == -1.0 && transform.b == 0 && transform.c == 0 && transform.d == -1.0 {
            assetOrientation = .down
        }
        
        return (assetOrientation, isPortrait)
    }
    
    private func addImage(image: UIImage?, to layer: CALayer, videoSize: CGSize, fontSize: Int?, isText: Bool) -> CGRect {
        guard let image = image else { return  .zero }
        let imageLayer = CALayer()
        
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
        imageLayer.frame = rect
        
        imageLayer.contents = image.cgImage
        layer.addSublayer(imageLayer)
        
        return rect
    }
}
