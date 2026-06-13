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
    // MARK: - Target Size (WCAG 2.5.8 Minimum / 2.5.5 Enhanced)

    func testTargetSizeFlagsElementBelowMinimumAsAAFailure() throws {
        let issues = SupplementalAccessibilityChecks.targetSizeIssues(
            interactiveElements: [
                AuditedElement(
                    identifier: "footer.legal",
                    label: "Legal",
                    frame: CGRect(x: 0, y: 0, width: 20, height: 20)
                )
            ]
        )

        XCTAssertEqual(issues.count, 1)
        let issue = try XCTUnwrap(issues.first)
        XCTAssertEqual(issue.auditType, "Target Size (Minimum)")
        XCTAssertEqual(issue.elementIdentifier, "footer.legal")
        XCTAssertEqual(issue.elementLabel, "Legal")
        XCTAssertEqual(issue.elementFrame, CGRect(x: 0, y: 0, width: 20, height: 20))
        XCTAssertTrue(issue.detailedDescription.contains("2.5.8"))
        XCTAssertEqual(issue.severity, .error)
    }

    func testTargetSizeFlagsElementShortInOneDimensionAsAAFailure() throws {
        let issues = SupplementalAccessibilityChecks.targetSizeIssues(
            interactiveElements: [
                AuditedElement(
                    identifier: "home.search",
                    label: "Search",
                    frame: CGRect(x: 0, y: 0, width: 354, height: 22)
                )
            ]
        )

        XCTAssertEqual(issues.count, 1)
        let issue = try XCTUnwrap(issues.first)
        XCTAssertEqual(issue.auditType, "Target Size (Minimum)")
        XCTAssertTrue(issue.detailedDescription.contains("2.5.8"))
    }

    func testTargetSizeFlagsElementBetweenMinimumAndEnhancedAsAAAOnly() throws {
        let issues = SupplementalAccessibilityChecks.targetSizeIssues(
            interactiveElements: [
                AuditedElement(
                    identifier: "home.editButton",
                    label: "Edit",
                    frame: CGRect(x: 0, y: 0, width: 30, height: 30)
                )
            ]
        )

        XCTAssertEqual(issues.count, 1)
        let issue = try XCTUnwrap(issues.first)
        XCTAssertEqual(issue.auditType, "Target Size (Enhanced)")
        XCTAssertTrue(issue.detailedDescription.contains("2.5.5"))
        XCTAssertEqual(issue.severity, .warning)
    }

    func testTargetSizeEmitsOneIssuePerElementAtWorstLevel() {
        // A 20×20 element fails both 24pt and 44pt thresholds but is reported
        // once, at the more severe AA level.
        let issues = SupplementalAccessibilityChecks.targetSizeIssues(
            interactiveElements: [
                AuditedElement(
                    identifier: "footer.legal",
                    label: "Legal",
                    frame: CGRect(x: 0, y: 0, width: 20, height: 20)
                )
            ]
        )

        XCTAssertEqual(issues.count, 1)
        XCTAssertEqual(issues.first?.auditType, "Target Size (Minimum)")
    }

    func testTargetSizePassesElementAtEnhancedMinimum() {
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

    // MARK: - Target Spacing (WCAG 2.5.8)

    func testTargetSpacingFlagsUndersizedTargetTouchingNeighbour() throws {
        // A 20×20 target is undersized; its 24pt spacing circle (radius 12)
        // overlaps the adjacent well-sized target.
        let issues = SupplementalAccessibilityChecks.targetSpacingIssues(
            interactiveElements: [
                AuditedElement(
                    identifier: "toolbar.share",
                    label: "Share",
                    frame: CGRect(x: 0, y: 0, width: 20, height: 20)
                ),
                AuditedElement(
                    identifier: "toolbar.delete",
                    label: "Delete",
                    frame: CGRect(x: 20, y: 0, width: 44, height: 44)
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

    func testTargetSpacingSkipsWellSizedNeighbours() {
        // Both targets meet the 24×24pt minimum, so 2.5.8's spacing exception
        // does not apply even when they touch — the stacked-rows false positive.
        let issues = SupplementalAccessibilityChecks.targetSpacingIssues(
            interactiveElements: [
                AuditedElement(
                    identifier: "list.row1",
                    label: "Row 1",
                    frame: CGRect(x: 0, y: 0, width: 320, height: 44)
                ),
                AuditedElement(
                    identifier: "list.row2",
                    label: "Row 2",
                    frame: CGRect(x: 0, y: 44, width: 320, height: 44)
                )
            ]
        )

        XCTAssertTrue(issues.isEmpty)
    }

    func testTargetSpacingSkipsOverlappingWellSizedTargets() {
        // Overlap of two well-sized targets is out of 2.5.8 scope; Apple's
        // hit-region audit covers genuinely unhittable overlaps.
        let issues = SupplementalAccessibilityChecks.targetSpacingIssues(
            interactiveElements: [
                AuditedElement(
                    identifier: "a",
                    label: "A",
                    frame: CGRect(x: 0, y: 0, width: 44, height: 44)
                ),
                AuditedElement(
                    identifier: "b",
                    label: "B",
                    frame: CGRect(x: 40, y: 0, width: 44, height: 44)
                )
            ]
        )

        XCTAssertTrue(issues.isEmpty)
    }

    func testTargetSpacingFlagsTwoUndersizedTargetsWithIntersectingCircles() {
        // Centres are 22pt apart — under the 24pt sum of the two radius-12
        // spacing circles — so the circles intersect.
        let issues = SupplementalAccessibilityChecks.targetSpacingIssues(
            interactiveElements: [
                AuditedElement(
                    identifier: "grid.a",
                    label: "A",
                    frame: CGRect(x: 0, y: 0, width: 20, height: 20)
                ),
                AuditedElement(
                    identifier: "grid.b",
                    label: "B",
                    frame: CGRect(x: 22, y: 0, width: 20, height: 20)
                )
            ]
        )

        XCTAssertEqual(issues.count, 1)
    }

    func testTargetSpacingPassesUndersizedTargetsWithSufficientSeparation() {
        // Centres are 40pt apart; neither spacing circle reaches the other
        // target or circle.
        let issues = SupplementalAccessibilityChecks.targetSpacingIssues(
            interactiveElements: [
                AuditedElement(
                    identifier: "grid.a",
                    label: "A",
                    frame: CGRect(x: 0, y: 0, width: 20, height: 20)
                ),
                AuditedElement(
                    identifier: "grid.b",
                    label: "B",
                    frame: CGRect(x: 40, y: 0, width: 20, height: 20)
                )
            ]
        )

        XCTAssertTrue(issues.isEmpty)
    }

    func testTargetSpacingSkipsContainedElements() {
        // One frame fully containing another indicates a parent/child pair,
        // not two adjacent targets — even when the inner one is undersized.
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
                    frame: CGRect(x: 150, y: 28, width: 20, height: 20)
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
                    frame: CGRect(x: 0, y: 0, width: 20, height: 20)
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

    func testGenericLabelFlagsLabelEqualToIdentifier() throws {
        let issues = SupplementalAccessibilityChecks.genericLabelIssues(
            interactiveElements: [
                AuditedElement(
                    identifier: "files.backupStatus",
                    label: "files.backupStatus",
                    frame: CGRect(x: 0, y: 0, width: 44, height: 44)
                )
            ]
        )

        XCTAssertEqual(issues.count, 1)
        XCTAssertEqual(issues.first?.auditType, "Generic Label")
    }

    func testGenericLabelFlagsSnakeCaseLabel() {
        let issues = SupplementalAccessibilityChecks.genericLabelIssues(
            interactiveElements: [
                AuditedElement(
                    identifier: "files.status",
                    label: "backup_status",
                    frame: CGRect(x: 0, y: 0, width: 44, height: 44)
                )
            ]
        )

        XCTAssertEqual(issues.count, 1)
    }

    func testGenericLabelFlagsCamelCaseLabel() {
        let issues = SupplementalAccessibilityChecks.genericLabelIssues(
            interactiveElements: [
                AuditedElement(
                    identifier: "files.status",
                    label: "backupStatus",
                    frame: CGRect(x: 0, y: 0, width: 44, height: 44)
                )
            ]
        )

        XCTAssertEqual(issues.count, 1)
    }

    func testGenericLabelFlagsDottedSymbolName() {
        let issues = SupplementalAccessibilityChecks.genericLabelIssues(
            interactiveElements: [
                AuditedElement(
                    identifier: "toolbar.next",
                    label: "chevron.right",
                    frame: CGRect(x: 0, y: 0, width: 44, height: 44)
                )
            ]
        )

        XCTAssertEqual(issues.count, 1)
    }

    func testGenericLabelFlagsSymbolOnlyLabel() {
        let issues = SupplementalAccessibilityChecks.genericLabelIssues(
            interactiveElements: [
                AuditedElement(
                    identifier: "toolbar.favourite",
                    label: "★",
                    frame: CGRect(x: 0, y: 0, width: 44, height: 44)
                )
            ]
        )

        XCTAssertEqual(issues.count, 1)
    }

    func testGenericLabelEmitsOneIssueForLabelMatchingSeveralRules() {
        // "ic_chevron" is both an asset-name prefix and snake_case; the
        // element should still produce a single issue.
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

    func testGenericLabelPassesSingleWordWithDigits() {
        let issues = SupplementalAccessibilityChecks.genericLabelIssues(
            interactiveElements: [
                AuditedElement(
                    identifier: "pager.page2",
                    label: "2",
                    frame: CGRect(x: 0, y: 0, width: 44, height: 44)
                )
            ]
        )

        XCTAssertTrue(issues.isEmpty)
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

    // MARK: - Label Hygiene (WCAG 4.1.2)

    func testLabelHygieneFlagsRedundantRoleSuffix() throws {
        let issues = SupplementalAccessibilityChecks.labelHygieneIssues(
            interactiveElements: [
                AuditedElement(
                    identifier: "home.save",
                    label: "Save button",
                    frame: CGRect(x: 0, y: 0, width: 44, height: 44)
                )
            ]
        )

        XCTAssertEqual(issues.count, 1)
        let issue = try XCTUnwrap(issues.first)
        XCTAssertEqual(issue.auditType, "Label Hygiene")
        XCTAssertEqual(issue.elementIdentifier, "home.save")
        XCTAssertTrue(issue.detailedDescription.contains("button"))
        XCTAssertTrue(issue.detailedDescription.contains("4.1.2"))
    }

    func testLabelHygieneFlagsRoleSuffixCaseInsensitively() {
        let issues = SupplementalAccessibilityChecks.labelHygieneIssues(
            interactiveElements: [
                AuditedElement(
                    identifier: "home.photos",
                    label: "Photos Tab",
                    frame: CGRect(x: 0, y: 0, width: 44, height: 44)
                )
            ]
        )

        XCTAssertEqual(issues.count, 1)
    }

    func testLabelHygienePassesLoneRoleWord() {
        // A label that is nothing but a role word is a Generic Label issue;
        // hygiene only flags the redundant suffix on otherwise-useful labels.
        let issues = SupplementalAccessibilityChecks.labelHygieneIssues(
            interactiveElements: [
                AuditedElement(
                    identifier: "home.action",
                    label: "Button",
                    frame: CGRect(x: 0, y: 0, width: 44, height: 44)
                )
            ]
        )

        XCTAssertTrue(issues.isEmpty)
    }

    func testLabelHygieneFlagsUntrimmedWhitespace() throws {
        let issues = SupplementalAccessibilityChecks.labelHygieneIssues(
            interactiveElements: [
                AuditedElement(
                    identifier: "compose.send",
                    label: "Send ",
                    frame: CGRect(x: 0, y: 0, width: 44, height: 44)
                )
            ]
        )

        XCTAssertEqual(issues.count, 1)
        XCTAssertEqual(issues.first?.auditType, "Label Hygiene")
    }

    func testLabelHygieneFlagsAllCapsMultiWordLabel() {
        let issues = SupplementalAccessibilityChecks.labelHygieneIssues(
            interactiveElements: [
                AuditedElement(
                    identifier: "home.save",
                    label: "SAVE CAPSULE",
                    frame: CGRect(x: 0, y: 0, width: 120, height: 44)
                )
            ]
        )

        XCTAssertEqual(issues.count, 1)
    }

    func testLabelHygieneFlagsLongAllCapsWord() {
        let issues = SupplementalAccessibilityChecks.labelHygieneIssues(
            interactiveElements: [
                AuditedElement(
                    identifier: "files.delete",
                    label: "DELETE",
                    frame: CGRect(x: 0, y: 0, width: 80, height: 44)
                )
            ]
        )

        XCTAssertEqual(issues.count, 1)
    }

    func testLabelHygienePassesShortAcronyms() {
        let issues = SupplementalAccessibilityChecks.labelHygieneIssues(
            interactiveElements: [
                AuditedElement(
                    identifier: "alert.ok",
                    label: "OK",
                    frame: CGRect(x: 0, y: 0, width: 44, height: 44)
                ),
                AuditedElement(
                    identifier: "files.export",
                    label: "PDF",
                    frame: CGRect(x: 50, y: 0, width: 44, height: 44)
                )
            ]
        )

        XCTAssertTrue(issues.isEmpty)
    }

    func testLabelHygieneReportsEachProblemSeparately() {
        let issues = SupplementalAccessibilityChecks.labelHygieneIssues(
            interactiveElements: [
                AuditedElement(
                    identifier: "home.save",
                    label: "Save button ",
                    frame: CGRect(x: 0, y: 0, width: 44, height: 44)
                )
            ]
        )

        XCTAssertEqual(issues.count, 2)
    }

    func testLabelHygienePassesCleanLabelAndIgnoresEmptyLabels() {
        let issues = SupplementalAccessibilityChecks.labelHygieneIssues(
            interactiveElements: [
                AuditedElement(
                    identifier: "compose.send",
                    label: "Send message",
                    frame: CGRect(x: 0, y: 0, width: 44, height: 44)
                ),
                AuditedElement(
                    identifier: "hidden",
                    label: "",
                    frame: CGRect(x: 0, y: 50, width: 44, height: 44)
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

    // MARK: - Missing Element Description (WCAG 4.1.2 / 1.1.1)

    func testMissingElementDescriptionFlagsRequiredEmptyLabelAsError() throws {
        let issues = SupplementalAccessibilityChecks.missingElementDescriptionIssues(
            elements: [
                AuditedElement(
                    identifier: "home.profile",
                    label: "",
                    frame: CGRect(x: 0, y: 0, width: 44, height: 44),
                    requiresDescription: true
                )
            ]
        )

        XCTAssertEqual(issues.count, 1)
        let issue = try XCTUnwrap(issues.first)
        XCTAssertEqual(issue.auditType, "Element Description")
        XCTAssertEqual(issue.elementIdentifier, "home.profile")
        XCTAssertEqual(issue.severity, .error)
    }

    func testMissingElementDescriptionTreatsWhitespaceLabelAsEmpty() {
        let issues = SupplementalAccessibilityChecks.missingElementDescriptionIssues(
            elements: [
                AuditedElement(
                    identifier: "x",
                    label: "   ",
                    frame: CGRect(x: 0, y: 0, width: 44, height: 44),
                    requiresDescription: true
                )
            ]
        )
        XCTAssertEqual(issues.count, 1)
    }

    func testMissingElementDescriptionIgnoresElementsNotRequiringDescription() {
        let issues = SupplementalAccessibilityChecks.missingElementDescriptionIssues(
            elements: [
                AuditedElement(
                    identifier: "label.title",
                    label: "",
                    frame: CGRect(x: 0, y: 0, width: 100, height: 20),
                    requiresDescription: false
                )
            ]
        )
        XCTAssertTrue(issues.isEmpty)
    }

    func testMissingElementDescriptionPassesLabelledElement() {
        let issues = SupplementalAccessibilityChecks.missingElementDescriptionIssues(
            elements: [
                AuditedElement(
                    identifier: "x",
                    label: "Profile",
                    frame: CGRect(x: 0, y: 0, width: 44, height: 44),
                    requiresDescription: true
                )
            ]
        )
        XCTAssertTrue(issues.isEmpty)
    }

    func testMissingElementDescriptionFlagsOnlyTheRequiredUnlabelledElementInAMixedArray() {
        let issues = SupplementalAccessibilityChecks.missingElementDescriptionIssues(
            elements: [
                AuditedElement(identifier: "needs.it", label: "", frame: CGRect(x: 0, y: 0, width: 44, height: 44), requiresDescription: true),
                AuditedElement(identifier: "labelled", label: "Save", frame: CGRect(x: 0, y: 0, width: 44, height: 44), requiresDescription: true),
                AuditedElement(identifier: "static.text", label: "", frame: CGRect(x: 0, y: 0, width: 80, height: 20), requiresDescription: false)
            ]
        )
        XCTAssertEqual(issues.count, 1)
        XCTAssertEqual(issues.first?.elementIdentifier, "needs.it")
    }
}
