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
}
