//
//  CheckSeverityTests.swift
//  AccessibilityAuditReportTests
//
//  Created by Stephen Gurnett on 13/06/2026.
//

import AccessibilityAuditReport
import CoreGraphics
import XCTest

final class CheckSeverityTests: XCTestCase {
    func testGenericLabelIssuesAreWarnings() throws {
        let issues = SupplementalAccessibilityChecks.genericLabelIssues(
            interactiveElements: [
                AuditedElement(identifier: "id", label: "Button", frame: .zero)
            ]
        )
        let issue = try XCTUnwrap(issues.first)
        XCTAssertEqual(issue.severity, .warning)
    }

    func testLabelHygieneIssuesAreWarnings() throws {
        let issues = SupplementalAccessibilityChecks.labelHygieneIssues(
            interactiveElements: [
                AuditedElement(identifier: "id", label: "Save button", frame: .zero)
            ]
        )
        let issue = try XCTUnwrap(issues.first)
        XCTAssertEqual(issue.severity, .warning)
    }

    func testDeterministicCheckStaysError() throws {
        let issues = SupplementalAccessibilityChecks.targetSizeIssues(
            interactiveElements: [
                AuditedElement(identifier: "id", label: "Edit", frame: CGRect(x: 0, y: 0, width: 10, height: 10))
            ]
        )
        let issue = try XCTUnwrap(issues.first)
        XCTAssertEqual(issue.severity, .error)
    }

    func testInputPurposeIssuesAreWarnings() throws {
        let issues = SupplementalAccessibilityChecks.inputPurposeIssues(
            textEntryElements: [
                AuditedElement(identifier: "login.email", label: "Email", frame: .zero)
            ]
        )
        let issue = try XCTUnwrap(issues.first)
        XCTAssertEqual(issue.severity, .warning)
    }
}
