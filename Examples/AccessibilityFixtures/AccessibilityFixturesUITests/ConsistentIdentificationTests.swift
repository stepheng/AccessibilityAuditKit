//  ConsistentIdentificationTests.swift
import AccessibilityAuditReport
import XCTest

@MainActor
final class ConsistentIdentificationTests: FixturesUITestCase {
    func testConsistentIdentification() throws {
        guard #available(iOS 17.0, *) else { throw XCTSkip("Requires iOS 17+") }

        launch(fixture: "cidA")
        let a = try inventory(screenName: "Screen A")
        launch(fixture: "cidB")
        let b = try inventory(screenName: "Screen B")

        let issues = SupplementalAccessibilityChecks.consistentIdentificationIssues(screens: [a, b])
            .filter { $0.auditType == "Consistent Identification" }
        let flagged = Set(issues.map(\.elementIdentifier))

        XCTAssertTrue(flagged.contains("cid.control"),
            "Differently-labelled shared id should be flagged. Flagged=\(flagged)")
        XCTAssertFalse(flagged.contains("cid.consistent"),
            "Consistently-labelled shared id should be clean. Flagged=\(flagged)")
        XCTAssertTrue(issues.allSatisfy { $0.severity == .error })
    }
}
