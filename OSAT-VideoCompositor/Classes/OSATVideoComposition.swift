//
//  OSATVideoComposition.swift
//  OSAT-VideoCompositor
//
//  Created by hdutt on 17/12/22.
//

import AVFoundation
public struct OSATVideoSource {
    public let videoURL: URL
    public let startTime: Double
    public let duration: Double
    public init(videoURL: URL, startTime: Double, duration: Double) {
        self.videoURL = videoURL
        self.startTime = startTime
        self.duration = duration
    }
}

public struct OSATVideoComposition {
    
    public init() {}
    
    /// Creates a video composition for a source video with annotations
    /// - Parameters:
    ///   - sourceVideoURL: URL for the source video
    ///   - exportURL: URL for saving the exported video
    ///   - annotations: list of annotations confroming to OSATAnnotationProtocol
    ///   - completionHandler: completionHandler is called when video composition execute succesfully
    ///   - errorHandler: errorHandler is called when video composition failed due to any reason
    public func createVideoComposition(sourceVideoURL: URL, exportURL: URL, annotations: [OSATAnnotationProtocol], completionHandler: @escaping(_ videExportSession: AVAssetExportSession) -> Void, errorHandler: @escaping(_ error: OSATVideoCompositionError) -> Void) {
        
        let composition = AVMutableComposition()
        let asset = AVAsset(url: sourceVideoURL)
        
        guard let compositionTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid), let assetTrack = asset.tracks(withMediaType: .video).first else {
            NSLog("Video asset is corrupt.", "")
            errorHandler(.videoAssetCorrupt)
            return
        }
        
