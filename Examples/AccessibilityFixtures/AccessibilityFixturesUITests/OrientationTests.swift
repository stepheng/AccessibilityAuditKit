//  OrientationTests.swift
import AccessibilityAuditReport
import AccessibilityAuditXCTestSupport
import XCTest

@MainActor
final class OrientationTests: FixturesUITestCase {
    func testOrientationLock() throws {
        guard #available(iOS 17.0, *) else { throw XCTSkip("Requires iOS 17+") }

        // Fail: app locked to portrait → window stays portrait after rotation.
        launch(fixture: "orientation", extraArgs: ["-lockOrientation", "portrait"])
        var lockedReport = AccessibilityAuditHTMLReport(title: "Orientation locked")
        app.recordOrientationLockCheck(in: &lockedReport)
        let lockedIssues = lockedReport.screens.last?.issues.filter { $0.auditType == "Orientation" } ?? []
        XCTAssertFalse(lockedIssues.isEmpty, "Locked app should record an Orientation issue")

        // Pass: app adapts → no Orientation issue.
        launch(fixture: "orientation")
        var freeReport = AccessibilityAuditHTMLReport(title: "Orientation free")
        app.recordOrientationLockCheck(in: &freeReport)
        let freeIssues = freeReport.screens.last?.issues.filter { $0.auditType == "Orientation" } ?? []
        XCTAssertTrue(freeIssues.isEmpty, "Adaptive app should record no Orientation issue")
    }
}
