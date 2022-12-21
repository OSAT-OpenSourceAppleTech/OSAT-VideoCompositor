//
//  OSATVideoComposition.swift
//  OSAT-VideoCompositor
//
//  Created by hdutt on 17/12/22.
//

import AVFoundation

struct OSATVideoComposition {
    
    /// Creates a video composition for a source video with annotations
    /// - Parameters:
    ///   - sourceVideoURL: URL for the source video
    ///   - exportURL: URL for saving the exported video
    ///   - annotations: list of annotations confroming to OSATAnnotationProtocol
    ///   - completionHandler: completionHandler is called when video composition execute succesfully
    ///   - errorHandler: errorHandler is called when video composition failed due to any reason
    func createVideoComposition(sourceVideoURL: URL, exportURL: URL, annotations: [OSATAnnotationProtocol], completionHandler: @escaping(_ videExportSession: AVAssetExportSession) -> Void, errorHandler: @escaping(_ error: OSATVideoCompositionError) -> Void) {
        
    }
}