        do {
            let timeRange = CMTimeRange(start: .zero, duration: asset.duration)
            try compositionTrack.insertTimeRange(timeRange, of: assetTrack, at: .zero)
            
            if let audioAssetTrack = asset.tracks(withMediaType: .audio).first, let compositionAudioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) {
                try compositionAudioTrack.insertTimeRange(timeRange, of: audioAssetTrack, at: .zero)
            }
        } catch {
            NSLog("Failed to insert audio track", "")
            errorHandler(.videoAssetCorrupt)
            return
        }
        
        compositionTrack.preferredTransform = assetTrack.preferredTransform
        
        let videoInfo = assetTrack.preferredTransform.orientation
        let videoSize: CGSize = videoInfo.isPortrait ? CGSize(width: assetTrack.naturalSize.height, height: assetTrack.naturalSize.width) : assetTrack.naturalSize
        
        let videoLayer = CALayer()
        videoLayer.frame = CGRect(origin: .zero, size: videoSize)
        
        videoLayer.frame = CGRect(
            x: 0,
            y: 0,
            width: videoSize.width,
            height: videoSize.height)
        
        let outputLayer = CALayer()
        outputLayer.frame = CGRect(origin: .zero, size: videoSize)
        outputLayer.addSublayer(videoLayer)
        
        annotations.forEach { outputLayer.addSublayer($0.getAnnotationLayer()) }
        
        let videoComposition = AVMutableVideoComposition()
        videoComposition.renderSize = videoSize
        videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
        videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer, in: outputLayer)
        
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRange(start: .zero, duration: composition.duration)
        videoComposition.instructions = [instruction]
        
        let layerInstruction = compositionLayerInstruction(for: compositionTrack, assetTrack: assetTrack)
        instruction.layerInstructions = [layerInstruction]
        
        export(composition: composition, videoComposition: videoComposition, exportURL: exportURL, completionHandler: completionHandler, errorHandler: errorHandler)
    }

    /// Make a video from multiple videos. The user is able to merge and trim videos.
    /// - Parameters:
    ///   - sourceItems: add source videos
    ///   - animation: set `true` for video end animation otherwise false
    ///   - exportURL: URL for saving the exported video
    ///   - completionHandler: completionHandler is called when video composition execute succesfully
    ///   - errorHandler: errorHandler is called when video composition failed due to any reason
    public func makeMultiVideoComposition(from sourceItems:[OSATVideoSource], animation:Bool = true, exportURL: URL, completionHandler: @escaping(_ videExportSession: AVAssetExportSession) -> Void, errorHandler: @escaping(_ error: OSATVideoCompositionError)->Void) {
        var insertTime = CMTime.zero
        // currently it's support only single canvas size
        let defaultSize = CGSize(width: 1280, height: 1280) // Default video size
        var arrayLayerInstructions:[AVMutableVideoCompositionLayerInstruction] = []

        // Init composition
        let mixComposition = AVMutableComposition()
        
        for videoSource in sourceItems {
            let videoAsset = AVAsset(url: videoSource.videoURL)
            // Get video track
            guard let videoTrack = videoAsset.tracks(withMediaType: AVMediaType.video).first else { continue }
            
            // Get audio track
            var audioTrack:AVAssetTrack?
            if videoAsset.tracks(withMediaType: AVMediaType.audio).count > 0 {
                audioTrack = videoAsset.tracks(withMediaType: AVMediaType.audio).first
            }
            
            // Init video & audio composition track
            let videoCompositionTrack = mixComposition.addMutableTrack(withMediaType: AVMediaType.video,
                                                                       preferredTrackID: Int32(kCMPersistentTrackID_Invalid))
            
            let audioCompositionTrack = mixComposition.addMutableTrack(withMediaType: AVMediaType.audio,
                                                                       preferredTrackID: Int32(kCMPersistentTrackID_Invalid))
            
            do {
                let startTime = videoSource.startTime.toCMTime() // CMTime.zero
                let duration = videoSource.duration.toCMTime() // videoAsset.duration
                
                // Add video track to video composition at specific time
                try videoCompositionTrack?.insertTimeRange(CMTimeRangeMake(start: startTime, duration: duration),
                                                           of: videoTrack,
                                                           at: insertTime)
                
                // Add audio track to audio composition at specific time
                if let audioTrack = audioTrack {
                    try audioCompositionTrack?.insertTimeRange(CMTimeRangeMake(start: startTime, duration: duration),
                                                               of: audioTrack,
                                                               at: insertTime)
                }
                
                // Add layer instruction for video track
                if let videoCompositionTrack = videoCompositionTrack {
                    let layerInstruction = videoCompositionInstructionForTrack(track: videoCompositionTrack, asset: videoAsset, targetSize: defaultSize)
                    
                    // Hide video track before changing to new track
                    let endTime = CMTimeAdd(insertTime, duration)
                    
                    if animation {
                        let durationAnimation = 1.0.toCMTime()
                        
                        layerInstruction.setOpacityRamp(fromStartOpacity: 1.0, toEndOpacity: 0.0, timeRange: CMTimeRange(start: endTime, duration: durationAnimation))
                    }
                    else {
                        layerInstruction.setOpacity(0, at: endTime)
                    }
                    
                    arrayLayerInstructions.append(layerInstruction)
                }
                
                // Increase the insert time
                insertTime = CMTimeAdd(insertTime, duration)
            }
            catch {
                print("Load track error")
            }
        }
        
        // Main video composition instruction
        let mainInstruction = AVMutableVideoCompositionInstruction()
        mainInstruction.timeRange = CMTimeRangeMake(start: CMTime.zero, duration: insertTime)
        mainInstruction.layerInstructions = arrayLayerInstructions
        
        // Main video composition
        let mainVideoComposition = AVMutableVideoComposition()
        mainVideoComposition.instructions = [mainInstruction]
        mainVideoComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
        mainVideoComposition.renderSize = defaultSize
        
        // do export
        export(composition: mixComposition, videoComposition: mainVideoComposition, exportURL: exportURL, completionHandler: completionHandler, errorHandler: errorHandler)
    }
    
    private func export(composition: AVMutableComposition, videoComposition: AVMutableVideoComposition, exportURL: URL, completionHandler: @escaping(_ videExportSession: AVAssetExportSession) -> Void, errorHandler: @escaping(_ error: OSATVideoCompositionError)->Void) {
        
        guard let export = AVAssetExportSession(
            asset: composition,
            presetName: AVAssetExportPresetHighestQuality)
        else {
            NSLog("Cannot create export session.", "")
            errorHandler(.assetExportSessionFailed)
            return
        }
        
        let videoName = UUID().uuidString
        let exportURL = exportURL.appendingPathComponent(videoName).appendingPathExtension("mp4")
        
        export.videoComposition = videoComposition
        export.outputFileType = .mov
        export.outputURL = exportURL
        
        export.exportAsynchronously(completionHandler: {
            DispatchQueue.main.async {
                switch export.status {
                case .completed:
                    completionHandler(export)
                default:
                    print(export.error ?? "")
                    errorHandler(.assetExportSessionFailed)
                    break
                }
            }
        })
    }
    
    private func videoCompositionInstructionForTrack(track: AVCompositionTrack?, asset: AVAsset, targetSize: CGSize) -> AVMutableVideoCompositionLayerInstruction {
        guard let track = track else {
            return AVMutableVideoCompositionLayerInstruction()
        }
        
        let instruction = AVMutableVideoCompositionLayerInstruction(assetTrack: track)
        let assetTrack = asset.tracks(withMediaType: AVMediaType.video)[0]

        let transform = assetTrack.fixedPreferredTransform
        let assetOrientation = transform.orientation
        
        let scaleToFitRatio = min(targetSize.width / assetTrack.naturalSize.width, targetSize.width / assetTrack.naturalSize.height)
        if assetOrientation.isPortrait {
            // Scale to fit target size
            let scaleFactor = CGAffineTransform(scaleX: scaleToFitRatio, y: scaleToFitRatio)
            
            // Align center Y
            let newX = targetSize.width/2 - ((assetTrack.naturalSize.height / 2) * scaleToFitRatio)
            let newY = targetSize.height/2 - ((assetTrack.naturalSize.width / 2) * scaleToFitRatio)
            let moveCenterFactor = CGAffineTransform(translationX: newX, y: newY)
            
            let finalTransform = transform.concatenating(scaleFactor).concatenating(moveCenterFactor)

            instruction.setTransform(finalTransform, at: .zero)
        } else {
            // Scale to fit target size
            let scaleFactor = CGAffineTransform(scaleX: scaleToFitRatio, y: scaleToFitRatio)
            
            // Align center Y
            let newY = targetSize.height/2 - (assetTrack.naturalSize.height * scaleToFitRatio)/2
            let moveCenterFactor = CGAffineTransform(translationX: 0, y: newY)
            
            let finalTransform = transform.concatenating(scaleFactor).concatenating(moveCenterFactor)
            
            instruction.setTransform(finalTransform, at: .zero)
        }

        return instruction
    }
    
    
    private func compositionLayerInstruction(for track: AVCompositionTrack, assetTrack: AVAssetTrack) -> AVMutableVideoCompositionLayerInstruction {
        let instruction = AVMutableVideoCompositionLayerInstruction(assetTrack: track)
        let transform = assetTrack.preferredTransform
        instruction.setTransform(transform, at: .zero)
        return instruction
    }
}
