//
//  AccessibilityAuditHTMLReportTests.swift
//  AccessibilityAuditReport
//
//  Created by Stephen Gurnett on 12/06/2026.
//

import AccessibilityAuditReport
import CoreGraphics
import Foundation
import XCTest

final class AccessibilityAuditHTMLReportTests: XCTestCase {
    func testRenderEscapesIssueTextAndAnnotatesScreenshotFrame() throws {
        var report = AccessibilityAuditHTMLReport(title: "Capsyl <Audit>")
        report.record(
            ScreenResult(
                name: "Home & Files",
                screenshotPNGData: Data([0, 1, 2, 3]),
                screenshotSize: CGSize(width: 200, height: 100),
                issues: [
                    Issue(
                        auditType: "Trait <Check>",
                        compactDescription: "Button & image",
                        detailedDescription: "Expected \"button\" trait.",
                        elementIdentifier: "files.row.audio",
                        elementLabel: "Audio <6 items>",
                        elementFrame: CGRect(x: 20, y: 10, width: 40, height: 30)
                    )
                ]
            )
        )

        let html = report.renderHTML()

        XCTAssertTrue(html.contains("Capsyl &lt;Audit&gt;"))
        XCTAssertTrue(html.contains("Home &amp; Files"))
        XCTAssertTrue(html.contains("Trait &lt;Check&gt;"))
        XCTAssertTrue(html.contains("Button &amp; image"))
        XCTAssertTrue(html.contains("Expected &quot;button&quot; trait."))
        XCTAssertTrue(html.contains("Audio &lt;6 items&gt;"))
        XCTAssertTrue(html.contains("data:image/png;base64,AAECAw=="))
        XCTAssertTrue(html.contains("left:10.00%;top:10.00%;width:20.00%;height:30.00%"))
    }

    func testRenderSummarizesPassingAndFailingScreens() throws {
        var report = AccessibilityAuditHTMLReport(title: "Capsyl Accessibility Audit")
        report.record(
            ScreenResult(
                variant: "Default",
                name: "Home",
                screenshotPNGData: Data([0]),
                screenshotSize: CGSize(width: 10, height: 10),
                issues: []
            )
        )
        report.record(
            ScreenResult(
                variant: "Dark Contrast",
                name: "Files",
                screenshotPNGData: Data([1]),
                screenshotSize: CGSize(width: 10, height: 10),
                issues: [
                    Issue(
                        auditType: "Hit Region",
                        compactDescription: "Small target",
                        detailedDescription: "The tappable area is too small.",
                        elementIdentifier: "files.row.audio",
                        elementLabel: "Audio",
                        elementFrame: nil
                    )
                ]
            )
        )

        let html = report.renderHTML()

        XCTAssertEqual(report.issueCount, 1)
        XCTAssertTrue(html.contains("<dt>Screens audited</dt><dd>2</dd>"))
        XCTAssertTrue(html.contains("<dt>Issues found</dt><dd>1</dd>"))
        XCTAssertTrue(html.contains("No issues found for this screen."))
        XCTAssertTrue(html.contains("Files"))
        XCTAssertTrue(html.contains("Small target"))
        XCTAssertTrue(html.contains("<dt>Default</dt><dd>0 issue(s), 1 screen(s)</dd>"))
        XCTAssertTrue(html.contains("<dt>Dark Contrast</dt><dd>1 issue(s), 1 screen(s)</dd>"))
    }

