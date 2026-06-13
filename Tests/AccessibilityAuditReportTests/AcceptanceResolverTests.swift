import AccessibilityAuditReport
import CoreGraphics
import XCTest

final class AcceptanceResolverTests: XCTestCase {
    private func issue(
        auditType: String = "Label in Name",
        identifier: String = "saveButton",
        label: String = "Save",
        compact: String = "Mismatch"
    ) -> Issue {
        Issue(
            auditType: auditType,
            compactDescription: compact,
            detailedDescription: "…",
            elementIdentifier: identifier,
            elementLabel: label,
            elementFrame: nil
        )
    }

    func testMatchesByElementIdentity() {
        let rule = AcceptanceRule(
            screen: "Home", auditType: "Label in Name",
            elementIdentifier: "saveButton", reason: "OK"
        )
        let resolved = AcceptanceResolver.resolve(
            issues: [issue()], screen: "Home", variant: "Default", rules: [rule]
        )
        XCTAssertEqual(resolved.first?.acceptance?.reason, "OK")
        XCTAssertEqual(resolved.first?.acceptance?.isStale, false)
    }

    func testFallsBackToLabelWhenIdentifierIsPlaceholder() {
        let rule = AcceptanceRule(
            screen: "Home", auditType: "Label in Name",
            elementLabel: "Save", reason: "OK"
        )
        let placeholderIssue = issue(identifier: "No element identifier")
        let resolved = AcceptanceResolver.resolve(
            issues: [placeholderIssue], screen: "Home", variant: "Default", rules: [rule]
        )
        XCTAssertNotNil(resolved.first?.acceptance)
    }

    func testNilVariantMatchesAnyVariant() {
        let rule = AcceptanceRule(
            screen: "Home", variant: nil, auditType: "Label in Name",
            elementIdentifier: "saveButton", reason: "OK"
        )
        let resolved = AcceptanceResolver.resolve(
            issues: [issue()], screen: "Home", variant: "Dark Contrast", rules: [rule]
        )
        XCTAssertNotNil(resolved.first?.acceptance)
    }

    func testSetVariantMustMatch() {
        let rule = AcceptanceRule(
            screen: "Home", variant: "Default", auditType: "Label in Name",
            elementIdentifier: "saveButton", reason: "OK"
        )
        let resolved = AcceptanceResolver.resolve(
            issues: [issue()], screen: "Home", variant: "Dark Contrast", rules: [rule]
        )
        XCTAssertNil(resolved.first?.acceptance)
    }

    func testContextDriftMarksStale() {
        let rule = AcceptanceRule(
            screen: "Home", auditType: "Label in Name",
            elementIdentifier: "saveButton",
            context: "Old description", reason: "OK"
        )
        let resolved = AcceptanceResolver.resolve(
            issues: [issue(compact: "New description")],
            screen: "Home", variant: "Default", rules: [rule]
        )
        XCTAssertEqual(resolved.first?.acceptance?.isStale, true)
    }

    func testNonMatchingRuleLeavesIssueActive() {
        let rule = AcceptanceRule(
            screen: "Other", auditType: "Label in Name",
            elementIdentifier: "saveButton", reason: "OK"
        )
        let resolved = AcceptanceResolver.resolve(
            issues: [issue()], screen: "Home", variant: "Default", rules: [rule]
        )
        XCTAssertNil(resolved.first?.acceptance)
    }
}
