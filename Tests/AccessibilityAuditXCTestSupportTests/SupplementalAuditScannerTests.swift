//
//  SupplementalAuditScannerTests.swift
//  AccessibilityAuditReport
//
//  Created by Stephen Gurnett on 12/06/2026.
//

import AccessibilityAuditXCTestSupport
import XCTest

private final class FakeSnapshot: XCUIElementSnapshot {
    let elementType: XCUIElement.ElementType
    let identifier: String
    let label: String
    let title: String
    let frame: CGRect
    let children: [any XCUIElementSnapshot]
    let exists = true
    let value: Any? = nil
    let placeholderValue: String? = nil
    let isEnabled = true
    let isSelected = false
    let hasFocus = false
    let horizontalSizeClass = XCUIElement.SizeClass.unspecified
    let verticalSizeClass = XCUIElement.SizeClass.unspecified
    var dictionaryRepresentation: [XCUIElement.AttributeName: Any] { [:] }

    init(
        elementType: XCUIElement.ElementType = .other,
        identifier: String = "",
        label: String = "",
        title: String = "",
        frame: CGRect = .zero,
        children: [any XCUIElementSnapshot] = []
    ) {
        self.elementType = elementType
        self.identifier = identifier
        self.label = label
        self.title = title
        self.frame = frame
        self.children = children
    }
}

final class SupplementalAuditScannerTests: XCTestCase {
    private let screen = CGRect(x: 0, y: 0, width: 400, height: 800)

    func testCollectsSmallInteractiveElementAsTargetSizeIssue() throws {
        let root = FakeSnapshot(
            frame: screen,
            children: [
                FakeSnapshot(
                    elementType: .button,
                    identifier: "home.closeButton",
                    label: "Close",
                    frame: CGRect(x: 10, y: 10, width: 30, height: 30)
                )
            ]
        )

        let issues = SupplementalAuditScanner.issues(in: root, checks: .targetSize)

        XCTAssertEqual(issues.count, 1)
        let issue = try XCTUnwrap(issues.first)
        XCTAssertEqual(issue.auditType, "Target Size")
        XCTAssertEqual(issue.elementIdentifier, "home.closeButton")
    }

    func testDoesNotDescendIntoInteractiveElements() {
        // The inner button is part of the outer control's composite; only the
        // outermost interactive element counts as a target.
        let root = FakeSnapshot(
            frame: screen,
            children: [
                FakeSnapshot(
                    elementType: .button,
                    identifier: "card",
                    label: "Open card",
                    frame: CGRect(x: 0, y: 0, width: 200, height: 100),
                    children: [
                        FakeSnapshot(
                            elementType: .button,
                            identifier: "card.inner",
                            label: "Inner",
                            frame: CGRect(x: 10, y: 10, width: 30, height: 30)
                        )
                    ]
                )
            ]
        )

        let issues = SupplementalAuditScanner.issues(in: root, checks: .targetSize)

        XCTAssertTrue(issues.isEmpty)
    }

    func testIgnoresElementsOutsideRootFrame() {
        let root = FakeSnapshot(
            frame: screen,
            children: [
                FakeSnapshot(
                    elementType: .button,
                    identifier: "offscreen.button",
                    label: "Offscreen",
                    frame: CGRect(x: -1000, y: 10, width: 30, height: 30)
                )
            ]
        )

        let issues = SupplementalAuditScanner.issues(in: root, checks: .targetSize)

        XCTAssertTrue(issues.isEmpty)
    }

    func testFlagsAdjacentInteractiveElementsAsSpacingIssue() {
        let root = FakeSnapshot(
            frame: screen,
            children: [
                FakeSnapshot(
                    elementType: .button,
                    identifier: "toolbar.share",
                    label: "Share",
                    frame: CGRect(x: 0, y: 0, width: 44, height: 44)
                ),
                FakeSnapshot(
                    elementType: .button,
                    identifier: "toolbar.delete",
                    label: "Delete",
                    frame: CGRect(x: 46, y: 0, width: 44, height: 44)
                )
            ]
        )

        let issues = SupplementalAuditScanner.issues(in: root, checks: .targetSpacing)

        XCTAssertEqual(issues.count, 1)
        XCTAssertEqual(issues.first?.auditType, "Target Spacing")
    }

    func testFlagsNavigationBarWithoutTitle() {
        let root = FakeSnapshot(
            frame: screen,
            children: [
                FakeSnapshot(
                    elementType: .navigationBar,
                    frame: CGRect(x: 0, y: 0, width: 400, height: 44)
                )
            ]
        )

        let issues = SupplementalAuditScanner.issues(in: root, checks: .screenTitle)

        XCTAssertEqual(issues.count, 1)
        XCTAssertEqual(issues.first?.auditType, "Screen Title")
    }

    func testUsesNavigationBarStaticTextAsTitle() {
        let root = FakeSnapshot(
            frame: screen,
            children: [
                FakeSnapshot(
                    elementType: .navigationBar,
                    frame: CGRect(x: 0, y: 0, width: 400, height: 44),
                    children: [
                        FakeSnapshot(
                            elementType: .staticText,
                            label: "Photos",
                            frame: CGRect(x: 150, y: 0, width: 100, height: 44)
                        )
                    ]
                )
            ]
        )

        let issues = SupplementalAuditScanner.issues(in: root, checks: .screenTitle)

        XCTAssertTrue(issues.isEmpty)
    }

    func testFlagsDuplicateLabelsAcrossInteractiveElements() {
        let root = FakeSnapshot(
            frame: screen,
            children: [
                FakeSnapshot(
                    elementType: .button,
                    identifier: "row1.edit",
                    label: "Edit",
                    frame: CGRect(x: 0, y: 0, width: 44, height: 44)
                ),
                FakeSnapshot(
                    elementType: .button,
                    identifier: "row2.edit",
                    label: "Edit",
                    frame: CGRect(x: 0, y: 100, width: 44, height: 44)
                )
            ]
        )

        let issues = SupplementalAuditScanner.issues(in: root, checks: .duplicateLabels)

        XCTAssertEqual(issues.count, 1)
        XCTAssertEqual(issues.first?.auditType, "Duplicate Labels")
    }

    func testRunsOnlySelectedChecks() {
        let root = FakeSnapshot(
            frame: screen,
            children: [
                FakeSnapshot(
                    elementType: .button,
                    identifier: "home.closeButton",
                    label: "Close",
                    frame: CGRect(x: 10, y: 10, width: 30, height: 30)
                )
            ]
        )

        let issues = SupplementalAuditScanner.issues(in: root, checks: .screenTitle)

        XCTAssertTrue(issues.isEmpty)
    }

    func testAllRunsEveryCheck() {
        let root = FakeSnapshot(
            frame: screen,
            children: [
                FakeSnapshot(
                    elementType: .navigationBar,
                    frame: CGRect(x: 0, y: 0, width: 400, height: 44)
                ),
                FakeSnapshot(
                    elementType: .button,
                    identifier: "home.closeButton",
                    label: "Close",
                    frame: CGRect(x: 10, y: 100, width: 30, height: 30)
                )
            ]
        )

        let issues = SupplementalAuditScanner.issues(in: root, checks: .all)

        XCTAssertEqual(
            Set(issues.map(\.auditType)),
            ["Target Size", "Screen Title"]
        )
    }
}
