//
//  LiveScreenScanTests.swift
//  AccessibilityAuditReport
//
//  Created by Stephen Gurnett on 14/06/2026.
//

#if canImport(UIKit)
import CoreGraphics
import UIKit
import XCTest
@testable import AccessibilityAuditLiveSupport

final class LiveScreenScanTests: XCTestCase {
    private func button(_ id: String, _ label: String, _ frame: CGRect) -> AccessibilityNode {
        AccessibilityNode(identifier: id, label: label, traits: .button, frame: frame, isAccessibilityElement: true)
    }

    func testCollectsOutermostInteractiveElementsOnly() {
        let root = AccessibilityNode(
            frame: CGRect(x: 0, y: 0, width: 400, height: 800),
            children: [
                AccessibilityNode(
                    traits: .button,
                    frame: CGRect(x: 0, y: 0, width: 100, height: 44),
                    isAccessibilityElement: false,
                    children: [button("inner", "Inner", CGRect(x: 0, y: 0, width: 20, height: 20))]
                )
            ]
        )

        let elements = LiveScreenScan.interactiveElements(in: root, within: root.frame)

        XCTAssertEqual(elements.count, 1)
        XCTAssertEqual(elements.first?.frame.width, 100)
        XCTAssertTrue(elements.first?.requiresDescription == true)
    }

    func testIgnoresElementsOutsideBounds() {
        let root = AccessibilityNode(
            frame: CGRect(x: 0, y: 0, width: 400, height: 800),
            children: [button("offscreen", "Off", CGRect(x: 0, y: 2000, width: 44, height: 44))]
        )
        XCTAssertTrue(LiveScreenScan.interactiveElements(in: root, within: root.frame).isEmpty)
    }

    func testRequiresDescriptionElementsIncludeImages() {
        let root = AccessibilityNode(
            frame: CGRect(x: 0, y: 0, width: 400, height: 800),
            children: [
                AccessibilityNode(identifier: "logo", label: "", traits: .image,
                                  frame: CGRect(x: 0, y: 0, width: 80, height: 80), isAccessibilityElement: true)
            ]
        )
        let elements = LiveScreenScan.elementsRequiringDescription(in: root, within: root.frame)
        XCTAssertEqual(elements.count, 1)
        XCTAssertEqual(elements.first?.identifier, "logo")
    }

    func testAdjustableElementsCarryValue() {
        let root = AccessibilityNode(
            frame: CGRect(x: 0, y: 0, width: 400, height: 800),
            children: [
                AccessibilityNode(identifier: "vol", label: "Volume", value: "30%", traits: .adjustable,
                                  frame: CGRect(x: 0, y: 0, width: 200, height: 30), isAccessibilityElement: true)
            ]
        )
        let elements = LiveScreenScan.adjustableElements(in: root, within: root.frame)
        XCTAssertEqual(elements.first?.value, "30%")
    }

    func testIssuesRunsMissingDescriptionForUnlabelledControl() {
        let root = AccessibilityNode(
            frame: CGRect(x: 0, y: 0, width: 400, height: 800),
            children: [button("unnamed", "", CGRect(x: 0, y: 0, width: 44, height: 44))]
        )
        let issues = LiveScreenScan.issues(in: root, navigationBarTitles: [])
        XCTAssertTrue(issues.contains { $0.auditType == "Element Description" })
    }

    func testIssuesRunsScreenTitleForEmptyNavTitle() {
        let root = AccessibilityNode(frame: CGRect(x: 0, y: 0, width: 400, height: 800))
        let issues = LiveScreenScan.issues(in: root, navigationBarTitles: [""])
        XCTAssertTrue(issues.contains { $0.auditType == "Screen Title" })
    }
}
#endif
