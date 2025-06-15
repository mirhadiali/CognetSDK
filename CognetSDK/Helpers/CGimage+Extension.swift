//
//  CGimage+Extension.swift
//  CaptureFace
//
//  Created by Hadi Ali on 25/04/2025.
//

import CoreGraphics

extension CGImage {
    func averageLuminance() -> CGFloat {
        let width = 1
        let height = 1
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        var pixelData = [UInt8](repeating: 0, count: bytesPerRow)
        
        guard let context = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        ) else { return 0 }
        
        context.draw(self, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        let r = CGFloat(pixelData[0])
        let g = CGFloat(pixelData[1])
        let b = CGFloat(pixelData[2])
        
        return (0.299 * r + 0.587 * g + 0.114 * b) / 255.0
    }
}
