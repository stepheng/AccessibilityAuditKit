import AccessibilityAuditReport
import CoreGraphics
import Foundation
import XCTest

final class ReportGatingTests: XCTestCase {
    private func screen(_ issues: [Issue], name: String = "Home", variant: String = "Default") -> ScreenResult {
        ScreenResult(
            variant: variant,
            name: name,
            screenshotPNGData: Data([0]),
            screenshotSize: CGSize(width: 10, height: 10),
            issues: issues
        )
    }

    private func issue(_ severity: Severity, identifier: String = "id", auditType: String = "Target Size") -> Issue {
        Issue(
            auditType: auditType,
            compactDescription: "c",
            detailedDescription: "d",
            elementIdentifier: identifier,
            elementLabel: "L",
            elementFrame: nil,
            severity: severity
        )
    }

    func testCountsPartitionErrorsWarningsAndAccepted() {
        var report = AccessibilityAuditHTMLReport(title: "T")
        report.record(screen([issue(.error, identifier: "a"), issue(.warning, identifier: "b"), issue(.error, identifier: "c")]))
        report.acceptanceRules = [
            AcceptanceRule(screen: "Home", auditType: "Target Size", elementIdentifier: "c", reason: "OK")
        ]

        XCTAssertEqual(report.blockingIssueCount, 1) // a is the only active error (c is accepted)
        XCTAssertEqual(report.warningCount, 1)
        XCTAssertEqual(report.acceptedCount, 1)
        XCTAssertEqual(report.issueCount, 3) // total preserved
    }

    func testStaleAcceptedErrorStillDoesNotBlock() {
        var report = AccessibilityAuditHTMLReport(title: "T")
        report.record(screen([issue(.error, identifier: "a")]))
        report.acceptanceRules = [
            AcceptanceRule(
                screen: "Home", auditType: "Target Size",
                elementIdentifier: "a", context: "old", reason: "OK"
            )
        ]

        XCTAssertEqual(report.blockingIssueCount, 0)
        XCTAssertEqual(report.acceptedCount, 1)
    }

    func testWarningNeverBlocks() {
        var report = AccessibilityAuditHTMLReport(title: "T")
        report.record(screen([issue(.warning)]))

        XCTAssertEqual(report.blockingIssueCount, 0)
        XCTAssertEqual(report.warningCount, 1)
    }
}
