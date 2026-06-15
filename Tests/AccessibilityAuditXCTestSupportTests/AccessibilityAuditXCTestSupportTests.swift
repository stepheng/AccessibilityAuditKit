//
//  AccessibilityAuditXCTestSupportTests.swift
//  AccessibilityAuditXCTestSupportTests
//
//  Created by Stephen Gurnett on 12/06/2026.
//

import AccessibilityAuditXCTestSupport
import XCTest

final class AccessibilityAuditXCTestSupportTests: XCTestCase {
    @available(iOS 17.0, macOS 14.0, *)
    func testAccessibilityAuditTypeNameFormatsKnownTypes() {
        let auditTypes: XCUIAccessibilityAuditType = [
            .contrast,
            .hitRegion
        ]

        XCTAssertEqual(
            AccessibilityAuditTypeNameFormatter.name(for: auditTypes),
            "Contrast, Hit Region"
        )
    }

    func testAppleAuditLocatorHintHelperUsesElementMetadata() {
        let hints = AccessibilityAuditIssueHints.locatorHints(
            auditType: "Hit Region",
            identifier: "home.closeButton",
            label: "Close"
        )

        XCTAssertTrue(hints.contains { $0.automationKey == "source.search.identifier" })
        XCTAssertTrue(hints.contains { $0.automationKey == "source.search.label" })
        XCTAssertTrue(hints.contains { $0.automationKey == "audit.remediation.target-size" })
    }
}
