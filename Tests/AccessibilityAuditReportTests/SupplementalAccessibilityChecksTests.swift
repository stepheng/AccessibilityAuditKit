//
//  SupplementalAccessibilityChecksTests.swift
//  AccessibilityAuditReport
//
//  Created by Stephen Gurnett on 12/06/2026.
//

import AccessibilityAuditReport
import CoreGraphics
import XCTest

final class SupplementalAccessibilityChecksTests: XCTestCase {
    // MARK: - Target Size (WCAG 2.5.5)

    func testTargetSizeFlagsElementNarrowerThanMinimum() throws {
        let issues = SupplementalAccessibilityChecks.targetSizeIssues(
            interactiveElements: [
                AuditedElement(
                    identifier: "home.editButton",
                    label: "Edit",
                    frame: CGRect(x: 0, y: 0, width: 43, height: 44)
                )
            ]
        )

        XCTAssertEqual(issues.count, 1)
        let issue = try XCTUnwrap(issues.first)
        XCTAssertEqual(issue.auditType, "Target Size")
        XCTAssertEqual(issue.elementIdentifier, "home.editButton")
        XCTAssertEqual(issue.elementLabel, "Edit")
        XCTAssertEqual(issue.elementFrame, CGRect(x: 0, y: 0, width: 43, height: 44))
        XCTAssertTrue(issue.detailedDescription.contains("2.5.5"))
    }

    func testTargetSizeFlagsElementShorterThanMinimum() {
        let issues = SupplementalAccessibilityChecks.targetSizeIssues(
            interactiveElements: [
                AuditedElement(
                    identifier: "home.closeButton",
                    label: "Close",
                    frame: CGRect(x: 0, y: 0, width: 44, height: 43)
                )
            ]
        )

        XCTAssertEqual(issues.count, 1)
    }

    func testTargetSizePassesElementAtMinimum() {
        let issues = SupplementalAccessibilityChecks.targetSizeIssues(
            interactiveElements: [
                AuditedElement(
                    identifier: "home.editButton",
                    label: "Edit",
                    frame: CGRect(x: 0, y: 0, width: 44, height: 44)
                )
            ]
        )

        XCTAssertTrue(issues.isEmpty)
    }

    func testTargetSizeIgnoresZeroSizedFrames() {
        let issues = SupplementalAccessibilityChecks.targetSizeIssues(
            interactiveElements: [
                AuditedElement(identifier: "hidden", label: "", frame: .zero)
            ]
        )

        XCTAssertTrue(issues.isEmpty)
    }

    func testTargetSizeHonoursCustomMinimum() {
        let issues = SupplementalAccessibilityChecks.targetSizeIssues(
            interactiveElements: [
                AuditedElement(
                    identifier: "home.editButton",
                    label: "Edit",
                    frame: CGRect(x: 0, y: 0, width: 30, height: 30)
                )
            ],
            minimumDimension: 24
        )

        XCTAssertTrue(issues.isEmpty)
    }

    // MARK: - Target Spacing (WCAG 2.5.8)

    func testTargetSpacingFlagsOverlappingElements() throws {
        let issues = SupplementalAccessibilityChecks.targetSpacingIssues(
            interactiveElements: [
                AuditedElement(
                    identifier: "toolbar.share",
                    label: "Share",
                    frame: CGRect(x: 0, y: 0, width: 44, height: 44)
                ),
                AuditedElement(
                    identifier: "toolbar.delete",
                    label: "Delete",
                    frame: CGRect(x: 40, y: 0, width: 44, height: 44)
                )
            ]
        )

        XCTAssertEqual(issues.count, 1)
        let issue = try XCTUnwrap(issues.first)
        XCTAssertEqual(issue.auditType, "Target Spacing")
        XCTAssertEqual(issue.elementIdentifier, "toolbar.share")
        XCTAssertTrue(issue.detailedDescription.contains("toolbar.delete"))
        XCTAssertTrue(issue.detailedDescription.contains("2.5.8"))
    }

    func testTargetSpacingFlagsElementsCloserThanMinimumGap() {
        let issues = SupplementalAccessibilityChecks.targetSpacingIssues(
            interactiveElements: [
                AuditedElement(
                    identifier: "toolbar.share",
                    label: "Share",
                    frame: CGRect(x: 0, y: 0, width: 44, height: 44)
                ),
                AuditedElement(
                    identifier: "toolbar.delete",
                    label: "Delete",
                    frame: CGRect(x: 49, y: 0, width: 44, height: 44)
                )
            ]
        )

        XCTAssertEqual(issues.count, 1)
    }

