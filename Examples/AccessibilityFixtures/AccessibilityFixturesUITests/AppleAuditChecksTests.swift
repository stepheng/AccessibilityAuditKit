//
//  AppleAuditChecksTests.swift
//  AccessibilityFixturesUITests
//
//  Created by Stephen Gurnett on 15/06/2026.
//

import AccessibilityAuditReport
import AccessibilityAuditXCTestSupport
import XCTest

@MainActor
final class AppleAuditChecksTests: FixturesUITestCase {

    // Data-driven over every Apple-audit fixture: report all checks' outcomes in
    // one run rather than stopping at the first failing one.
    override func setUp() {
        super.setUp()
        continueAfterFailure = true
    }

    @available(iOS 17.0, *)
    private func auditTypeNames(running type: XCUIAccessibilityAuditType) throws -> [String] {
        var names: [String] = []
        try app.performAccessibilityAudit(for: type) { issue in
            names.append(AccessibilityAuditTypeNameFormatter.name(for: issue.auditType))
            return true   // handled — do not fail the XCTest audit; we assert ourselves
        }
        return names
    }

    func testAppleAuditChecks() throws {
        guard #available(iOS 17.0, *) else { throw XCTSkip("Requires iOS 17+") }

        // tier == .lenient keeps any downgraded (tier == .manual) check out of this gate.
        let checks = FixtureCatalog.all.filter { $0.category == .appleAudit && $0.tier == .lenient }
        XCTAssertFalse(checks.isEmpty, "Catalog should yield lenient Apple-audit checks to assert")
        for check in checks {
            guard let kind = check.appleKind,
                  let failScreen = check.failScreenId,
                  let passScreen = check.passScreenId,
                  let name = check.auditType else { continue }
            let type = CatalogMapping.auditType(kind)

            try XCTContext.runActivity(named: check.title) { _ in
                launch(fixture: failScreen)
                let failNames = try auditTypeNames(running: type)
                XCTAssertTrue(failNames.contains { $0.contains(name) },
                    "\(check.title): fail screen should raise a \(name) issue. Got=\(failNames)")

                launch(fixture: passScreen)
                let passNames = try auditTypeNames(running: type)
                XCTAssertFalse(passNames.contains { $0.contains(name) },
                    "\(check.title): pass screen should be clean. Got=\(passNames)")
            }
        }
    }
}
