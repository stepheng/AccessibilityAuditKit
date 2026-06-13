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