    func testTargetSpacingFlagsDiagonalNeighboursCloserThanMinimumGap() {
        // Diagonal separation of hypot(4, 4) ≈ 5.66pt is under the 6pt minimum.
        let issues = SupplementalAccessibilityChecks.targetSpacingIssues(
            interactiveElements: [
                AuditedElement(
                    identifier: "grid.a",
                    label: "A",
                    frame: CGRect(x: 0, y: 0, width: 44, height: 44)
                ),
                AuditedElement(
                    identifier: "grid.b",
                    label: "B",
                    frame: CGRect(x: 48, y: 48, width: 44, height: 44)
                )
            ]
        )

        XCTAssertEqual(issues.count, 1)
    }

    func testTargetSpacingPassesElementsAtMinimumGap() {
        let issues = SupplementalAccessibilityChecks.targetSpacingIssues(
            interactiveElements: [
                AuditedElement(
                    identifier: "toolbar.share",
                    label: "Share",
                    frame: CGRect(x: 0, y: 0, width: 44, height: 44)
                ),
                AuditedElement(
                    identifier: "toolbar.delete",
                    label: "Delete",
                    frame: CGRect(x: 50, y: 0, width: 44, height: 44)
                )
            ]
        )

        XCTAssertTrue(issues.isEmpty)
    }

    func testTargetSpacingSkipsContainedElements() {
        // One frame fully containing another indicates a parent/child pair,
        // not two adjacent targets.
        let issues = SupplementalAccessibilityChecks.targetSpacingIssues(
            interactiveElements: [
                AuditedElement(
                    identifier: "card",
                    label: "Open card",
                    frame: CGRect(x: 0, y: 0, width: 200, height: 100)
                ),
                AuditedElement(
                    identifier: "card.favourite",
                    label: "Favourite",
                    frame: CGRect(x: 150, y: 28, width: 44, height: 44)
                )
            ]
        )

        XCTAssertTrue(issues.isEmpty)
    }

    func testTargetSpacingIgnoresZeroSizedFrames() {
        let issues = SupplementalAccessibilityChecks.targetSpacingIssues(
            interactiveElements: [
                AuditedElement(identifier: "hidden", label: "", frame: .zero),
                AuditedElement(
                    identifier: "toolbar.share",
                    label: "Share",
                    frame: CGRect(x: 0, y: 0, width: 44, height: 44)
                )
            ]
        )

        XCTAssertTrue(issues.isEmpty)
    }

    // MARK: - Screen Title (WCAG 2.4.2)

    func testScreenTitleFlagsEmptyNavigationBarTitle() throws {
        let issues = SupplementalAccessibilityChecks.screenTitleIssues(
            navigationBarTitles: ["  "]
        )

        XCTAssertEqual(issues.count, 1)
        let issue = try XCTUnwrap(issues.first)
        XCTAssertEqual(issue.auditType, "Screen Title")
        XCTAssertTrue(issue.detailedDescription.contains("2.4.2"))
    }

    func testScreenTitlePassesNonEmptyTitle() {
        let issues = SupplementalAccessibilityChecks.screenTitleIssues(
            navigationBarTitles: ["Photos"]
        )

        XCTAssertTrue(issues.isEmpty)
    }

    func testScreenTitlePassesWhenNoNavigationBarExists() {
        let issues = SupplementalAccessibilityChecks.screenTitleIssues(
            navigationBarTitles: []
        )

        XCTAssertTrue(issues.isEmpty)
    }

    // MARK: - Duplicate Labels (WCAG 2.4.6)

