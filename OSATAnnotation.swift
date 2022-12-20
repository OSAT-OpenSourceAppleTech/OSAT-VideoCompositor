//
//  OSATAnnotation.swift
//  OSAT-VideoCompositor
//
//  Created by hdutt on 17/12/22.
//

import AVFoundation

/// OSATAnnotationProtocol  is a base protocol for all Annotation object layers supported by OSAT-VideoCompositor
protocol OSATAnnotationProtocol {
    func getAnnotationLayer() -> CALayer
}

/// OSATImageAnnotation holds data for  the image annotation to be rendered on Video
public struct OSATImageAnnotation: OSATAnnotationProtocol {
    let image: UIImage
    let frame: CGRect
    let timeRange: CMTimeRange
    let caption: String?
    let attributedCaption: AttributedString?
    
    public init(image: UIImage, frame: CGRect, timeRange: CMTimeRange, caption: String?, attributedCaption: AttributedString?) {
        self.image = image
        self.frame = frame
        self.timeRange = timeRange
        self.caption = caption
        self.attributedCaption = attributedCaption
    }
    
    public func getAnnotationLayer() -> CALayer {
        let imageLayer = CALayer()
        imageLayer.frame = frame
        imageLayer.contents = image.cgImage
        return imageLayer
    }
}


/// OSATTextAnnotation holds data for the text annotation to be rendered on Video
public struct OSATTextAnnotation: OSATAnnotationProtocol {
    let text: String
    let frame: CGRect
    let timeRange: CMTimeRange
    let attributedText: AttributedString?
    let textColor: UIColor?
    let backgroundColor: UIColor?
    let font: UIFont?
    
    public init(text: String, frame: CGRect, timeRange: CMTimeRange, attributedText: AttributedString?, textColor: UIColor?, backgroundColor: UIColor?, font: UIFont?) {
        self.text = text
        self.frame = frame
        self.timeRange = timeRange
        self.attributedText = attributedText
        self.textColor = textColor
        self.backgroundColor = backgroundColor
        self.font = font
    }

    public func getAnnotationLayer() -> CALayer {
        let textLayer = CATextLayer()
        textLayer.string = attributedText ?? text
        textLayer.font = font ?? UIFont(name: "Helvetica", size: CGFloat(20))
        textLayer.backgroundColor = backgroundColor?.cgColor ?? UIColor.clear.cgColor
        textLayer.frame = frame

        textLayer.shouldRasterize = true
        textLayer.rasterizationScale = UIScreen.main.scale
        textLayer.backgroundColor = UIColor.clear.cgColor
        textLayer.alignmentMode = .center
        textLayer.displayIfNeeded()
        return textLayer
    }
}


/// OSATBezierAnnotation holds data for the Bezier sPath annotation to be rendered on Video
public struct OSATBezierAnnotation: OSATAnnotationProtocol {
    let bezierPath: UIBezierPath
    let position: CGPoint
    let lineWidth: CGFloat
    let timeRange: CMTimeRange
    let strokeColor: UIColor?
    let fillColor: UIColor?
    
    public init(bezierPath: UIBezierPath, position: CGPoint, lineWidth: CGFloat, timeRange: CMTimeRange, strokeColor: UIColor?, fillColor: UIColor?) {
        self.bezierPath = bezierPath
        self.position = position
        self.lineWidth = lineWidth
        self.timeRange = timeRange
        self.strokeColor = strokeColor
        self.fillColor = fillColor
    }
    
    public func getAnnotationLayer() -> CALayer {
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = bezierPath.cgPath
        shapeLayer.position = position
        shapeLayer.lineWidth = lineWidth
        shapeLayer.strokeColor = strokeColor?.cgColor ?? UIColor.black.cgColor
        shapeLayer.fillColor = strokeColor?.cgColor ?? UIColor.clear.cgColor
        return shapeLayer
    }
}
