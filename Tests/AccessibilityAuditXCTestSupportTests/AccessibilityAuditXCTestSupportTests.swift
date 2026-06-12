//
//  AccessibilityAuditXCTestSupportTests.swift
//  AccessibilityAuditReport
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
}
