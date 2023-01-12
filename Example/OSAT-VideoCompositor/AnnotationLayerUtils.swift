//
//  AnnotationLayerUtils.swift
//  OSAT-VideoCompositor_Example
//
//  Created by Rohit Sharma on 12/01/23.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import AVFoundation
import OSAT_VideoCompositor

struct AnnotationLayerUtils {
    static func createTextLayer(text: String, videoSize: CGSize, fontSize: Int?, imageSize: CGRect? = nil, fontColor: UIColor = .black, positionOfWaterMark: OSATWaterMarkPosition) -> OSATTextAnnotation {
        let attributedText = NSAttributedString(
            string: text,
            attributes: [
                .font: UIFont(name: "ArialRoundedMTBold", size: CGFloat(fontSize ?? 20)) as Any,
                .foregroundColor: fontColor])
        
        let getFrameForText = getFrameForText(text: text, videoSize: videoSize, attributedText: attributedText, fontSize: fontSize, imageSize: imageSize, fontColor: fontColor, positionOfWaterMark: positionOfWaterMark)
        
        return OSATTextAnnotation(text: text, frame: getFrameForText, timeRange: nil, attributedText: attributedText, textColor: fontColor, backgroundColor: .clear, font: UIFont.systemFont(ofSize: CGFloat(fontSize ?? 20)))
    }
    
    static func getFrameForText(text: String, videoSize: CGSize, attributedText: NSAttributedString?, fontSize: Int?, imageSize: CGRect? = nil, fontColor: UIColor = .black, positionOfWaterMark: OSATWaterMarkPosition) -> CGRect {
        
        let currentFontSize = fontSize ?? 20
       

        let height: CGFloat = CGFloat((30 + currentFontSize))
        let wd = attributedText?.width(containerHeight: height) ?? .zero

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
        
        return rect
    }
}
