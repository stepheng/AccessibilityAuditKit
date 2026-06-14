//
//  NonTextContrastCheckTests.swift
//  AccessibilityAuditReport
//

import CoreGraphics
import Foundation
import XCTest
import AccessibilityAuditReport

/// A solid RGBA buffer of one grey.
private func solidPixels(width: Int, height: Int, grey: UInt8) -> [UInt8] {
    var pixels = [UInt8]()
    pixels.reserveCapacity(width * height * 4)
    for _ in 0..<(width * height) { pixels += [grey, grey, grey, 255] }
    return pixels
}

/// A `background` fill with a `glyph`-grey rectangle painted into `glyphRect`.
private func iconImage(
    width: Int, height: Int, background: UInt8, glyph: UInt8, glyphRect: CGRect
) -> PixelImage {
    var pixels = solidPixels(width: width, height: height, grey: background)
    for y in Int(glyphRect.minY)..<Int(glyphRect.maxY) {
        for x in Int(glyphRect.minX)..<Int(glyphRect.maxX) {
            let offset = (y * width + x) * 4
            pixels[offset] = glyph
            pixels[offset + 1] = glyph
            pixels[offset + 2] = glyph
            pixels[offset + 3] = 255
        }
    }
    return PixelImage(width: width, height: height, pixels: pixels)
}

final class NonTextContrastCheckTests: XCTestCase {
    private let frame = CGRect(x: 0, y: 0, width: 20, height: 20)

    private func element(_ frame: CGRect) -> AuditedElement {
        AuditedElement(identifier: "icon.share", label: "Share", frame: frame)
    }

    func testFlagsLowContrastDuotoneIcon() throws {
        // Grey 118 (luminance ≈ 0.18) glyph on grey 149 (≈ 0.30): ≈ 1.5:1.
        let image = iconImage(
            width: 20, height: 20, background: 149, glyph: 118,
            glyphRect: CGRect(x: 5, y: 5, width: 10, height: 10)
        )
        let issues = SupplementalAccessibilityChecks.nonTextContrastIssues(
            graphicalElements: [element(frame)], image: image
        )
        XCTAssertEqual(issues.count, 1)
        let issue = try XCTUnwrap(issues.first)
        XCTAssertEqual(issue.auditType, "Non-text Contrast")
        XCTAssertEqual(issue.severity, .warning)
        XCTAssertEqual(issue.elementFrame, frame)
        XCTAssertEqual(issue.elementIdentifier, "icon.share")
    }

    func testPassesHighContrastIcon() {
        let image = iconImage(
            width: 20, height: 20, background: 255, glyph: 0,
            glyphRect: CGRect(x: 5, y: 5, width: 10, height: 10)
        )
        let issues = SupplementalAccessibilityChecks.nonTextContrastIssues(
            graphicalElements: [element(frame)], image: image
        )
        XCTAssertTrue(issues.isEmpty)
    }

    func testSkipsUniformRegion() {
        let image = PixelImage(
            width: 20, height: 20, pixels: solidPixels(width: 20, height: 20, grey: 130)
        )
        let issues = SupplementalAccessibilityChecks.nonTextContrastIssues(
            graphicalElements: [element(frame)], image: image
        )
        XCTAssertTrue(issues.isEmpty)
    }

    func testSkipsRegionThatIsNotTwoToned() {
        // Three equal luminance bands (black, mid-grey, white): Otsu
        // separability stays below the gate, so it is skipped, not guessed at.
        let width = 30, height = 12
        let bands: [UInt8] = [0, 188, 255]
        var pixels = [UInt8]()
        for _ in 0..<height {
            for x in 0..<width {
                let v = bands[x / 10]
                pixels += [v, v, v, 255]
            }
        }
        let image = PixelImage(width: width, height: height, pixels: pixels)
        let issues = SupplementalAccessibilityChecks.nonTextContrastIssues(
            graphicalElements: [element(CGRect(x: 0, y: 0, width: width, height: height))],
            image: image
        )
        XCTAssertTrue(issues.isEmpty)
    }

    func testSkipsSpeckBelowClassFraction() {
        // A 1×1 speck on a 20×20 fill is below the minimum class fraction.
        let image = iconImage(
            width: 20, height: 20, background: 149, glyph: 118,
            glyphRect: CGRect(x: 0, y: 0, width: 1, height: 1)
        )
        let issues = SupplementalAccessibilityChecks.nonTextContrastIssues(
            graphicalElements: [element(frame)], image: image
        )
        XCTAssertTrue(issues.isEmpty)
    }

    func testSkipsOffscreenFrame() {
        let image = iconImage(
            width: 20, height: 20, background: 149, glyph: 118,
            glyphRect: CGRect(x: 5, y: 5, width: 10, height: 10)
        )
        let offscreen = element(CGRect(x: -100, y: 0, width: 20, height: 20))
        let issues = SupplementalAccessibilityChecks.nonTextContrastIssues(
            graphicalElements: [offscreen], image: image
        )
        XCTAssertTrue(issues.isEmpty)
    }

    func testMapsPointFrameToPixelsUsingScale() {
        // Image is 40×40 pixels; a 20×20-point frame at scale 2 samples it all.
        let image = iconImage(
            width: 40, height: 40, background: 149, glyph: 118,
            glyphRect: CGRect(x: 10, y: 10, width: 20, height: 20)
        )
        let pointFrame = CGRect(x: 0, y: 0, width: 20, height: 20)
        let issues = SupplementalAccessibilityChecks.nonTextContrastIssues(
            graphicalElements: [element(pointFrame)], image: image, scale: 2
        )
        XCTAssertEqual(issues.count, 1)
        XCTAssertEqual(issues.first?.elementFrame, pointFrame)
    }
}
