//
//  NonTextContrastFixtureTests.swift
//  AccessibilityFixturesUITests
//
//  Created by Stephen Gurnett on 15/06/2026.
//

import AccessibilityAuditReport
import AccessibilityAuditXCTestSupport
import XCTest

@MainActor
final class NonTextContrastFixtureTests: FixturesUITestCase {
    func testNonTextContrastFixtureUsesScreenshotBackedAuditPath() throws {
        guard #available(iOS 17.0, *) else { throw XCTSkip("Requires iOS 17+") }

        launch(fixture: "future.nonTextContrast")

        var report = AccessibilityAuditHTMLReport(title: "Non-text Contrast Fixture")
        try app.recordAccessibilityAuditScreen(
            "Non-text Contrast",
            auditTypes: [],
            supplementalChecks: .nonTextContrast,
            in: &report
        )

        let issues = report.screens.flatMap(\.issues)
            .filter { $0.auditType == "Non-text Contrast" }
        let flagged = Set(issues.map(\.elementIdentifier))

        XCTAssertTrue(
            flagged.contains("nonTextContrast.fail"),
            "Expected the low-contrast glyph to be flagged. Flagged=\(flagged)"
        )
        XCTAssertFalse(
            flagged.contains("nonTextContrast.pass"),
            "Expected the high-contrast glyph to stay clean. Flagged=\(flagged)"
        )
        XCTAssertTrue(
            issues.allSatisfy { $0.severity == .warning },
            "Non-text contrast should stay advisory."
        )
    }
}
