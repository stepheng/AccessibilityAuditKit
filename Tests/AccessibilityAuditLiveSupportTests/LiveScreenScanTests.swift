//
//  LiveScreenScanTests.swift
//  AccessibilityAuditLiveSupportTests
//
//  Created by Stephen Gurnett on 14/06/2026.
//

#if canImport(UIKit)
import CoreGraphics
import UIKit
import XCTest
@testable import AccessibilityAuditLiveSupport

private final class RuntimeBreadcrumbOwnerView: UIView {}
private final class RuntimeBreadcrumbActionView: UIView {}

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

    func testLiveInteractiveElementsCarryRuntimeHints() throws {
        let root = AccessibilityNode(
            frame: CGRect(x: 0, y: 0, width: 400, height: 800),
            children: [
                AccessibilityNode(
                    identifier: "shared.close",
                    label: "Close",
                    traits: .button,
                    frame: CGRect(x: 0, y: 0, width: 20, height: 20),
                    isAccessibilityElement: true,
                    objectClassName: "CapsuleButton",
                    objectModuleName: "CommonUx",
                    ownerClassName: "BannerView",
                    ownerModuleName: "CommonUx"
                )
            ]
        )

        let element = try XCTUnwrap(LiveScreenScan.interactiveElements(in: root, within: root.frame).first)

        XCTAssertTrue(element.reviewerHints.contains {
            $0.automationKey == "runtime.class" && $0.detail.contains("CommonUx.CapsuleButton")
        })
        XCTAssertTrue(element.reviewerHints.contains {
            $0.automationKey == "runtime.ownerClass" && $0.detail.contains("CommonUx.BannerView")
        })
    }

    func testLiveIssuesIncludeRuntimeBreadcrumbHints() throws {
        let root = AccessibilityNode(
            frame: CGRect(x: 0, y: 0, width: 400, height: 800),
            children: [
                AccessibilityNode(
                    identifier: "shared.close",
                    label: "Close",
                    traits: .button,
                    frame: CGRect(x: 0, y: 0, width: 20, height: 20),
                    isAccessibilityElement: true,
                    objectClassName: "CapsuleButton",
                    objectModuleName: "CommonUx"
                )
            ]
        )

        let issue = try XCTUnwrap(
            LiveScreenScan.issues(in: root, navigationBarTitles: [])
                .first { $0.auditType.hasPrefix("Target Size") }
        )

        XCTAssertTrue(issue.reviewerHints.contains { $0.automationKey == "runtime.class" })
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

    func testZeroFrameInteractiveContainerStillCollectsOnScreenChildren() {
        let root = AccessibilityNode(
            frame: CGRect(x: 0, y: 0, width: 400, height: 800),
            children: [
                AccessibilityNode(
                    traits: .button,
                    frame: .zero,
                    children: [button("real.child", "Submit", CGRect(x: 0, y: 0, width: 80, height: 44))]
                )
            ]
        )
        let elements = LiveScreenScan.interactiveElements(in: root, within: root.frame)
        XCTAssertEqual(elements.count, 1)
        XCTAssertEqual(elements.first?.identifier, "real.child")
    }

    @MainActor
    func testWalkerCapturesRuntimeClassAndOwnerBreadcrumbs() throws {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        let owner = RuntimeBreadcrumbOwnerView(frame: window.bounds)
        let action = RuntimeBreadcrumbActionView(frame: CGRect(x: 10, y: 20, width: 44, height: 44))
        action.isAccessibilityElement = true
        action.accessibilityIdentifier = "shared.close"
        action.accessibilityLabel = "Close"
        owner.addSubview(action)
        window.addSubview(owner)
        window.layoutIfNeeded()

        let root = UIAccessibilityTreeWalker.node(for: window)
        let node = try XCTUnwrap(firstNode(withIdentifier: "shared.close", in: root), treeDescription(root))

        XCTAssertEqual(node.objectClassName, "RuntimeBreadcrumbActionView")
        XCTAssertEqual(node.ownerClassName, "RuntimeBreadcrumbOwnerView")
        XCTAssertEqual(node.objectModuleName, "AccessibilityAuditLiveSupportTests")
        XCTAssertEqual(node.ownerModuleName, "AccessibilityAuditLiveSupportTests")
    }

    @MainActor
    func testWalkerRespectsEmptyCustomAccessibilityElements() {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        let owner = UIView(frame: window.bounds)
        owner.accessibilityElements = []
        let hiddenAction = UIView(frame: CGRect(x: 10, y: 20, width: 44, height: 44))
        hiddenAction.isAccessibilityElement = true
        hiddenAction.accessibilityIdentifier = "hidden.action"
        hiddenAction.accessibilityLabel = "Hidden"
        hiddenAction.accessibilityTraits = .button
        owner.addSubview(hiddenAction)
        window.addSubview(owner)
        window.layoutIfNeeded()

        let root = UIAccessibilityTreeWalker.node(for: window)

        XCTAssertNil(firstNode(withIdentifier: "hidden.action", in: root), treeDescription(root))
    }

    func testNonInteractiveContainerRecursesIntoInteractiveChildren() {
        let root = AccessibilityNode(
            frame: CGRect(x: 0, y: 0, width: 400, height: 800),
            children: [
                AccessibilityNode(
                    frame: CGRect(x: 0, y: 0, width: 400, height: 88),
                    children: [
                        button("a", "First", CGRect(x: 0, y: 0, width: 80, height: 44)),
                        button("b", "Second", CGRect(x: 0, y: 44, width: 80, height: 44))
                    ]
                )
            ]
        )
        let elements = LiveScreenScan.interactiveElements(in: root, within: root.frame)
        XCTAssertEqual(elements.count, 2)
        XCTAssertEqual(Set(elements.map(\.identifier)), ["a", "b"])
    }

    func testIssuesFiresDuplicateLabelsThroughAggregator() {
        let root = AccessibilityNode(
            frame: CGRect(x: 0, y: 0, width: 400, height: 800),
            children: [
                button("share.top", "Share", CGRect(x: 0, y: 0, width: 60, height: 44)),
                button("share.bottom", "Share", CGRect(x: 0, y: 100, width: 60, height: 44))
            ]
        )
        let issues = LiveScreenScan.issues(in: root, navigationBarTitles: [])
        XCTAssertTrue(issues.contains { $0.auditType == "Duplicate Labels" })
    }

    /// A system scroll indicator carries the `.adjustable` trait, so the
    /// trait-driven live scanner would otherwise collect it as an interactive
    /// target — but its size is user-agent controlled, so it is not an authored
    /// target and must not be audited (matches the XCTest path, which never
    /// collects `.scrollBar`).
    private func scrollBar(_ label: String, _ frame: CGRect) -> AccessibilityNode {
        AccessibilityNode(
            identifier: "", label: label, value: "29 pages", traits: .adjustable,
            frame: frame, isAccessibilityElement: true
        )
    }

    func testIgnoresSystemScrollBarAsInteractiveTarget() {
        let root = AccessibilityNode(
            frame: CGRect(x: 0, y: 0, width: 402, height: 874),
            children: [scrollBar("Vertical scroll bar", CGRect(x: 369, y: 116, width: 30, height: 675))]
        )
        XCTAssertTrue(LiveScreenScan.interactiveElements(in: root, within: root.frame).isEmpty)
    }

    func testIssuesDoesNotFlagScrollBarTargetSize() {
        let root = AccessibilityNode(
            frame: CGRect(x: 0, y: 0, width: 402, height: 874),
            children: [
                scrollBar("Vertical scroll bar", CGRect(x: 369, y: 116, width: 30, height: 675)),
                scrollBar("Horizontal scroll bar", CGRect(x: 62, y: 758, width: 278, height: 30))
            ]
        )
        let issues = LiveScreenScan.issues(in: root, navigationBarTitles: [])
        XCTAssertFalse(issues.contains { $0.auditType.hasPrefix("Target Size") })
    }

    func testIgnoresScrollBarIdentifiedByScrollViewOwnerWithoutLabel() {
        // No "scroll bar" label — identified purely by being an adjustable
        // direct child of a UIScrollView, the locale-independent signal.
        let root = AccessibilityNode(
            frame: CGRect(x: 0, y: 0, width: 402, height: 874),
            children: [
                AccessibilityNode(
                    identifier: "", label: "", value: "29 pages", traits: .adjustable,
                    frame: CGRect(x: 369, y: 116, width: 30, height: 675),
                    isAccessibilityElement: true, ownerIsScrollView: true
                )
            ]
        )
        XCTAssertTrue(LiveScreenScan.interactiveElements(in: root, within: root.frame).isEmpty)
    }

    @MainActor
    func testWalkerMarksOnlyScrollViewChildrenAsScrollOwned() {
        func walk(rootContainer: UIView) -> AccessibilityNode {
            let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 402, height: 874))
            rootContainer.frame = window.bounds
            let child = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
            child.isAccessibilityElement = true
            rootContainer.addSubview(child)
            window.addSubview(rootContainer)
            window.layoutIfNeeded()
            return UIAccessibilityTreeWalker.node(for: window)
        }

        XCTAssertFalse(
            anyScrollOwned(walk(rootContainer: UIView())),
            "A plain container must not mark its children as scroll-owned"
        )
        XCTAssertTrue(
            anyScrollOwned(walk(rootContainer: UIScrollView())),
            "A UIScrollView must mark its direct children as scroll-owned"
        )
    }

    private func anyScrollOwned(_ node: AccessibilityNode) -> Bool {
        node.ownerIsScrollView || node.children.contains(where: anyScrollOwned)
    }

    private func firstNode(withIdentifier identifier: String, in node: AccessibilityNode) -> AccessibilityNode? {
        if node.identifier == identifier { return node }
        for child in node.children {
            if let match = firstNode(withIdentifier: identifier, in: child) {
                return match
            }
        }
        return nil
    }

    private func treeDescription(_ node: AccessibilityNode, depth: Int = 0) -> String {
        let indent = String(repeating: "  ", count: depth)
        let current = "\(indent)\(node.objectClassName) id=\(node.identifier) label=\(node.label)"
        return ([current] + node.children.map { treeDescription($0, depth: depth + 1) })
            .joined(separator: "\n")
    }

    func testUndersizedRealAdjustableIsStillFlagged() {
        let root = AccessibilityNode(
            frame: CGRect(x: 0, y: 0, width: 402, height: 874),
            children: [
                AccessibilityNode(
                    identifier: "vol", label: "Volume", value: "30%", traits: .adjustable,
                    frame: CGRect(x: 0, y: 0, width: 200, height: 30), isAccessibilityElement: true
                )
            ]
        )
        let issues = LiveScreenScan.issues(in: root, navigationBarTitles: [])
        XCTAssertTrue(issues.contains { $0.auditType == "Target Size (Enhanced)" })
    }
}
#endif