    func testDuplicateLabelsFlagsRepeatedInteractiveLabels() throws {
        let issues = SupplementalAccessibilityChecks.duplicateLabelIssues(
            interactiveElements: [
                AuditedElement(
                    identifier: "row1.edit",
                    label: "Edit",
                    frame: CGRect(x: 0, y: 0, width: 44, height: 44)
                ),
                AuditedElement(
                    identifier: "row2.edit",
                    label: "edit",
                    frame: CGRect(x: 0, y: 100, width: 44, height: 44)
                )
            ]
        )

        XCTAssertEqual(issues.count, 1)
        let issue = try XCTUnwrap(issues.first)
        XCTAssertEqual(issue.auditType, "Duplicate Labels")
        XCTAssertTrue(issue.detailedDescription.contains("row1.edit"))
        XCTAssertTrue(issue.detailedDescription.contains("row2.edit"))
        XCTAssertTrue(issue.detailedDescription.contains("2.4.6"))
    }

    func testDuplicateLabelsPassesUniqueLabels() {
        let issues = SupplementalAccessibilityChecks.duplicateLabelIssues(
            interactiveElements: [
                AuditedElement(
                    identifier: "toolbar.share",
                    label: "Share",
                    frame: CGRect(x: 0, y: 0, width: 44, height: 44)
                ),
                AuditedElement(
                    identifier: "toolbar.delete",
                    label: "Delete",
                    frame: CGRect(x: 50, y: 0, width: 44, height: 44)
                )
            ]
        )

        XCTAssertTrue(issues.isEmpty)
    }

    func testDuplicateLabelsIgnoresEmptyLabels() {
        let issues = SupplementalAccessibilityChecks.duplicateLabelIssues(
            interactiveElements: [
                AuditedElement(identifier: "a", label: "", frame: CGRect(x: 0, y: 0, width: 44, height: 44)),
                AuditedElement(identifier: "b", label: " ", frame: CGRect(x: 0, y: 50, width: 44, height: 44))
            ]
        )

        XCTAssertTrue(issues.isEmpty)
    }

    // MARK: - Generic Labels (WCAG 2.4.4)

    func testGenericLabelFlagsPureRoleWord() throws {
        let issues = SupplementalAccessibilityChecks.genericLabelIssues(
            interactiveElements: [
                AuditedElement(
                    identifier: "home.action",
                    label: "Button",
                    frame: CGRect(x: 0, y: 0, width: 44, height: 44)
                )
            ]
        )

        XCTAssertEqual(issues.count, 1)
        let issue = try XCTUnwrap(issues.first)
        XCTAssertEqual(issue.auditType, "Generic Label")
        XCTAssertEqual(issue.elementIdentifier, "home.action")
        XCTAssertTrue(issue.detailedDescription.contains("2.4.4"))
    }

    func testGenericLabelFlagsGenericPhraseCaseInsensitively() {
        let issues = SupplementalAccessibilityChecks.genericLabelIssues(
            interactiveElements: [
                AuditedElement(
                    identifier: "home.action",
                    label: "Tap Here",
                    frame: CGRect(x: 0, y: 0, width: 44, height: 44)
                )
            ]
        )

        XCTAssertEqual(issues.count, 1)
    }

    func testGenericLabelFlagsImageFilename() {
        let issues = SupplementalAccessibilityChecks.genericLabelIssues(
            interactiveElements: [
                AuditedElement(
                    identifier: "gallery.thumb",
                    label: "IMG_0123.png",
                    frame: CGRect(x: 0, y: 0, width: 44, height: 44)
                )
            ]
        )

        XCTAssertEqual(issues.count, 1)
    }

    func testGenericLabelFlagsAssetNamePrefix() {
        let issues = SupplementalAccessibilityChecks.genericLabelIssues(
            interactiveElements: [
                AuditedElement(
                    identifier: "toolbar.next",
                    label: "ic_chevron",
                    frame: CGRect(x: 0, y: 0, width: 44, height: 44)
                )
            ]
        )

        XCTAssertEqual(issues.count, 1)
    }

    func testGenericLabelPassesDescriptiveLabel() {
        let issues = SupplementalAccessibilityChecks.genericLabelIssues(
            interactiveElements: [
                AuditedElement(
                    identifier: "compose.send",
                    label: "Send message",
                    frame: CGRect(x: 0, y: 0, width: 44, height: 44)
                )
            ]
        )

        XCTAssertTrue(issues.isEmpty)
    }

    func testGenericLabelPassesPhraseContainingRoleWord() {
        // Only labels that are entirely generic flag; a role word inside a
        // descriptive phrase is fine.
        let issues = SupplementalAccessibilityChecks.genericLabelIssues(
            interactiveElements: [
                AuditedElement(
                    identifier: "board.add",
                    label: "Add button to board",
                    frame: CGRect(x: 0, y: 0, width: 44, height: 44)
                )
            ]
        )

        XCTAssertTrue(issues.isEmpty)
    }

