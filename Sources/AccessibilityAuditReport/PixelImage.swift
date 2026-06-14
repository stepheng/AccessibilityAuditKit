//
//  PixelImage.swift
//  AccessibilityAuditReport
//
//  Created by Stephen Gurnett on 14/06/2026.
//

import CoreGraphics
import Foundation
import ImageIO

/// A decoded RGBA8 bitmap — row-major, 4 bytes per pixel, top-left origin. The
/// package's first pixel abstraction: it isolates CoreGraphics decoding behind a
/// plain buffer so pixel-based checks (Non-text Contrast, WCAG 1.4.11) can be
/// unit-tested with synthetic bitmaps and no screenshot.
public struct PixelImage {
    public let width: Int
    public let height: Int
    /// Row-major RGBA, 4 bytes per pixel (`[r, g, b, a, r, g, b, a, …]`).
    public let pixels: [UInt8]

    public init(width: Int, height: Int, pixels: [UInt8]) {
        precondition(
            pixels.count == width * height * 4,
            "pixels must contain width * height * 4 RGBA bytes"
        )
        self.width = width
        self.height = height
        self.pixels = pixels
    }

    /// Decodes PNG data into an RGBA8 buffer. Returns nil when the data is not a
    /// decodable image. Screenshots are opaque, so alpha is preserved but
    /// ignored by the contrast math.
    public init?(pngData: Data) {
        guard let source = CGImageSourceCreateWithData(pngData as CFData, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            return nil
        }
        let width = cgImage.width
        let height = cgImage.height
        guard width > 0, height > 0 else { return nil }

        let bytesPerRow = width * 4
        var buffer = [UInt8](repeating: 0, count: height * bytesPerRow)
        guard let context = CGContext(
            data: &buffer,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        self.width = width
        self.height = height
        self.pixels = buffer
    }

    /// WCAG relative luminance (0…1) of the pixel at (x, y), top-left origin.
    public func relativeLuminance(x: Int, y: Int) -> Double {
        let offset = (y * width + x) * 4
        let r = Self.linearised(pixels[offset])
        let g = Self.linearised(pixels[offset + 1])
        let b = Self.linearised(pixels[offset + 2])
        return 0.2126 * r + 0.7152 * g + 0.0722 * b
    }

    /// WCAG contrast ratio (1…21) between two relative luminances.
    public static func contrastRatio(_ first: Double, _ second: Double) -> Double {
        let lighter = max(first, second)
        let darker = min(first, second)
        return (lighter + 0.05) / (darker + 0.05)
    }

    /// Linearises an 8-bit sRGB channel to its 0…1 light value.
    private static func linearised(_ channel: UInt8) -> Double {
        let c = Double(channel) / 255.0
        return c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
    }
}
