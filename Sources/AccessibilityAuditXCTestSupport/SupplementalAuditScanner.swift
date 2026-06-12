//
//  SupplementalAuditScanner.swift
//  AccessibilityAuditReport
//
//  Created by Stephen Gurnett on 12/06/2026.
//

import AccessibilityAuditReport
import Foundation
import XCTest

public struct SupplementalAuditType: OptionSet, Sendable {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let targetSize = SupplementalAuditType(rawValue: 1 << 0)
    public static let targetSpacing = SupplementalAuditType(rawValue: 1 << 1)
    public static let screenTitle = SupplementalAuditType(rawValue: 1 << 2)
    public static let duplicateLabels = SupplementalAuditType(rawValue: 1 << 3)
    public static let labelInName = SupplementalAuditType(rawValue: 1 << 4)
    public static let genericLabels = SupplementalAuditType(rawValue: 1 << 5)
    public static let adjustableValue = SupplementalAuditType(rawValue: 1 << 6)
    /// Cross-screen check: collects each screen's interactive elements into
    /// the report's inventory; produces no per-screen issues. Call
    /// `recordConsistentIdentificationCheck` on the report after the last
    /// screen to evaluate it.
    public static let consistentIdentification = SupplementalAuditType(rawValue: 1 << 7)
    public static let labelHygiene = SupplementalAuditType(rawValue: 1 << 8)

    public static let all: SupplementalAuditType = [
        .targetSize, .targetSpacing, .screenTitle, .duplicateLabels,
        .labelInName, .genericLabels, .adjustableValue, .consistentIdentification,
        .labelHygiene
    ]
}

public enum SupplementalAuditScanner {
    /// Element types treated as interactive targets for size, spacing, and
    /// duplicate-label checks.
    static let interactiveElementTypes: Set<XCUIElement.ElementType> = [
        .button, .checkBox, .radioButton, .switch, .toggle, .slider,
        .stepper, .segmentedControl, .link, .menuItem,
        .textField, .secureTextField, .searchField
    ]

    /// Element types expected to expose an accessibility value describing
    /// their current state. Steppers and segmented controls are excluded:
    /// they convey state through child buttons, not a value.
    static let adjustableElementTypes: Set<XCUIElement.ElementType> = [
        .slider, .picker, .pickerWheel
    ]

    public static func issues(
        in snapshot: any XCUIElementSnapshot,
        checks: SupplementalAuditType
    ) -> [Issue] {
        var issues: [Issue] = []
        let needsInteractive = !checks.isDisjoint(with: [
            .targetSize, .targetSpacing, .duplicateLabels, .labelInName,
            .genericLabels, .labelHygiene
        ])
        let interactive = needsInteractive
            ? interactiveElements(in: snapshot, within: snapshot.frame)
            : []

        if checks.contains(.targetSize) {
            issues += SupplementalAccessibilityChecks.targetSizeIssues(interactiveElements: interactive)
        }
        if checks.contains(.targetSpacing) {
            issues += SupplementalAccessibilityChecks.targetSpacingIssues(interactiveElements: interactive)
        }
        if checks.contains(.screenTitle) {
            issues += SupplementalAccessibilityChecks.screenTitleIssues(
                navigationBarTitles: navigationBarTitles(in: snapshot)
            )
        }
        if checks.contains(.duplicateLabels) {
            issues += SupplementalAccessibilityChecks.duplicateLabelIssues(interactiveElements: interactive)
        }
        if checks.contains(.labelInName) {
            issues += SupplementalAccessibilityChecks.labelInNameIssues(interactiveElements: interactive)
        }
        if checks.contains(.genericLabels) {
            issues += SupplementalAccessibilityChecks.genericLabelIssues(interactiveElements: interactive)
        }
        if checks.contains(.labelHygiene) {
            issues += SupplementalAccessibilityChecks.labelHygieneIssues(interactiveElements: interactive)
        }
        if checks.contains(.adjustableValue) {
            issues += SupplementalAccessibilityChecks.adjustableValueIssues(
                adjustableElements: adjustableElements(in: snapshot, within: snapshot.frame)
            )
        }

        return issues
    }

    /// The outermost interactive elements on screen, for recording into a
    /// report's element inventory for cross-screen checks.
    public static func interactiveElementInventory(in snapshot: any XCUIElementSnapshot) -> [AuditedElement] {
        interactiveElements(in: snapshot, within: snapshot.frame)
    }

    /// Collects the outermost interactive elements that intersect `bounds`.
    /// Descendants of an interactive element are treated as part of its
    /// composite, not as separate targets.
    private static func interactiveElements(
        in snapshot: any XCUIElementSnapshot,
        within bounds: CGRect
    ) -> [AuditedElement] {
        if interactiveElementTypes.contains(snapshot.elementType) {
            guard bounds.intersects(snapshot.frame) else { return [] }
            return [
                AuditedElement(
                    identifier: snapshot.identifier,
                    label: snapshot.label,
                    frame: snapshot.frame,
                    visibleTextLabels: descendantStaticTextLabels(in: snapshot)
                )
            ]
        }
        return snapshot.children.flatMap { interactiveElements(in: $0, within: bounds) }
    }

    /// Collects adjustable controls that intersect `bounds`, carrying their
    /// accessibility value for the Adjustable Value check.
    private static func adjustableElements(
        in snapshot: any XCUIElementSnapshot,
        within bounds: CGRect
    ) -> [AuditedElement] {
        if adjustableElementTypes.contains(snapshot.elementType) {
            guard bounds.intersects(snapshot.frame) else { return [] }
            return [
                AuditedElement(
                    identifier: snapshot.identifier,
                    label: snapshot.label,
                    frame: snapshot.frame,
                    value: snapshot.value.map { $0 as? String ?? String(describing: $0) }
                )
            ]
        }
        return snapshot.children.flatMap { adjustableElements(in: $0, within: bounds) }
    }

    private static func descendantStaticTextLabels(in snapshot: any XCUIElementSnapshot) -> [String] {
        snapshot.children.flatMap { child -> [String] in
            if child.elementType == .staticText, !child.label.isEmpty {
                return [child.label]
            }
            return descendantStaticTextLabels(in: child)
        }
    }

    private static func navigationBarTitles(in snapshot: any XCUIElementSnapshot) -> [String] {
        if snapshot.elementType == .navigationBar {
            return [title(of: snapshot)]
        }
        return snapshot.children.flatMap { navigationBarTitles(in: $0) }
    }

    private static func title(of navigationBar: any XCUIElementSnapshot) -> String {
        if !navigationBar.identifier.isEmpty {
            return navigationBar.identifier
        }
        return firstStaticTextLabel(in: navigationBar) ?? ""
    }

    private static func firstStaticTextLabel(in snapshot: any XCUIElementSnapshot) -> String? {
        for child in snapshot.children {
            if child.elementType == .staticText, !child.label.isEmpty {
                return child.label
            }
            if let label = firstStaticTextLabel(in: child) {
                return label
            }
        }
        return nil
    }
}