    func testRenderLinksIssueRowsToScreenshotFramesAndFullSizeScreenshot() throws {
        var report = AccessibilityAuditHTMLReport(title: "Capsyl Accessibility Audit")
        report.record(
            ScreenResult(
                variant: "AX XXXL",
                name: "Files",
                screenshotPNGData: Data([0, 1, 2, 3]),
                screenshotSize: CGSize(width: 200, height: 100),
                issues: [
                    Issue(
                        auditType: "Text Clipped",
                        compactDescription: "Label clipped",
                        detailedDescription: "Text is clipped at larger Dynamic Type.",
                        elementIdentifier: "files.row.documents",
                        elementLabel: "Documents",
                        elementFrame: CGRect(x: 20, y: 10, width: 40, height: 30)
                    )
                ]
            )
        )

        let html = report.renderHTML()

        XCTAssertTrue(html.contains("class=\"screen-layout\""))
        XCTAssertTrue(html.contains("class=\"issue-list\""))
        XCTAssertTrue(html.contains("class=\"screenshot-panel\""))
        XCTAssertTrue(html.contains("<a class=\"screenshot-link\" href=\"data:image/png;base64,AAECAw==\""))
        XCTAssertTrue(html.contains("class=\"issue-card\" tabindex=\"0\" data-issue-id=\"screen-0-issue-0\""))
        XCTAssertTrue(html.contains("class=\"issue-frame\" data-issue-id=\"screen-0-issue-0\""))
        XCTAssertTrue(
            html.contains(
                ".screen-layout:has(.issue-card[data-issue-id=\"screen-0-issue-0\"]:hover) .issue-frame[data-issue-id=\"screen-0-issue-0\"]"
            )
        )
        XCTAssertTrue(html.contains("max-height: 70vh"))
        XCTAssertTrue(html.contains("display: inline-block;"))
        XCTAssertTrue(html.contains("line-height: 0;"))
        XCTAssertFalse(html.contains(".screenshot {\n  display: block;"))
    }

    func testConsistentIdentificationCheckRecordsIssuesFromInventories() throws {
        var report = AccessibilityAuditHTMLReport(title: "Capsyl Accessibility Audit")
        report.recordElementInventory(
            screenName: "Home",
            elements: [
                AuditedElement(
                    identifier: "tab.photos",
                    label: "Photos",
                    frame: CGRect(x: 0, y: 0, width: 44, height: 44)
                )
            ]
        )
        report.recordElementInventory(
            screenName: "Files",
            elements: [
                AuditedElement(
                    identifier: "tab.photos",
                    label: "Pictures",
                    frame: CGRect(x: 0, y: 0, width: 44, height: 44)
                )
            ]
        )

        report.recordConsistentIdentificationCheck(
            screenshotPNGData: Data([0]),
            screenshotSize: CGSize(width: 10, height: 10)
        )

        XCTAssertEqual(report.issueCount, 1)
        let screen = try XCTUnwrap(report.screens.last)
        XCTAssertEqual(screen.name, "Consistent Identification")
        XCTAssertEqual(screen.issues.first?.auditType, "Consistent Identification")
    }

    func testConsistentIdentificationCheckRecordsPassingScreenWhenLabelsAgree() throws {
        var report = AccessibilityAuditHTMLReport(title: "Capsyl Accessibility Audit")
        report.recordElementInventory(
            screenName: "Home",
            elements: [
                AuditedElement(
                    identifier: "tab.photos",
                    label: "Photos",
                    frame: CGRect(x: 0, y: 0, width: 44, height: 44)
                )
            ]
        )

        report.recordConsistentIdentificationCheck(
            screenshotPNGData: Data([0]),
            screenshotSize: CGSize(width: 10, height: 10)
        )

        XCTAssertEqual(report.issueCount, 0)
        XCTAssertEqual(report.screens.last?.name, "Consistent Identification")
    }

    func testRenderIncludesManualFollowUpChecklist() throws {
        let report = AccessibilityAuditHTMLReport(title: "Capsyl Accessibility Audit")

        let html = report.renderHTML()

        XCTAssertTrue(html.contains("Manual follow-up checks"))
        XCTAssertTrue(html.contains("VoiceOver focus order"))
        XCTAssertTrue(html.contains("Full Keyboard Access"))
        XCTAssertTrue(html.contains("Switch Control"))
    }

    func testAdditionalManualChecksAppearInChecklist() {
        var report = AccessibilityAuditHTMLReport(title: "T")
        report.additionalManualChecks = ["Run Accessibility Inspector for Contrast."]
        let html = report.renderHTML()
        XCTAssertTrue(html.contains("Run Accessibility Inspector for Contrast."))
        XCTAssertTrue(html.contains("VoiceOver focus order follows the visual and task flow."))
    }

    func testManualChecklistDefaultsToBaseItemsOnlyWithNoEmptyItem() {
        let report = AccessibilityAuditHTMLReport(title: "T")
        let html = report.renderHTML()
        XCTAssertTrue(html.contains("Custom grouped content exposes the right accessibility children."))
        XCTAssertFalse(html.contains("<li></li>"))
    }
}
