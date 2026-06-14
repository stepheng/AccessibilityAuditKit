import AccessibilityAuditReport
import CoreGraphics
import Foundation
import XCTest

final class PlainTextRenderingTests: XCTestCase {
    private func screen(name: String, issues: [Issue]) -> ScreenResult {
        ScreenResult(
            variant: "Default", name: name,
            screenshotPNGData: Data([0]), screenshotSize: CGSize(width: 10, height: 10),
            issues: issues
        )
    }

    func testSummaryLineShowsSeverityCounts() {
        var report = AccessibilityAuditHTMLReport(title: "In-Process Accessibility Audit")
        report.record(
            screen(name: "Home", issues: [
                Issue(auditType: "Target Size", compactDescription: "c", detailedDescription: "d",
                      elementIdentifier: "a", elementLabel: "L", elementFrame: nil, severity: .error),
                Issue(auditType: "Label Hygiene", compactDescription: "c", detailedDescription: "d",
                      elementIdentifier: "b", elementLabel: "L", elementFrame: nil, severity: .warning)
            ])
        )

        let text = report.renderPlainText()

        XCTAssertTrue(text.contains("In-Process Accessibility Audit"))
        XCTAssertTrue(text.contains("Screens audited: 1"))
        XCTAssertTrue(text.contains("Issues: 2"))
        XCTAssertTrue(text.contains("Blocking errors: 1"))
        XCTAssertTrue(text.contains("Warnings: 1"))
        XCTAssertTrue(text.contains("Accepted: 0"))
    }

    func testIssueShowsTypeDescriptionAndElement() {
        var report = AccessibilityAuditHTMLReport(title: "T")
        report.record(
            screen(name: "Memories", issues: [
                Issue(auditType: "Target Size (Minimum)", compactDescription: "18x18pt below 24x24pt",
                      detailedDescription: "Interactive element is too small to hit reliably.",
                      elementIdentifier: "closeButton", elementLabel: "Close",
                      elementFrame: CGRect(x: 1, y: 2, width: 18, height: 18), severity: .error)
            ])
        )

        let text = report.renderPlainText()

        XCTAssertTrue(text.contains("Memories"))
        XCTAssertTrue(text.contains("Target Size (Minimum): 18x18pt below 24x24pt"))
        XCTAssertTrue(text.contains("ERROR"))
        XCTAssertTrue(text.contains("closeButton"))
        XCTAssertTrue(text.contains("Close"))
        XCTAssertTrue(text.contains("Interactive element is too small to hit reliably."))
        XCTAssertTrue(text.contains("width: 18.00"))
    }

    func testWarningIssueIsMarkedAsWarning() {
        var report = AccessibilityAuditHTMLReport(title: "T")
        report.record(
            screen(name: "Home", issues: [
                Issue(auditType: "Label Hygiene", compactDescription: "redundant role suffix",
                      detailedDescription: "d", elementIdentifier: "save", elementLabel: "Save button",
                      elementFrame: nil, severity: .warning)
            ])
        )

        let text = report.renderPlainText()

        XCTAssertTrue(text.contains("WARN"))
        XCTAssertTrue(text.contains("Label Hygiene: redundant role suffix"))
    }

    func testAcceptedIssueShowsReasonAndIsNotBlocking() {
        var report = AccessibilityAuditHTMLReport(title: "T")
        report.record(
            screen(name: "Home", issues: [
                Issue(auditType: "Label in Name", compactDescription: "Mismatch", detailedDescription: "d",
                      elementIdentifier: "saveButton", elementLabel: "Save", elementFrame: nil)
            ])
        )
        report.acceptanceRules = [
            AcceptanceRule(screen: "Home", auditType: "Label in Name",
                           elementIdentifier: "saveButton", reason: "Decorative OK")
        ]

        let text = report.renderPlainText()

        XCTAssertTrue(text.contains("ACCEPTED"))
        XCTAssertTrue(text.contains("Decorative OK"))
        XCTAssertTrue(text.contains("Blocking errors: 0"))
        XCTAssertTrue(text.contains("Accepted: 1"))
    }

    func testStaleAcceptanceShowsReReviewNote() {
        var report = AccessibilityAuditHTMLReport(title: "T")
        report.record(
            screen(name: "Home", issues: [
                Issue(auditType: "Label in Name", compactDescription: "New", detailedDescription: "d",
                      elementIdentifier: "saveButton", elementLabel: "Save", elementFrame: nil)
            ])
        )
        report.acceptanceRules = [
            AcceptanceRule(screen: "Home", auditType: "Label in Name",
                           elementIdentifier: "saveButton", context: "Old", reason: "OK")
        ]

        let text = report.renderPlainText()

        XCTAssertTrue(text.contains("re-review"))
    }

    func testCleanScreenReportsNoIssues() {
        var report = AccessibilityAuditHTMLReport(title: "T")
        report.record(screen(name: "Photos", issues: []))

        let text = report.renderPlainText()

        XCTAssertTrue(text.contains("Photos"))
        XCTAssertTrue(text.contains("No issues found"))
    }

    func testManualChecklistIncludesBaseAndAdditionalItems() {
        var report = AccessibilityAuditHTMLReport(title: "T")
        report.record(screen(name: "Home", issues: []))
        report.additionalManualChecks = ["Use Accessibility Inspector for contrast."]

        let text = report.renderPlainText()

        XCTAssertTrue(text.contains("Manual follow-up checks"))
        XCTAssertTrue(text.contains("VoiceOver focus order"))
        XCTAssertTrue(text.contains("Use Accessibility Inspector for contrast."))
    }

    func testPlainTextIncludesReviewerHintsWithAutomationKeys() {
        var report = AccessibilityAuditHTMLReport(title: "T")
        report.record(
            screen(name: "Home", issues: [
                Issue(
                    auditType: "Target Size",
                    compactDescription: "c",
                    detailedDescription: "d",
                    elementIdentifier: "home.search",
                    elementLabel: "Search",
                    elementFrame: nil,
                    reviewerHints: [
                        IssueReviewerHint(
                            title: "Search source by identifier",
                            detail: "Search for accessibility identifier \"home.search\".",
                            automationKey: "source.search.identifier"
                        ),
                        IssueReviewerHint(
                            title: "Inspect owning component",
                            detail: "Inspect the shared button style.",
                            automationKey: nil
                        )
                    ]
                )
            ])
        )

        let text = report.renderPlainText()

        XCTAssertTrue(text.contains("hint[source.search.identifier]: Search source by identifier - Search for accessibility identifier \"home.search\"."))
        XCTAssertTrue(text.contains("hint: Inspect owning component - Inspect the shared button style."))
    }

    func testErrorsAreListedBeforeWarningsAndAccepted() throws {
        var report = AccessibilityAuditHTMLReport(title: "T")
        report.record(
            screen(name: "Home", issues: [
                Issue(auditType: "Label Hygiene", compactDescription: "warn", detailedDescription: "d",
                      elementIdentifier: "w", elementLabel: "W", elementFrame: nil, severity: .warning),
                Issue(auditType: "Target Size", compactDescription: "err", detailedDescription: "d",
                      elementIdentifier: "e", elementLabel: "E", elementFrame: nil, severity: .error)
            ])
        )

        let text = report.renderPlainText()
        let errorIndex = try XCTUnwrap(text.range(of: "Target Size: err")).lowerBound
        let warningIndex = try XCTUnwrap(text.range(of: "Label Hygiene: warn")).lowerBound
        XCTAssertTrue(errorIndex < warningIndex, "Errors should be listed before warnings")
    }
}
