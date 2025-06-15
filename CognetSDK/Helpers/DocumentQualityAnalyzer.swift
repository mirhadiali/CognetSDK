//
//  DocumentQualityAnalyzer.swift
//  CaptureFace
//
//  Created by Hadi Ali on 25/04/2025.
//


import Foundation
import Vision
import CoreImage
import CoreImage.CIFilterBuiltins
import CoreGraphics
import CoreVideo

class DocumentQualityAnalyzer {
    
    private let ciContext = CIContext()
    
    /// Determines if the image has sufficient sharpness
    func isImageSharpEnough(pixelBuffer: CVPixelBuffer, threshold: CGFloat = 0.1) -> Bool {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let filter = CIFilter.edges()
        filter.inputImage = ciImage
        guard let outputImage = filter.outputImage else { return true }
        
        let extent = outputImage.extent
        guard let cgImage = ciContext.createCGImage(outputImage, from: extent) else { return true }
        
        let sharpness = cgImage.averageLuminance()
        print("sharpness ", sharpness)
        return sharpness > threshold
    }
    
    /// Detects if the image is too bright (glare)
    func isImageTooBright(pixelBuffer: CVPixelBuffer, brightnessThreshold: CGFloat = 0.9) -> Bool {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let filter = CIFilter.areaMaximum()
        filter.inputImage = ciImage
        filter.extent = ciImage.extent // ✅ Just use CGRect, not CIVector
        
        guard let outputImage = filter.outputImage,
              let cgImage = ciContext.createCGImage(outputImage, from: outputImage.extent) else {
            return false
        }
        
        let brightness = cgImage.averageLuminance()
        print("brightness ", brightness)
        return brightness > brightnessThreshold
    }
    
    func hasTooMuchShadow(pixelBuffer: CVPixelBuffer, shadowThreshold: CGFloat = 0.15) -> Bool {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)

        // Convert to grayscale using CIColorControls
        let grayscaleImage = ciImage.applyingFilter("CIColorControls", parameters: [
            kCIInputSaturationKey: 0.0,  // Remove color
            kCIInputBrightnessKey: 0.0,
            kCIInputContrastKey: 1.1
        ])

        // Downscale for performance
        let scaledImage = grayscaleImage.transformed(by: CGAffineTransform(scaleX: 0.1, y: 0.1))
        let context = CIContext()
        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else {
            return false
        }

        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 1
        let bytesPerRow = width * bytesPerPixel
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: width * height)
        defer { buffer.deallocate() }

        let colorSpace = CGColorSpaceCreateDeviceGray()
        let bitmapInfo = CGImageAlphaInfo.none.rawValue

        guard let bitmapContext = CGContext(data: buffer, width: width, height: height,
                                            bitsPerComponent: 8, bytesPerRow: bytesPerRow,
                                            space: colorSpace, bitmapInfo: bitmapInfo) else {
            return false
        }

        bitmapContext.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        // Analyze luminance
        let pixelCount = width * height
        let luminanceValues = (0..<pixelCount).map { CGFloat(buffer[$0]) / 255.0 }
        let mean = luminanceValues.reduce(0, +) / CGFloat(pixelCount)
        let variance = luminanceValues.reduce(0) { $0 + pow($1 - mean, 2) } / CGFloat(pixelCount)

        return sqrt(variance) > shadowThreshold
    }
    
    func isRectangleSkewed(_ observation: VNRectangleObservation, maxAngleDegrees: CGFloat = 15) -> Bool {
        func angleBetween(_ p1: CGPoint, _ p2: CGPoint) -> CGFloat {
            let deltaY = p2.y - p1.y
            let deltaX = p2.x - p1.x
            return atan2(deltaY, deltaX) * 180 / .pi
        }

        let topAngle = angleBetween(observation.topLeft, observation.topRight)
        let bottomAngle = angleBetween(observation.bottomLeft, observation.bottomRight)
        let leftAngle = angleBetween(observation.topLeft, observation.bottomLeft)
        let rightAngle = angleBetween(observation.topRight, observation.bottomRight)

        return abs(topAngle) > maxAngleDegrees ||
               abs(bottomAngle) > maxAngleDegrees ||
               abs(leftAngle - 90) > maxAngleDegrees ||
               abs(rightAngle - 90) > maxAngleDegrees
    }
}