    func testGenericLabelIgnoresEmptyLabels() {
        // Missing labels are already covered by Apple's
        // sufficientElementDescription audit.
        let issues = SupplementalAccessibilityChecks.genericLabelIssues(
            interactiveElements: [
                AuditedElement(
                    identifier: "home.action",
                    label: " ",
                    frame: CGRect(x: 0, y: 0, width: 44, height: 44)
                )
            ]
        )

        XCTAssertTrue(issues.isEmpty)
    }

    // MARK: - Label in Name (WCAG 2.5.3)

    func testLabelInNameFlagsLabelMissingVisibleText() throws {
        let issues = SupplementalAccessibilityChecks.labelInNameIssues(
            interactiveElements: [
                AuditedElement(
                    identifier: "compose.send",
                    label: "submit_btn",
                    frame: CGRect(x: 0, y: 0, width: 44, height: 44),
                    visibleTextLabels: ["Send"]
                )
            ]
        )

        XCTAssertEqual(issues.count, 1)
        let issue = try XCTUnwrap(issues.first)
        XCTAssertEqual(issue.auditType, "Label in Name")
        XCTAssertEqual(issue.elementIdentifier, "compose.send")
        XCTAssertTrue(issue.detailedDescription.contains("Send"))
        XCTAssertTrue(issue.detailedDescription.contains("2.5.3"))
    }

    func testLabelInNameFlagsEmptyLabelWithVisibleText() {
        let issues = SupplementalAccessibilityChecks.labelInNameIssues(
            interactiveElements: [
                AuditedElement(
                    identifier: "compose.send",
                    label: "",
                    frame: CGRect(x: 0, y: 0, width: 44, height: 44),
                    visibleTextLabels: ["Send"]
                )
            ]
        )

        XCTAssertEqual(issues.count, 1)
    }

    func testLabelInNamePassesLabelContainingVisibleText() {
        let issues = SupplementalAccessibilityChecks.labelInNameIssues(
            interactiveElements: [
                AuditedElement(
                    identifier: "compose.send",
                    label: "Send message",
                    frame: CGRect(x: 0, y: 0, width: 44, height: 44),
                    visibleTextLabels: ["Send"]
                )
            ]
        )

        XCTAssertTrue(issues.isEmpty)
    }

    func testLabelInNameMatchesCaseInsensitively() {
        let issues = SupplementalAccessibilityChecks.labelInNameIssues(
            interactiveElements: [
                AuditedElement(
                    identifier: "compose.send",
                    label: "send",
                    frame: CGRect(x: 0, y: 0, width: 44, height: 44),
                    visibleTextLabels: ["Send"]
                )
            ]
        )

        XCTAssertTrue(issues.isEmpty)
    }

    func testLabelInNamePassesWhenAnyVisibleTextMatches() {
        // A composite control can show several pieces of text; the accessible
        // label only needs to include one of them to be speakable.
        let issues = SupplementalAccessibilityChecks.labelInNameIssues(
            interactiveElements: [
                AuditedElement(
                    identifier: "compose.send",
                    label: "Send",
                    frame: CGRect(x: 0, y: 0, width: 44, height: 44),
                    visibleTextLabels: ["Send", "to John"]
                )
            ]
        )

        XCTAssertTrue(issues.isEmpty)
    }

    func testLabelInNameIgnoresElementsWithoutVisibleText() {
        let issues = SupplementalAccessibilityChecks.labelInNameIssues(
            interactiveElements: [
                AuditedElement(
                    identifier: "toolbar.share",
                    label: "Share",
                    frame: CGRect(x: 0, y: 0, width: 44, height: 44)
                )
            ]
        )

        XCTAssertTrue(issues.isEmpty)
    }

    func testLabelInNameIgnoresWhitespaceOnlyVisibleText() {
        let issues = SupplementalAccessibilityChecks.labelInNameIssues(
            interactiveElements: [
                AuditedElement(
                    identifier: "toolbar.share",
                    label: "Share",
                    frame: CGRect(x: 0, y: 0, width: 44, height: 44),
                    visibleTextLabels: ["  "]
                )
            ]
        )

        XCTAssertTrue(issues.isEmpty)
    }

