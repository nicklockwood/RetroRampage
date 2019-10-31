//
//  NSImage+Bitmap.swift
//  RampageMac
//
//  Created by Nick Lockwood on 29/10/2019.
//  Copyright © 2019 Nick Lockwood. All rights reserved.
//

import Cocoa
import Engine
import Renderer

extension NSImage {
    convenience init?(bitmap: Bitmap) {
        let alphaInfo = CGImageAlphaInfo.premultipliedLast
        let bytesPerPixel = MemoryLayout<Color>.size
        let bytesPerRow = bitmap.height * bytesPerPixel

        guard let providerRef = CGDataProvider(data: Data(
            bytes: bitmap.pixels, count: bitmap.width * bytesPerRow
        ) as CFData) else {
            return nil
        }

        guard let cgImage = CGImage(
            width: bitmap.height,
            height: bitmap.width,
            bitsPerComponent: 8,
            bitsPerPixel: bytesPerPixel * 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGBitmapInfo(rawValue: alphaInfo.rawValue),
            provider: providerRef,
            decode: nil,
            shouldInterpolate: true,
            intent: .defaultIntent
        ) else {
            return nil
        }

        let rotatedSize = NSSize(width: bitmap.height, height: bitmap.width)
        let rotatedImage = NSImage(cgImage: cgImage, size: rotatedSize)
        let transform = NSAffineTransform()
        transform.rotate(byDegrees: 90)
        transform.scaleX(by: -1, yBy: 1)
        transform.translateX(by: -rotatedSize.width, yBy: -rotatedSize.height)
        self.init(size: NSSize(width: bitmap.width, height: bitmap.height))
        self.lockFocus()
        transform.concat()
        rotatedImage.draw(in: NSRect(origin: .zero, size: rotatedSize))
        self.unlockFocus()
    }
}

extension Bitmap {
    init?(image: NSImage) {
        var rect = NSRect(
            x: 0,
            y: 0,
            width: Int(image.size.width),
            height: Int(image.size.height)
        )
        guard let cgImage = image.cgImage(forProposedRect: &rect, context: nil, hints: nil) else {
            return nil
        }

        let alphaInfo = CGImageAlphaInfo.premultipliedLast
        let bytesPerPixel = MemoryLayout<Color>.size
        let bytesPerRow = cgImage.height * bytesPerPixel

        var pixels = [Color](repeating: .clear, count: cgImage.width * cgImage.height)
        guard let context = CGContext(
            data: &pixels,
            width: cgImage.height,
            height: cgImage.width,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: alphaInfo.rawValue
        ) else {
            return nil
        }

        context.translateBy(x: rect.size.height, y: rect.size.width)
        context.rotate(by: .pi/2)
        context.scaleBy(x: -1, y: 1)
        context.draw(cgImage, in: NSRectToCGRect(rect))
        self.init(height: cgImage.height, pixels: pixels)
    }
}

