//
//  AccessibilityAuditReportFailureTests.swift
//  AccessibilityAuditReport
//
//  Created by Stephen Gurnett on 12/06/2026.
//

import AccessibilityAuditReport
import CoreGraphics
import Foundation
import XCTest

final class AccessibilityAuditReportFailureTests: XCTestCase {
    func testRecordReadinessFailureAddsScreenshotAndIssue() {
        var report = AccessibilityAuditHTMLReport(title: "Capsyl Accessibility Audit")

        report.recordReadinessFailure(
            for: "Memories",
            variant: "AX XXXL",
            screenshotPNGData: Data([1, 2, 3]),
            screenshotSize: CGSize(width: 300, height: 600)
        )

        XCTAssertEqual(report.issueCount, 1)
        XCTAssertEqual(report.screens.first?.variant, "AX XXXL")
        XCTAssertEqual(report.screens.first?.name, "Memories")
        XCTAssertEqual(report.screens.first?.screenshotPNGData, Data([1, 2, 3]))
        XCTAssertEqual(report.screens.first?.screenshotSize, CGSize(width: 300, height: 600))
        XCTAssertEqual(report.screens.first?.issues.first?.auditType, "Readiness Failure")
        XCTAssertEqual(
            report.screens.first?.issues.first?.compactDescription,
            "Memories did not finish rendering before the audit timeout."
        )
    }

    func testRecordNavigationFailureAddsReason() {
        var report = AccessibilityAuditHTMLReport(title: "Capsyl Accessibility Audit")

        report.recordNavigationFailure(
            for: "Photos - Locations",
            variant: "Default",
            reason: "An authentication web view appeared.",
            screenshotPNGData: Data([4, 5, 6]),
            screenshotSize: CGSize(width: 300, height: 600)
        )

        XCTAssertEqual(report.issueCount, 1)
        XCTAssertEqual(report.screens.first?.name, "Photos - Locations")
        XCTAssertEqual(report.screens.first?.issues.first?.auditType, "Navigation Failure")
        XCTAssertEqual(report.screens.first?.issues.first?.compactDescription, "An authentication web view appeared.")
        XCTAssertEqual(
            report.screens.first?.issues.first?.detailedDescription,
            "The automated audit skipped this screen because the visible UI did not match the expected app screen."
        )
    }
}