    // MARK: - Adjustable Value (WCAG 4.1.2)

    func testAdjustableValueFlagsMissingValue() throws {
        let issues = SupplementalAccessibilityChecks.adjustableValueIssues(
            adjustableElements: [
                AuditedElement(
                    identifier: "player.volume",
                    label: "Volume",
                    frame: CGRect(x: 0, y: 0, width: 200, height: 44)
                )
            ]
        )

        XCTAssertEqual(issues.count, 1)
        let issue = try XCTUnwrap(issues.first)
        XCTAssertEqual(issue.auditType, "Adjustable Value")
        XCTAssertEqual(issue.elementIdentifier, "player.volume")
        XCTAssertTrue(issue.detailedDescription.contains("4.1.2"))
    }

    func testAdjustableValueFlagsEmptyValue() {
        let issues = SupplementalAccessibilityChecks.adjustableValueIssues(
            adjustableElements: [
                AuditedElement(
                    identifier: "player.volume",
                    label: "Volume",
                    frame: CGRect(x: 0, y: 0, width: 200, height: 44),
                    value: " "
                )
            ]
        )

        XCTAssertEqual(issues.count, 1)
    }

    func testAdjustableValuePassesElementExposingValue() {
        let issues = SupplementalAccessibilityChecks.adjustableValueIssues(
            adjustableElements: [
                AuditedElement(
                    identifier: "player.volume",
                    label: "Volume",
                    frame: CGRect(x: 0, y: 0, width: 200, height: 44),
                    value: "50%"
                )
            ]
        )

        XCTAssertTrue(issues.isEmpty)
    }

    // MARK: - Consistent Identification (WCAG 3.2.4)

    func testConsistentIdentificationFlagsSameIdentifierWithDifferentLabels() throws {
        let issues = SupplementalAccessibilityChecks.consistentIdentificationIssues(
            screens: [
                AuditedScreenElements(
                    screenName: "Home",
                    elements: [
                        AuditedElement(
                            identifier: "tab.photos",
                            label: "Photos",
                            frame: CGRect(x: 0, y: 0, width: 44, height: 44)
                        )
                    ]
                ),
                AuditedScreenElements(
                    screenName: "Files",
                    elements: [
                        AuditedElement(
                            identifier: "tab.photos",
                            label: "Pictures",
                            frame: CGRect(x: 0, y: 0, width: 44, height: 44)
                        )
                    ]
                )
            ]
        )

        XCTAssertEqual(issues.count, 1)
        let issue = try XCTUnwrap(issues.first)
        XCTAssertEqual(issue.auditType, "Consistent Identification")
        XCTAssertEqual(issue.elementIdentifier, "tab.photos")
        XCTAssertTrue(issue.detailedDescription.contains("Photos"))
        XCTAssertTrue(issue.detailedDescription.contains("Pictures"))
        XCTAssertTrue(issue.detailedDescription.contains("Home"))
        XCTAssertTrue(issue.detailedDescription.contains("Files"))
        XCTAssertTrue(issue.detailedDescription.contains("3.2.4"))
    }

    func testConsistentIdentificationPassesMatchingLabels() {
        let issues = SupplementalAccessibilityChecks.consistentIdentificationIssues(
            screens: [
                AuditedScreenElements(
                    screenName: "Home",
                    elements: [
                        AuditedElement(
                            identifier: "tab.photos",
                            label: "Photos",
                            frame: CGRect(x: 0, y: 0, width: 44, height: 44)
                        )
                    ]
                ),
                AuditedScreenElements(
                    screenName: "Files",
                    elements: [
                        AuditedElement(
                            identifier: "tab.photos",
                            label: "Photos",
                            frame: CGRect(x: 0, y: 0, width: 44, height: 44)
                        )
                    ]
                )
            ]
        )

        XCTAssertTrue(issues.isEmpty)
    }

