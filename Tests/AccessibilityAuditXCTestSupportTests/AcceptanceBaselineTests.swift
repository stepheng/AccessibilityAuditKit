//
//  AcceptanceBaselineTests.swift
//  AccessibilityAuditXCTestSupportTests
//
//  Created by Stephen Gurnett on 14/06/2026.
//

import AccessibilityAuditReport
import AccessibilityAuditXCTestSupport
import Foundation
import XCTest

final class AcceptanceBaselineTests: XCTestCase {
    private func writeTempFile(_ contents: String) throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("baseline-\(UUID().uuidString).json")
        try contents.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    func testLoadsValidBaseline() throws {
        let url = try writeTempFile("""
        [
          { "screen": "Home", "auditType": "Label in Name",
            "elementIdentifier": "saveButton", "reason": "Reviewed" }
        ]
        """)
        defer { try? FileManager.default.removeItem(at: url) }

        let rules = try AcceptanceBaseline.load(from: url)

        XCTAssertEqual(rules.count, 1)
        XCTAssertEqual(rules.first?.elementIdentifier, "saveButton")
        XCTAssertEqual(rules.first?.reason, "Reviewed")
    }

    func testRuleMissingReasonThrows() throws {
        let url = try writeTempFile("""
        [ { "screen": "Home", "auditType": "Label in Name" } ]
        """)
        defer { try? FileManager.default.removeItem(at: url) }

        XCTAssertThrowsError(try AcceptanceBaseline.load(from: url))
    }
}
