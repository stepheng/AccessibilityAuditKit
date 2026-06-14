//
//  AccessibilityNodeTests.swift
//  AccessibilityAuditReport
//
//  Created by Stephen Gurnett on 14/06/2026.
//

#if canImport(UIKit)
import CoreGraphics
import UIKit
import XCTest
@testable import AccessibilityAuditLiveSupport

final class AccessibilityNodeTests: XCTestCase {
    func testNodeDefaultsAreEmpty() {
        let node = AccessibilityNode()
        XCTAssertEqual(node.label, "")
        XCTAssertTrue(node.children.isEmpty)
        XCTAssertFalse(node.isAccessibilityElement)
        XCTAssertEqual(node.objectClassName, "")
        XCTAssertNil(node.objectModuleName)
        XCTAssertNil(node.ownerClassName)
        XCTAssertNil(node.ownerModuleName)
    }
}
#endif