    func testConsistentIdentificationNormalisesCaseAndWhitespace() {
        let issues = SupplementalAccessibilityChecks.consistentIdentificationIssues(
            screens: [
                AuditedScreenElements(
                    screenName: "Home",
                    elements: [
                        AuditedElement(
                            identifier: "toolbar.edit",
                            label: "Edit",
                            frame: CGRect(x: 0, y: 0, width: 44, height: 44)
                        )
                    ]
                ),
                AuditedScreenElements(
                    screenName: "Files",
                    elements: [
                        AuditedElement(
                            identifier: "toolbar.edit",
                            label: " edit ",
                            frame: CGRect(x: 0, y: 0, width: 44, height: 44)
                        )
                    ]
                )
            ]
        )

        XCTAssertTrue(issues.isEmpty)
    }

    func testConsistentIdentificationIgnoresEmptyIdentifiers() {
        let issues = SupplementalAccessibilityChecks.consistentIdentificationIssues(
            screens: [
                AuditedScreenElements(
                    screenName: "Home",
                    elements: [
                        AuditedElement(
                            identifier: "",
                            label: "Photos",
                            frame: CGRect(x: 0, y: 0, width: 44, height: 44)
                        )
                    ]
                ),
                AuditedScreenElements(
                    screenName: "Files",
                    elements: [
                        AuditedElement(
                            identifier: "",
                            label: "Pictures",
                            frame: CGRect(x: 0, y: 0, width: 44, height: 44)
                        )
                    ]
                )
            ]
        )

        XCTAssertTrue(issues.isEmpty)
    }

    func testConsistentIdentificationIgnoresEmptyLabels() {
        // A missing label is a sufficientElementDescription failure, not an
        // inconsistency between screens.
        let issues = SupplementalAccessibilityChecks.consistentIdentificationIssues(
            screens: [
                AuditedScreenElements(
                    screenName: "Home",
                    elements: [
                        AuditedElement(
                            identifier: "tab.photos",
                            label: "Photos",
                            frame: CGRect(x: 0, y: 0, width: 44, height: 44)
                        )
                    ]
                ),
                AuditedScreenElements(
                    screenName: "Files",
                    elements: [
                        AuditedElement(
                            identifier: "tab.photos",
                            label: "",
                            frame: CGRect(x: 0, y: 0, width: 44, height: 44)
                        )
                    ]
                )
            ]
        )

        XCTAssertTrue(issues.isEmpty)
    }

    // MARK: - Orientation (WCAG 1.3.4)

    func testOrientationFlagsLayoutUnchangedAfterRotation() throws {
        let issues = SupplementalAccessibilityChecks.orientationLockIssues(
            portraitWindowSize: CGSize(width: 402, height: 874),
            landscapeWindowSize: CGSize(width: 402, height: 874)
        )

        XCTAssertEqual(issues.count, 1)
        let issue = try XCTUnwrap(issues.first)
        XCTAssertEqual(issue.auditType, "Orientation")
        XCTAssertTrue(issue.detailedDescription.contains("1.3.4"))
        XCTAssertNil(issue.elementFrame)
    }

    func testOrientationFlagsLandscapeWindowStillTallerThanWide() {
        // The window resized but stayed portrait-proportioned, so the layout
        // did not adopt the landscape orientation.
        let issues = SupplementalAccessibilityChecks.orientationLockIssues(
            portraitWindowSize: CGSize(width: 402, height: 874),
            landscapeWindowSize: CGSize(width: 402, height: 800)
        )

        XCTAssertEqual(issues.count, 1)
    }

    func testOrientationPassesWhenLayoutRotates() {
        let issues = SupplementalAccessibilityChecks.orientationLockIssues(
            portraitWindowSize: CGSize(width: 402, height: 874),
            landscapeWindowSize: CGSize(width: 874, height: 402)
        )

        XCTAssertTrue(issues.isEmpty)
    }

    func testOrientationSkipsWhenPortraitWindowIsNotPortrait() {
        // If the window was not taller than wide before rotating, the
        // comparison is inconclusive (for example iPad multitasking).
        let issues = SupplementalAccessibilityChecks.orientationLockIssues(
            portraitWindowSize: CGSize(width: 874, height: 402),
            landscapeWindowSize: CGSize(width: 874, height: 402)
        )

        XCTAssertTrue(issues.isEmpty)
    }

    func testOrientationSkipsZeroSizedWindows() {
        let issues = SupplementalAccessibilityChecks.orientationLockIssues(
            portraitWindowSize: .zero,
            landscapeWindowSize: .zero
        )

        XCTAssertTrue(issues.isEmpty)
    }
}
