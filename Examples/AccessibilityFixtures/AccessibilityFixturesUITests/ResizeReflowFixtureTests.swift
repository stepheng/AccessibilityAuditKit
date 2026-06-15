//  ResizeReflowFixtureTests.swift
import AccessibilityAuditReport
import XCTest

@MainActor
final class ResizeReflowFixtureTests: FixturesUITestCase {
    func testResizeReflowFixtureRecordsLargeTextOverflowObservation() throws {
        guard #available(iOS 17.0, *) else { throw XCTSkip("Requires iOS 17+") }

        launch(
            fixture: "future.resizeReflow",
            extraArgs: [
                "-UIPreferredContentSizeCategoryName",
                "UICTContentSizeCategoryAccessibilityXXXL"
            ]
        )

        let passText = app.descendants(matching: .any)["resizeReflow.pass"]
        XCTAssertTrue(passText.waitForExistence(timeout: 2))
        let failText = app.descendants(matching: .any)["resizeReflow.fail"]
        XCTAssertTrue(failText.waitForExistence(timeout: 2))

        let window = app.windows.firstMatch.frame
        let viewport = CGRect(
            x: passText.frame.minX,
            y: window.minY,
            width: window.width,
            height: window.height
        )
        let issues = SupplementalAccessibilityChecks.resizeReflowIssues(
            observations: [
                ResizeReflowObservation(
                    identifier: "resizeReflow.pass",
                    label: passText.label,
                    variant: "AX XXXL Portrait",
                    frame: passText.frame,
                    viewportFrame: viewport
                ),
                ResizeReflowObservation(
                    identifier: "resizeReflow.fail",
                    label: failText.label,
                    variant: "AX XXXL Portrait",
                    frame: failText.frame,
                    viewportFrame: viewport
                )
            ]
        )

        var report = AccessibilityAuditHTMLReport(title: "Resize Text / Reflow Fixture")
        let screenshot = XCUIScreen.main.screenshot()
        report.record(
            ScreenResult(
                name: "Resize Text / Reflow",
                screenshotPNGData: screenshot.pngRepresentation,
                screenshotSize: screenshot.image.size,
                issues: issues
            )
        )

        let flagged = Set(report.screens.flatMap(\.issues).map(\.elementIdentifier))
        XCTAssertTrue(
            flagged.contains("resizeReflow.fail"),
            "Expected the fixed-width text to be flagged. \(frameDebug(pass: passText.frame, fail: failText.frame, viewport: viewport, flagged: flagged))"
        )
        XCTAssertFalse(
            flagged.contains("resizeReflow.pass"),
            "Expected the wrapping text to stay clean. \(frameDebug(pass: passText.frame, fail: failText.frame, viewport: viewport, flagged: flagged))"
        )
        XCTAssertTrue(report.screens.flatMap(\.issues).allSatisfy { $0.severity == .warning })
    }

    private func frameDebug(pass: CGRect, fail: CGRect, viewport: CGRect, flagged: Set<String>) -> String {
        "pass=\(pass) fail=\(fail) viewport=\(viewport) flagged=\(flagged)"
    }
}
