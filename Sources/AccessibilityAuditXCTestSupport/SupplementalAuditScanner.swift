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
    public static let inputPurpose = SupplementalAuditType(rawValue: 1 << 9)
    /// Pixel-based check: needs the screenshot, so `issues(in:checks:)` treats it
    /// as a no-op. `recordAccessibilityAuditScreen` runs it via
    /// `graphicalElementInventory` + `SupplementalAccessibilityChecks.nonTextContrastIssues`.
    public static let nonTextContrast = SupplementalAuditType(rawValue: 1 << 10)

    public static let all: SupplementalAuditType = [
        .targetSize, .targetSpacing, .screenTitle, .duplicateLabels,
        .labelInName, .genericLabels, .adjustableValue, .consistentIdentification,
        .labelHygiene, .inputPurpose, .nonTextContrast
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

    /// Text-entry fields whose content may be information about the user, for
    /// the Input Purpose check (WCAG 1.3.5). Search fields are excluded — their
    /// content is a query, not personal data.
    static let textEntryElementTypes: Set<XCUIElement.ElementType> = [
        .textField, .secureTextField
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
        if checks.contains(.inputPurpose) {
            issues += SupplementalAccessibilityChecks.inputPurposeIssues(
                textEntryElements: textEntryElements(in: snapshot, within: snapshot.frame)
            )
        }

        return issues
    }

    /// Interactive element types treated as icon-style controls: when they carry
    /// no visible text they render as a glyph, so Non-text Contrast (1.4.11)
    /// applies to them.
    static let iconControlTypes: Set<XCUIElement.ElementType> = [.button, .menuItem, .link]

    /// The outermost interactive elements on screen, for recording into a
    /// report's element inventory for cross-screen checks.
    public static func interactiveElementInventory(in snapshot: any XCUIElementSnapshot) -> [AuditedElement] {
        interactiveElements(in: snapshot, within: snapshot.frame)
    }

    /// The graphical objects on screen for the Non-text Contrast check (WCAG
    /// 1.4.11): image elements, and icon-only interactive controls that carry no
    /// visible text. Disabled and offscreen elements are excluded.
    public static func graphicalElementInventory(
        in snapshot: any XCUIElementSnapshot
    ) -> [AuditedElement] {
        graphicalElements(in: snapshot, within: snapshot.frame)
    }

    private static func graphicalElements(
        in snapshot: any XCUIElementSnapshot,
        within bounds: CGRect
    ) -> [AuditedElement] {
        if snapshot.elementType == .image {
            guard snapshot.isEnabled, !snapshot.frame.isEmpty,
                  bounds.intersects(snapshot.frame) else {
                return []
            }
            return [graphicalElement(from: snapshot)]
        }
        if iconControlTypes.contains(snapshot.elementType) {
            // Only icon-only controls (no visible text) are graphical objects.
            // Either way we do not descend into an interactive element's
            // composite, so nested glyphs are not double-counted.
            guard snapshot.isEnabled, !snapshot.frame.isEmpty,
                  bounds.intersects(snapshot.frame),
                  descendantStaticTextLabels(in: snapshot).isEmpty else {
                return []
            }
            return [graphicalElement(from: snapshot)]
        }
        return snapshot.children.flatMap { graphicalElements(in: $0, within: bounds) }
    }

    private static func graphicalElement(from snapshot: any XCUIElementSnapshot) -> AuditedElement {
        AuditedElement(
            identifier: snapshot.identifier,
            label: snapshot.label,
            frame: snapshot.frame
        )
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

    /// Collects text-entry fields that intersect `bounds`, carrying their
    /// visible text for the Input Purpose check.
    private static func textEntryElements(
        in snapshot: any XCUIElementSnapshot,
        within bounds: CGRect
    ) -> [AuditedElement] {
        if textEntryElementTypes.contains(snapshot.elementType) {
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
        return snapshot.children.flatMap { textEntryElements(in: $0, within: bounds) }
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
