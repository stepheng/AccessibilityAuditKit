//  DeterministicChecksTests.swift
import AccessibilityAuditReport
import XCTest

@MainActor
final class DeterministicChecksTests: FixturesUITestCase {

    // Report every check's outcome in one run rather than stopping at the first.
    override func setUp() {
        super.setUp()
        continueAfterFailure = true
    }

    func testDeterministicSupplementalChecks() throws {
        guard #available(iOS 17.0, *) else { throw XCTSkip("Requires iOS 17+") }

        let checks = FixtureCatalog.all.filter {
            // Cross-screen checks (Consistent Identification) have no single
            // screenId, so the screenId != nil guard excludes them here; they
            // are covered by their own test class.
            $0.category == .supplemental && $0.tier == .exact && $0.screenId != nil
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

    func testScriptedChecksAreCataloguedAsAssertedCoverage() {
        let scriptedChecks = ["nonTextContrast", "statusMessages", "resizeReflow"]

        for id in scriptedChecks {
            let check = FixtureCatalog.first(id: id)
            XCTAssertEqual(check?.category, .scripted)
            XCTAssertEqual(check?.tier, .scripted)
        }
    }
}
