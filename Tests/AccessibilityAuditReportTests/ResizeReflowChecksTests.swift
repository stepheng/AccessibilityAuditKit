//
//  ResizeReflowChecksTests.swift
//  AccessibilityAuditReportTests
//
//  Created by Stephen Gurnett on 15/06/2026.
//

import AccessibilityAuditReport
import CoreGraphics
import XCTest

final class ResizeReflowChecksTests: XCTestCase {
    func testContentWithinViewportProducesNoIssue() {
        let issues = SupplementalAccessibilityChecks.resizeReflowIssues(
            observations: [
                ResizeReflowObservation(
                    identifier: "resizeReflow.pass",
                    label: "Adaptive summary",
                    variant: "AX XXXL Portrait",
                    frame: CGRect(x: 16, y: 100, width: 320, height: 180),
                    viewportFrame: CGRect(x: 0, y: 0, width: 390, height: 844)
                )
            ]
        )

        XCTAssertTrue(issues.isEmpty)
    }

    func testHorizontalOverflowProducesWarningIssue() throws {
        let issues = SupplementalAccessibilityChecks.resizeReflowIssues(
            observations: [
                ResizeReflowObservation(
                    identifier: "resizeReflow.fail",
                    label: "Fixed width summary",
                    variant: "AX XXXL Portrait",
                    frame: CGRect(x: 16, y: 100, width: 720, height: 44),
                    viewportFrame: CGRect(x: 0, y: 0, width: 390, height: 844)
                )
            ]
        )

        let issue = try XCTUnwrap(issues.first)
        XCTAssertEqual(issue.auditType, "Resize Text / Reflow")
        XCTAssertEqual(issue.elementIdentifier, "resizeReflow.fail")
        XCTAssertEqual(issue.severity, .warning)
    }

    func testExplicitClippedObservationProducesWarningIssue() throws {
        let issues = SupplementalAccessibilityChecks.resizeReflowIssues(
            observations: [
                ResizeReflowObservation(
                    identifier: "resizeReflow.fail",
                    label: "Single-line status",
                    variant: "AX XXXL Landscape",
                    frame: CGRect(x: 16, y: 100, width: 200, height: 24),
                    viewportFrame: CGRect(x: 0, y: 0, width: 844, height: 390),
                    isClipped: true
                )
            ]
        )

        let issue = try XCTUnwrap(issues.first)
        XCTAssertTrue(issue.detailedDescription.contains("AX XXXL Landscape"))
        XCTAssertTrue(issue.detailedDescription.contains("appears clipped"))
    }
}
