//  ReportIntegrationSmokeTest.swift
//  Confirms the public recordAccessibilityAuditScreen → report → issues path
//  still surfaces a known supplemental finding end-to-end (not just the direct
//  scanner calls the deterministic suite uses).
import AccessibilityAuditReport
import AccessibilityAuditXCTestSupport
import XCTest

@MainActor
final class ReportIntegrationSmokeTest: FixturesUITestCase {
    func testReportRecordsTargetSizeIssue() throws {
        guard #available(iOS 17.0, *) else { throw XCTSkip("Requires iOS 17+") }
        launch(fixture: "targetSize")
        var report = AccessibilityAuditHTMLReport(title: "Smoke")
        // `.textClipped` is a benign audit on this all-button screen; the
        // supplemental `.targetSize` check produces the finding we assert.
        try app.recordAccessibilityAuditScreen(
            "Target Size", auditTypes: .textClipped, supplementalChecks: .targetSize, in: &report)
        let issues = report.screens.last?.issues ?? []
        XCTAssertTrue(issues.contains { $0.auditType == "Target Size (Minimum)"
            && $0.elementIdentifier == "targetSize.min20" },
            "Report should surface the 20pt target-size error. Issues=\(issues.map(\.auditType))")
        // Sanity: the rendered HTML is non-empty.
        XCTAssertFalse(report.renderHTML().isEmpty)
    }
}
