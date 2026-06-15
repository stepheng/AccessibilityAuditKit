//
//  ReportRenderingTests.swift
//  AccessibilityAuditReportTests
//
//  Created by Stephen Gurnett on 14/06/2026.
//

import AccessibilityAuditReport
import CoreGraphics
import Foundation
import XCTest

final class ReportRenderingTests: XCTestCase {
    func testLocatorHintsUseIdentifierAndLabelWhenAvailable() {
        let hints = IssueReviewerHints.elementLocatorHints(
            identifier: "home.search",
            label: "Search",
            auditType: "Target Size"
        )

        XCTAssertTrue(hints.contains { $0.automationKey == "source.search.identifier" && $0.detail.contains("home.search") })
        XCTAssertTrue(hints.contains { $0.automationKey == "source.search.label" && $0.detail.contains("Search") })
    }

    func testLocatorHintsSkipPlaceholderValues() {
        let hints = IssueReviewerHints.elementLocatorHints(
            identifier: "No element identifier",
            label: "No element label",
            auditType: "Screen Title"
        )

        XCTAssertFalse(hints.contains { $0.automationKey == "source.search.identifier" })
        XCTAssertFalse(hints.contains { $0.automationKey == "source.search.label" })
    }

    func testHeaderShowsSeverityCounts() {
        var report = AccessibilityAuditHTMLReport(title: "T")
        report.record(
            ScreenResult(
                variant: "Default", name: "Home",
                screenshotPNGData: Data([0]), screenshotSize: CGSize(width: 10, height: 10),
                issues: [
                    Issue(auditType: "Target Size", compactDescription: "c", detailedDescription: "d",
                          elementIdentifier: "a", elementLabel: "L", elementFrame: nil, severity: .error),
                    Issue(auditType: "Label Hygiene", compactDescription: "c", detailedDescription: "d",
                          elementIdentifier: "b", elementLabel: "L", elementFrame: nil, severity: .warning)
                ]
            )
        )

        let html = report.renderHTML()

        XCTAssertTrue(html.contains("<dt>Blocking errors</dt><dd>1</dd>"))
        XCTAssertTrue(html.contains("<dt>Warnings</dt><dd>1</dd>"))
        XCTAssertTrue(html.contains("<dt>Accepted</dt><dd>0</dd>"))
    }

    func testAcceptedIssueShowsReasonAndIsNotBlocking() {
        var report = AccessibilityAuditHTMLReport(title: "T")
        report.record(
            ScreenResult(
                variant: "Default", name: "Home",
                screenshotPNGData: Data([0]), screenshotSize: CGSize(width: 10, height: 10),
                issues: [
                    Issue(auditType: "Label in Name", compactDescription: "Mismatch", detailedDescription: "d",
                          elementIdentifier: "saveButton", elementLabel: "Save", elementFrame: nil)
                ]
            )
        )
        report.acceptanceRules = [
            AcceptanceRule(screen: "Home", auditType: "Label in Name",
                           elementIdentifier: "saveButton", reason: "Decorative OK")
        ]

        let html = report.renderHTML()

        XCTAssertTrue(html.contains("Decorative OK"))
        XCTAssertTrue(html.contains("accepted"))
    }

    func testStaleAcceptanceShowsReReviewBadge() {
        var report = AccessibilityAuditHTMLReport(title: "T")
        report.record(
            ScreenResult(
                variant: "Default", name: "Home",
                screenshotPNGData: Data([0]), screenshotSize: CGSize(width: 10, height: 10),
                issues: [
                    Issue(auditType: "Label in Name", compactDescription: "New", detailedDescription: "d",
                          elementIdentifier: "saveButton", elementLabel: "Save", elementFrame: nil)
                ]
            )
        )
        report.acceptanceRules = [
            AcceptanceRule(screen: "Home", auditType: "Label in Name",
                           elementIdentifier: "saveButton", context: "Old", reason: "OK")
        ]

        let html = report.renderHTML()

        XCTAssertTrue(html.contains("re-review"))
    }

    func testExistingTotalSummaryStillRenders() {
        var report = AccessibilityAuditHTMLReport(title: "T")
        report.record(
            ScreenResult(
                variant: "Default", name: "Home",
                screenshotPNGData: Data([0]), screenshotSize: CGSize(width: 10, height: 10),
                issues: [
                    Issue(auditType: "Target Size", compactDescription: "c", detailedDescription: "d",
                          elementIdentifier: "a", elementLabel: "L", elementFrame: nil)
                ]
            )
        )

        let html = report.renderHTML()
        XCTAssertTrue(html.contains("<dt>Issues found</dt><dd>1</dd>"))
    }
}
