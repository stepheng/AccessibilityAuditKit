//
//  AccessibilityAuditArtifactWriterTests.swift
//  AccessibilityAuditXCTestSupportTests
//
//  Created by Stephen Gurnett on 15/06/2026.
//

import AccessibilityAuditReport
import AccessibilityAuditXCTestSupport
import CoreGraphics
import Foundation
import XCTest

final class AccessibilityAuditArtifactWriterTests: XCTestCase {
    func testWriterEmitsHTMLAndJSONFiles() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("AccessibilityAuditArtifactWriterTests-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: directory) }

        var report = AccessibilityAuditHTMLReport(title: "Capsyl Accessibility Audit")
        report.record(
            ScreenResult(
                name: "Home",
                screenshotPNGData: Data([0]),
                screenshotSize: CGSize(width: 10, height: 10),
                issues: [
                    Issue(
                        auditType: "Label Hygiene",
                        compactDescription: "Accessible label has trailing whitespace",
                        detailedDescription: "Trim the label.",
                        elementIdentifier: "home.save",
                        elementLabel: "Save ",
                        elementFrame: nil,
                        severity: .warning
                    )
                ]
            )
        )

        let urls = try AccessibilityAuditArtifactWriter.write(
            report,
            to: directory,
            baseFilename: "Capsyl Audit"
        )

        XCTAssertTrue(FileManager.default.fileExists(atPath: urls.html.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: urls.json.path))
        XCTAssertEqual(urls.html.lastPathComponent, "Capsyl-Audit.html")
        XCTAssertEqual(urls.json.lastPathComponent, "Capsyl-Audit.json")
        XCTAssertTrue(try String(contentsOf: urls.html).contains("<!doctype html>"))
        XCTAssertTrue(try String(contentsOf: urls.json).contains("\"auditType\" : \"Label Hygiene\""))
    }
}
