//
//  StatusMessagesFixtureTests.swift
//  AccessibilityFixtures
//
//  Created by Stephen Gurnett on 15/06/2026.
//

import AccessibilityAuditReport
import XCTest

@MainActor
final class StatusMessagesFixtureTests: FixturesUITestCase {
    func testStatusMessagesFixtureRecordsScriptedAnnouncementObservation() throws {
        guard #available(iOS 17.0, *) else { throw XCTSkip("Requires iOS 17+") }

        launch(fixture: "future.statusMessages")

        let passButton = app.buttons["statusMessages.pass"]
        XCTAssertTrue(passButton.waitForExistence(timeout: 2))
        passButton.tap()

        let failButton = app.buttons["statusMessages.fail"]
        XCTAssertTrue(failButton.waitForExistence(timeout: 2))
        failButton.tap()

        let passObserved = observedStatusMessage(for: "statusMessages.pass.observed")
        let failObserved = observedStatusMessage(for: "statusMessages.fail.observed")
        let issues = SupplementalAccessibilityChecks.statusMessageIssues(
            observations: [
                StatusMessageObservation(
                    identifier: "statusMessages.pass",
                    label: passButton.label,
                    expectedMessage: "Upload started",
                    observedMessage: passObserved,
                    frame: passButton.frame
                ),
                StatusMessageObservation(
                    identifier: "statusMessages.fail",
                    label: failButton.label,
                    expectedMessage: "Draft saved",
                    observedMessage: failObserved,
                    frame: failButton.frame
                )
            ]
        )

        var report = AccessibilityAuditHTMLReport(title: "Status Messages Fixture")
        let screenshot = XCUIScreen.main.screenshot()
        report.record(
            ScreenResult(
                name: "Status Messages",
                screenshotPNGData: screenshot.pngRepresentation,
                screenshotSize: screenshot.image.size,
                issues: issues
            )
        )

        let flagged = Set(report.screens.flatMap(\.issues).map(\.elementIdentifier))
        XCTAssertTrue(
            flagged.contains("statusMessages.fail"),
            "Expected the silent status change to be flagged. Flagged=\(flagged)"
        )
        XCTAssertFalse(
            flagged.contains("statusMessages.pass"),
            "Expected the announced status change to stay clean. Flagged=\(flagged)"
        )
        XCTAssertTrue(report.screens.flatMap(\.issues).allSatisfy { $0.severity == .warning })
    }

    private func observedStatusMessage(for identifier: String) -> String? {
        let value = app.staticTexts[identifier].label
        return value == "No status message observed" ? nil : value
    }
}
