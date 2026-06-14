//  DeterministicChecksTests.swift
import AccessibilityAuditReport
import XCTest

@MainActor
final class DeterministicChecksTests: FixturesUITestCase {

    func testDeterministicSupplementalChecks() throws {
        guard #available(iOS 17.0, *) else { throw XCTSkip("Requires iOS 17+") }

        let checks = FixtureCatalog.all.filter {
            $0.category == .supplemental && $0.tier == .exact
                && $0.id != "consistentIdentification"   // cross-screen, tested separately
                && $0.screenId != nil                    // single-screen only
        }
        XCTAssertFalse(checks.isEmpty, "Catalog should yield deterministic single-screen checks")

        for check in checks {
            try XCTContext.runActivity(named: check.title) { _ in
                launch(fixture: check.screenId!)
                let ofType = try supplementalIssues(check.supplementalKinds)
                    .filter { $0.auditType == check.auditType }
                let flagged = Set(ofType.map(\.elementIdentifier))

                switch check.failMatch {
                case .all:
                    for id in check.failIdentifiers {
                        XCTAssertTrue(flagged.contains(id),
                            "\(check.title): expected \(id) flagged. Flagged=\(flagged)")
                    }
                case .any:
                    XCTAssertTrue(check.failIdentifiers.contains { flagged.contains($0) },
                        "\(check.title): expected one of \(check.failIdentifiers). Flagged=\(flagged)")
                }

                for id in check.passIdentifiers {
                    XCTAssertFalse(flagged.contains(id),
                        "\(check.title): \(id) should be clean. Flagged=\(flagged)")
                }

                if let expected = check.severity {
                    let sev = CatalogMapping.severity(expected)
                    XCTAssertTrue(ofType.allSatisfy { $0.severity == sev },
                        "\(check.title): expected severity \(sev)")
                }
            }
        }
    }
}
