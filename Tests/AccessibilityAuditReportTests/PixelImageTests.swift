//
//  PixelImageTests.swift
//  AccessibilityAuditReportTests
//
//  Created by Stephen Gurnett on 14/06/2026.
//

import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers
import XCTest
import AccessibilityAuditReport

private enum PNGHelperError: Error { case failed }

/// Encodes raw RGBA bytes to PNG data so the decoder can be round-tripped.
private func makePNGData(width: Int, height: Int, rgba: [UInt8]) throws -> Data {
    var bytes = rgba
    guard let context = CGContext(
        data: &bytes,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: width * 4,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ), let cgImage = context.makeImage() else {
        throw PNGHelperError.failed
    }
    let data = NSMutableData()
    guard let destination = CGImageDestinationCreateWithData(
        data as CFMutableData, UTType.png.identifier as CFString, 1, nil
    ) else {
        throw PNGHelperError.failed
    }
    CGImageDestinationAddImage(destination, cgImage, nil)
    guard CGImageDestinationFinalize(destination) else { throw PNGHelperError.failed }
    return data as Data
}

final class PixelImageTests: XCTestCase {
    func testRelativeLuminanceOfBlackAndWhite() {
        let image = PixelImage(
            width: 2, height: 1,
            pixels: [0, 0, 0, 255, 255, 255, 255, 255]
        )
        XCTAssertEqual(image.relativeLuminance(x: 0, y: 0), 0, accuracy: 0.0001)
        XCTAssertEqual(image.relativeLuminance(x: 1, y: 0), 1, accuracy: 0.0001)
    }

    func testRelativeLuminanceOfMidGrey() {
        let image = PixelImage(width: 1, height: 1, pixels: [128, 128, 128, 255])
        XCTAssertEqual(image.relativeLuminance(x: 0, y: 0), 0.2158, accuracy: 0.001)
    }

    func testContrastRatioBlackOnWhiteIsTwentyOne() {
        XCTAssertEqual(PixelImage.contrastRatio(0, 1), 21, accuracy: 0.0001)
    }

    func testPNGRoundTripPreservesDimensionsAndChannels() throws {
        // Red left, blue right: horizontal layout is invariant to any vertical
        // flip in decoding, so this pins channel order and addressing without
        // asserting orientation.
        let pngData = try makePNGData(
            width: 2, height: 1,
            rgba: [255, 0, 0, 255, 0, 0, 255, 255]
        )
        let image = try XCTUnwrap(PixelImage(pngData: pngData))
        XCTAssertEqual(image.width, 2)
        XCTAssertEqual(image.height, 1)
        XCTAssertEqual(image.pixels[0], 255) // left R
        XCTAssertEqual(image.pixels[1], 0)   // left G
        XCTAssertEqual(image.pixels[2], 0)   // left B
        XCTAssertEqual(image.pixels[4], 0)   // right R
        XCTAssertEqual(image.pixels[5], 0)   // right G
        XCTAssertEqual(image.pixels[6], 255) // right B
        // Close the decode→luminance loop: verify the public API sees the right
        // colour values after decoding through CGContext.
        XCTAssertEqual(image.relativeLuminance(x: 0, y: 0), 0.2126, accuracy: 0.001) // red
        XCTAssertEqual(image.relativeLuminance(x: 1, y: 0), 0.0722, accuracy: 0.001) // blue
    }

    func testInitFromInvalidPNGDataReturnsNil() {
        XCTAssertNil(PixelImage(pngData: Data([0x00, 0x01, 0x02])))
    }
}
