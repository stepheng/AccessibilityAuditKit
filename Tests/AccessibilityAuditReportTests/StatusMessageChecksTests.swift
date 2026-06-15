//
//  StatusMessageChecksTests.swift
//  AccessibilityAuditReportTests
//
//  Created by Stephen Gurnett on 15/06/2026.
//

import AccessibilityAuditReport
import CoreGraphics
import XCTest

final class StatusMessageChecksTests: XCTestCase {
    func testMatchingObservedStatusMessageProducesNoIssue() {
        let issues = SupplementalAccessibilityChecks.statusMessageIssues(
            observations: [
                StatusMessageObservation(
                    identifier: "statusMessages.pass",
                    label: "Start upload",
                    expectedMessage: "Upload started",
                    observedMessage: "Upload started",
                    frame: CGRect(x: 0, y: 0, width: 100, height: 44)
                )
            ]
        )

        XCTAssertTrue(issues.isEmpty)
    }

    func testMissingStatusMessageProducesWarningIssue() throws {
        let issues = SupplementalAccessibilityChecks.statusMessageIssues(
            observations: [
                StatusMessageObservation(
                    identifier: "statusMessages.fail",
                    label: "Save draft",
                    expectedMessage: "Draft saved",
                    observedMessage: nil,
                    frame: CGRect(x: 0, y: 0, width: 100, height: 44)
                )
            ]
        )

        let issue = try XCTUnwrap(issues.first)
        XCTAssertEqual(issue.auditType, "Status Messages")
        XCTAssertEqual(issue.elementIdentifier, "statusMessages.fail")
        XCTAssertEqual(issue.severity, .warning)
    }

    func testMismatchedStatusMessageProducesWarningIssue() throws {
        let issues = SupplementalAccessibilityChecks.statusMessageIssues(
            observations: [
                StatusMessageObservation(
                    identifier: "statusMessages.fail",
                    label: "Save draft",
                    expectedMessage: "Draft saved",
                    observedMessage: "Saving",
                    frame: CGRect(x: 0, y: 0, width: 100, height: 44)
                )
            ]
        )

        let issue = try XCTUnwrap(issues.first)
        XCTAssertTrue(issue.detailedDescription.contains("Expected \"Draft saved\""))
        XCTAssertTrue(issue.detailedDescription.contains("observed \"Saving\""))
    }
}
