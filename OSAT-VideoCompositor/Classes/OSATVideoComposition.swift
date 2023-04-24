//
//  OSATVideoComposition.swift
//  OSAT-VideoCompositor
//
//  Created by hdutt on 17/12/22.
//

import AVFoundation

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
        
        let videoInfo = orientation(from: assetTrack.preferredTransform)
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
        
        guard let export = AVAssetExportSession(
            asset: composition,
            presetName: AVAssetExportPresetHighestQuality)
        else {
            NSLog("Cannot create export session.", "")
            errorHandler(.assetExportSessionFailed)
            return
        }
        
        let videoName = UUID().uuidString
        let exportURL = exportURL.appendingPathComponent(videoName).appendingPathExtension("mov")
        
        export.videoComposition = videoComposition
        export.outputFileType = .mov
        export.outputURL = exportURL
        
        export.exportAsynchronously {
            DispatchQueue.main.async {
                switch export.status {
                case .completed:
                    completionHandler(export)
                default:
                    errorHandler(.assetExportSessionFailed)
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
    
    public func createMultiVideoComposition(sourceVideoURL: [URL], exportURL: URL, completionHandler: @escaping(_ videExportSession: AVAssetExportSession) -> Void, errorHandler: @escaping(_ error: OSATVideoCompositionError) -> Void) {
        // currently it's supports same size and resolution video
        
        let composition = AVMutableComposition()
        var videoInstructions = [AVMutableVideoCompositionInstruction]()
        var nextClipStartTime = CMTime.zero
        
        guard let compositionVideoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid),
              let compositionAudioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)  else {
            NSLog("track not created.", "")
            errorHandler(.mutableTrackFailed)
            return
        }
        
        // build composition
        for sourceVideoUrl in sourceVideoURL {
            let asset = AVAsset(url: sourceVideoUrl)
            if asset.tracks(withMediaType: .video).count != 0 {
                do {
                    try compositionVideoTrack.insertTimeRange(CMTimeRange(start: .zero, duration: asset.duration), of: asset.tracks(withMediaType: .video)[0], at: nextClipStartTime)
                } catch { print(error) }
            }
            
            if asset.tracks(withMediaType: .audio).count != 0 {
                do {
                    try compositionAudioTrack.insertTimeRange(CMTimeRange(start: .zero, duration: asset.duration), of: asset.tracks(withMediaType: .video)[0], at: nextClipStartTime)
                } catch { print(error) }
            }
            // build transition instruction
            let instruction = AVMutableVideoCompositionInstruction()
            instruction.timeRange = CMTimeRange(start: .zero, duration: asset.duration)
            let layerInstruction = compositionLayerInstruction(for: compositionVideoTrack, assetTrack: asset.tracks(withMediaType: .video)[0])
            instruction.layerInstructions = [layerInstruction]
            videoInstructions.append(instruction)
            nextClipStartTime = CMTimeAdd(nextClipStartTime, asset.duration)
        }
        let asset = AVAsset(url: sourceVideoURL[0])
        let assetTrack = asset.tracks(withMediaType: .video)[0]
        
        let videoInfo = orientation(from: assetTrack.preferredTransform)
        let videoSize: CGSize = videoInfo.isPortrait ? CGSize(width: assetTrack.naturalSize.height, height: assetTrack.naturalSize.width) : assetTrack.naturalSize
        
        compositionVideoTrack.preferredTransform = assetTrack.preferredTransform
        
        let videoComposition = AVMutableVideoComposition()
        videoComposition.renderSize = videoSize
        videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
        videoComposition.instructions = videoInstructions
        
        guard let export = AVAssetExportSession(
            asset: composition,
            presetName: AVAssetExportPresetHighestQuality)
        else {
            NSLog("Cannot create export session.", "")
            errorHandler(.assetExportSessionFailed)
            return
        }
        
        let videoName = UUID().uuidString
        let exportURL = exportURL.appendingPathComponent(videoName).appendingPathExtension("mov")
        
        export.videoComposition = videoComposition
        export.outputFileType = .mov
        export.outputURL = exportURL
        
        export.exportAsynchronously {
            DispatchQueue.main.async {
                switch export.status {
                case .completed:
                    completionHandler(export)
                default:
                    errorHandler(.assetExportSessionFailed)
                    break
                }
            }
        }
    }
    
    public func createVideoTrimComposition(sourceVideoURL: URL, exportURL: URL, trimTime: CMTimeRange, completionHandler: @escaping(_ videExportSession: AVAssetExportSession) -> Void, errorHandler: @escaping(_ error: OSATVideoCompositionError) -> Void) {
        
        let composition = AVMutableComposition()
        let asset = AVAsset(url: sourceVideoURL)
        
        guard let compositionTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid), let assetTrack = asset.tracks(withMediaType: .video).first else {
            NSLog("Video asset is corrupt.", "")
            errorHandler(.videoAssetCorrupt)
            return
        }
        
        do {
            // custom timerange for trim
            let timeRange = trimTime
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
        
        let videoInfo = orientation(from: assetTrack.preferredTransform)
        let videoSize: CGSize = videoInfo.isPortrait ? CGSize(width: assetTrack.naturalSize.height, height: assetTrack.naturalSize.width) : assetTrack.naturalSize
        
        let videoComposition = AVMutableVideoComposition()
        videoComposition.renderSize = videoSize
        videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
        
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRange(start: .zero, duration: composition.duration)
        videoComposition.instructions = [instruction]
        
        let layerInstruction = compositionLayerInstruction(for: compositionTrack, assetTrack: assetTrack)
        instruction.layerInstructions = [layerInstruction]
        
        guard let export = AVAssetExportSession(
            asset: composition,
            presetName: AVAssetExportPresetHighestQuality)
        else {
            NSLog("Cannot create export session.", "")
            errorHandler(.assetExportSessionFailed)
            return
        }
        
        let videoName = UUID().uuidString
        let exportURL = exportURL.appendingPathComponent(videoName).appendingPathExtension("mov")
        
        export.videoComposition = videoComposition
        export.outputFileType = .mov
        export.outputURL = exportURL
        
        export.exportAsynchronously {
            DispatchQueue.main.async {
                switch export.status {
                case .completed:
                    completionHandler(export)
                default:
                    errorHandler(.assetExportSessionFailed)
                    break
                }
            }
        }
    }
}
