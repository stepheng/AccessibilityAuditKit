//  ScreenTitleTests.swift
import AccessibilityAuditReport
import XCTest

@MainActor
final class ScreenTitleTests: FixturesUITestCase {
    func testScreenTitle() throws {
        guard #available(iOS 17.0, *) else { throw XCTSkip("Requires iOS 17+") }

        launch(fixture: "screenTitleFail")
        let failIssues = try supplementalIssues([.screenTitle]).filter { $0.auditType == "Screen Title" }
        XCTAssertFalse(failIssues.isEmpty, "Empty-title nav bar should be flagged")

        launch(fixture: "screenTitlePass")
        let passIssues = try supplementalIssues([.screenTitle]).filter { $0.auditType == "Screen Title" }
        XCTAssertTrue(passIssues.isEmpty, "Titled nav bar should be clean")
    }
}
