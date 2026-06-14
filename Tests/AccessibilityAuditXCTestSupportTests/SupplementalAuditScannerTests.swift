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
    let value: Any?
    let placeholderValue: String? = nil
    let isEnabled: Bool
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
        value: Any? = nil,
        isEnabled: Bool = true,
        children: [any XCUIElementSnapshot] = []
    ) {
        self.elementType = elementType
        self.identifier = identifier
        self.label = label
        self.title = title
        self.frame = frame
        self.value = value
        self.isEnabled = isEnabled
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
        XCTAssertEqual(issue.auditType, "Target Size (Enhanced)")
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

    func testFlagsUndersizedTargetTooCloseToNeighbourAsSpacingIssue() {
        let root = FakeSnapshot(
            frame: screen,
            children: [
                FakeSnapshot(
                    elementType: .button,
                    identifier: "toolbar.share",
                    label: "Share",
                    frame: CGRect(x: 0, y: 0, width: 20, height: 20)
                ),
                FakeSnapshot(
                    elementType: .button,
                    identifier: "toolbar.delete",
                    label: "Delete",
                    frame: CGRect(x: 20, y: 0, width: 44, height: 44)
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

    func testCollectsDescendantStaticTextForLabelInNameCheck() throws {
        let root = FakeSnapshot(
            frame: screen,
            children: [
                FakeSnapshot(
                    elementType: .button,
                    identifier: "compose.send",
                    label: "submit_btn",
                    frame: CGRect(x: 0, y: 0, width: 100, height: 44),
                    children: [
                        FakeSnapshot(
                            elementType: .staticText,
                            label: "Send",
                            frame: CGRect(x: 10, y: 10, width: 80, height: 24)
                        )
                    ]
                )
            ]
        )

        let issues = SupplementalAuditScanner.issues(in: root, checks: .labelInName)

        XCTAssertEqual(issues.count, 1)
        let issue = try XCTUnwrap(issues.first)
        XCTAssertEqual(issue.auditType, "Label in Name")
        XCTAssertEqual(issue.elementIdentifier, "compose.send")
    }

    func testLabelInNamePassesButtonWhoseLabelMatchesItsText() {
        let root = FakeSnapshot(
            frame: screen,
            children: [
                FakeSnapshot(
                    elementType: .button,
                    identifier: "compose.send",
                    label: "Send",
                    frame: CGRect(x: 0, y: 0, width: 100, height: 44),
                    children: [
                        FakeSnapshot(
                            elementType: .staticText,
                            label: "Send",
                            frame: CGRect(x: 10, y: 10, width: 80, height: 24)
                        )
                    ]
                )
            ]
        )

        let issues = SupplementalAuditScanner.issues(in: root, checks: .labelInName)

        XCTAssertTrue(issues.isEmpty)
    }

    func testFlagsGenericButtonLabel() {
        let root = FakeSnapshot(
            frame: screen,
            children: [
                FakeSnapshot(
                    elementType: .button,
                    identifier: "home.action",
                    label: "Button",
                    frame: CGRect(x: 0, y: 0, width: 44, height: 44)
                )
            ]
        )

        let issues = SupplementalAuditScanner.issues(in: root, checks: .genericLabels)

        XCTAssertEqual(issues.count, 1)
        XCTAssertEqual(issues.first?.auditType, "Generic Label")
    }

    func testFlagsSliderWithoutValue() throws {
        let root = FakeSnapshot(
            frame: screen,
            children: [
                FakeSnapshot(
                    elementType: .slider,
                    identifier: "player.volume",
                    label: "Volume",
                    frame: CGRect(x: 0, y: 0, width: 200, height: 44)
                )
            ]
        )

        let issues = SupplementalAuditScanner.issues(in: root, checks: .adjustableValue)

        XCTAssertEqual(issues.count, 1)
        let issue = try XCTUnwrap(issues.first)
        XCTAssertEqual(issue.auditType, "Adjustable Value")
        XCTAssertEqual(issue.elementIdentifier, "player.volume")
    }

    func testPassesSliderExposingValue() {
        let root = FakeSnapshot(
            frame: screen,
            children: [
                FakeSnapshot(
                    elementType: .slider,
                    identifier: "player.volume",
                    label: "Volume",
                    frame: CGRect(x: 0, y: 0, width: 200, height: 44),
                    value: "50%"
                )
            ]
        )

        let issues = SupplementalAuditScanner.issues(in: root, checks: .adjustableValue)

        XCTAssertTrue(issues.isEmpty)
    }

    func testConsistentIdentificationProducesNoPerScreenIssues() {
        // The check compares labels across screens, so it contributes no
        // issues during a single-screen scan.
        let root = FakeSnapshot(
            frame: screen,
            children: [
                FakeSnapshot(
                    elementType: .button,
                    identifier: "tab.photos",
                    label: "Photos",
                    frame: CGRect(x: 0, y: 0, width: 44, height: 44)
                )
            ]
        )

        let issues = SupplementalAuditScanner.issues(in: root, checks: .consistentIdentification)

        XCTAssertTrue(issues.isEmpty)
    }

    func testInteractiveElementInventoryCollectsElementsForCrossScreenChecks() throws {
        let root = FakeSnapshot(
            frame: screen,
            children: [
                FakeSnapshot(
                    elementType: .button,
                    identifier: "tab.photos",
                    label: "Photos",
                    frame: CGRect(x: 0, y: 0, width: 44, height: 44)
                ),
                FakeSnapshot(
                    elementType: .staticText,
                    label: "Welcome",
                    frame: CGRect(x: 0, y: 100, width: 200, height: 24)
                )
            ]
        )

        let elements = SupplementalAuditScanner.interactiveElementInventory(in: root)

        XCTAssertEqual(elements.count, 1)
        let element = try XCTUnwrap(elements.first)
        XCTAssertEqual(element.identifier, "tab.photos")
        XCTAssertEqual(element.label, "Photos")
    }

    func testFlagsLabelWithRedundantRoleSuffix() {
        let root = FakeSnapshot(
            frame: screen,
            children: [
                FakeSnapshot(
                    elementType: .button,
                    identifier: "home.save",
                    label: "Save button",
                    frame: CGRect(x: 0, y: 0, width: 44, height: 44)
                )
            ]
        )

        let issues = SupplementalAuditScanner.issues(in: root, checks: .labelHygiene)

        XCTAssertEqual(issues.count, 1)
        XCTAssertEqual(issues.first?.auditType, "Label Hygiene")
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
            ["Target Size (Enhanced)", "Screen Title"]
        )
    }

    func testFlagsTextFieldCollectingPersonalDataAsInputPurpose() throws {
        let root = FakeSnapshot(
            frame: screen,
            children: [
                FakeSnapshot(
                    elementType: .textField,
                    identifier: "login.email",
                    label: "Email",
                    frame: CGRect(x: 0, y: 0, width: 320, height: 44)
                )
            ]
        )

        let issues = SupplementalAuditScanner.issues(in: root, checks: .inputPurpose)

        XCTAssertEqual(issues.count, 1)
        let issue = try XCTUnwrap(issues.first)
        XCTAssertEqual(issue.auditType, "Input Purpose")
        XCTAssertEqual(issue.elementIdentifier, "login.email")
    }

    func testInputPurposeIgnoresNonTextEntryElements() {
        // A button labelled "Email" is not an input field, so 1.3.5 does not
        // apply — only text and secure fields are collected.
        let root = FakeSnapshot(
            frame: screen,
            children: [
                FakeSnapshot(
                    elementType: .button,
                    identifier: "share.email",
                    label: "Email",
                    frame: CGRect(x: 0, y: 0, width: 44, height: 44)
                )
            ]
        )

        let issues = SupplementalAuditScanner.issues(in: root, checks: .inputPurpose)

        XCTAssertTrue(issues.isEmpty)
    }

    func testInputPurposeIgnoresSearchFields() {
        // Search content is a query, not information about the user; search
        // fields are excluded even when the label looks like a personal purpose.
        let root = FakeSnapshot(
            frame: screen,
            children: [
                FakeSnapshot(
                    elementType: .searchField,
                    identifier: "contacts.search",
                    label: "Email",
                    frame: CGRect(x: 0, y: 0, width: 320, height: 44)
                )
            ]
        )

        let issues = SupplementalAuditScanner.issues(in: root, checks: .inputPurpose)

        XCTAssertTrue(issues.isEmpty)
    }

    func testGraphicalInventoryCollectsImageElement() throws {
        let root = FakeSnapshot(
            frame: screen,
            children: [
                FakeSnapshot(
                    elementType: .image,
                    identifier: "home.logo",
                    label: "Logo",
                    frame: CGRect(x: 10, y: 10, width: 40, height: 40)
                )
            ]
        )

        let elements = SupplementalAuditScanner.graphicalElementInventory(in: root)

        XCTAssertEqual(elements.count, 1)
        XCTAssertEqual(try XCTUnwrap(elements.first).identifier, "home.logo")
    }

    func testGraphicalInventoryCollectsIconOnlyButton() {
        let root = FakeSnapshot(
            frame: screen,
            children: [
                FakeSnapshot(
                    elementType: .button,
                    identifier: "toolbar.share",
                    label: "Share",
                    frame: CGRect(x: 0, y: 0, width: 44, height: 44)
                )
            ]
        )

        let elements = SupplementalAuditScanner.graphicalElementInventory(in: root)

        XCTAssertEqual(elements.map(\.identifier), ["toolbar.share"])
    }

    func testGraphicalInventoryExcludesTextBearingButton() {
        // A button containing visible static text is a text control; its
        // contrast is the .contrast text audit's job, not 1.4.11.
        let root = FakeSnapshot(
            frame: screen,
            children: [
                FakeSnapshot(
                    elementType: .button,
                    identifier: "compose.send",
                    label: "Send",
                    frame: CGRect(x: 0, y: 0, width: 80, height: 44),
                    children: [
                        FakeSnapshot(
                            elementType: .staticText,
                            label: "Send",
                            frame: CGRect(x: 10, y: 10, width: 60, height: 24)
                        )
                    ]
                )
            ]
        )

        let elements = SupplementalAuditScanner.graphicalElementInventory(in: root)

        XCTAssertTrue(elements.isEmpty)
    }

    func testGraphicalInventoryExcludesDisabledElement() {
        let root = FakeSnapshot(
            frame: screen,
            children: [
                FakeSnapshot(
                    elementType: .image,
                    identifier: "home.logo",
                    label: "Logo",
                    frame: CGRect(x: 10, y: 10, width: 40, height: 40),
                    isEnabled: false
                )
            ]
        )

        let elements = SupplementalAuditScanner.graphicalElementInventory(in: root)

        XCTAssertTrue(elements.isEmpty)
    }

    func testGraphicalInventoryExcludesDisabledIconButton() {
        // Exercises the enabled guard on the icon-control branch (the disabled
        // case above only covers the .image branch).
        let root = FakeSnapshot(
            frame: screen,
            children: [
                FakeSnapshot(
                    elementType: .button,
                    identifier: "toolbar.share",
                    label: "Share",
                    frame: CGRect(x: 0, y: 0, width: 44, height: 44),
                    isEnabled: false
                )
            ]
        )

        let elements = SupplementalAuditScanner.graphicalElementInventory(in: root)

        XCTAssertTrue(elements.isEmpty)
    }

    func testGraphicalInventoryIgnoresElementsOutsideRootFrame() {
        let root = FakeSnapshot(
            frame: screen,
            children: [
                FakeSnapshot(
                    elementType: .image,
                    identifier: "offscreen.image",
                    label: "Off",
                    frame: CGRect(x: -1000, y: 10, width: 40, height: 40)
                )
            ]
        )

        let elements = SupplementalAuditScanner.graphicalElementInventory(in: root)

        XCTAssertTrue(elements.isEmpty)
    }
}
