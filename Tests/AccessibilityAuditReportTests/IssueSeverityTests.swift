//
//  IssueSeverityTests.swift
//  AccessibilityAuditReportTests
//
//  Created by Stephen Gurnett on 13/06/2026.
//

import AccessibilityAuditReport
import CoreGraphics
import XCTest

final class IssueSeverityTests: XCTestCase {
    func testIssueDefaultsToErrorSeverityAndNoAcceptance() {
        let issue = Issue(
            auditType: "Target Size",
            compactDescription: "Too small",
            detailedDescription: "…",
            elementIdentifier: "home.editButton",
            elementLabel: "Edit",
            elementFrame: nil
        )

        XCTAssertEqual(issue.severity, .error)
        XCTAssertNil(issue.acceptance)
    }

    func testIssueCanBeConstructedAsWarning() {
        let issue = Issue(
            auditType: "Label Hygiene",
            compactDescription: "All caps",
            detailedDescription: "…",
            elementIdentifier: "id",
            elementLabel: "SAVE",
            elementFrame: nil,
            severity: .warning
        )

        XCTAssertEqual(issue.severity, .warning)
    }

    func testIssueDefaultsReviewerHintsToEmpty() {
        let issue = Issue(
            auditType: "Target Size",
            compactDescription: "Too small",
            detailedDescription: "d",
            elementIdentifier: "save",
            elementLabel: "Save",
            elementFrame: nil
        )

        XCTAssertTrue(issue.reviewerHints.isEmpty)
    }

    func testIssueAcceptanceCopyPreservesReviewerHints() throws {
        let hint = IssueReviewerHint(
            title: "Search source by identifier",
            detail: "Search for accessibility identifier \"save\".",
            automationKey: "source.search.identifier"
        )
        let issue = Issue(
            auditType: "Target Size",
            compactDescription: "Too small",
            detailedDescription: "d",
            elementIdentifier: "save",
            elementLabel: "Save",
            elementFrame: nil,
            reviewerHints: [hint]
        )

        let accepted = issue.with(acceptance: Acceptance(reason: "Reviewed", isStale: false))

        XCTAssertEqual(accepted.reviewerHints, [hint])
    }

    func testWithAcceptanceCopiesAllFieldsAndSetsAcceptance() {
        let base = Issue(
            auditType: "Label in Name",
            compactDescription: "Mismatch",
            detailedDescription: "…",
            elementIdentifier: "saveButton",
            elementLabel: "Save",
            elementFrame: CGRect(x: 1, y: 2, width: 3, height: 4),
            severity: .error
        )

        let accepted = base.with(acceptance: Acceptance(reason: "Reviewed", isStale: true))

        XCTAssertEqual(accepted.acceptance?.reason, "Reviewed")
        XCTAssertEqual(accepted.acceptance?.isStale, true)
        XCTAssertEqual(accepted.auditType, "Label in Name")
        XCTAssertEqual(accepted.elementIdentifier, "saveButton")
        XCTAssertEqual(accepted.elementFrame, CGRect(x: 1, y: 2, width: 3, height: 4))
        XCTAssertEqual(accepted.severity, .error)
    }
}
