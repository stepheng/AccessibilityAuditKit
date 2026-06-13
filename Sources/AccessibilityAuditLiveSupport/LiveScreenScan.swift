//
//  LiveScreenScan.swift
//  AccessibilityAuditReport
//
//  Created by Stephen Gurnett on 14/06/2026.
//

#if canImport(UIKit)
import AccessibilityAuditReport
import CoreGraphics
import UIKit

/// Pure scan logic over an `AccessibilityNode` tree. The in-process analogue
/// of `SupplementalAuditScanner`, but trait-driven rather than keyed off
/// `XCUIElement.ElementType`, so its interactive set is intentionally coarser.
enum LiveScreenScan {
    /// Traits that make an element an interactive target for size, spacing,
    /// duplicate-label, label-in-name, generic-label, and hygiene checks.
    static let interactiveTraits: UIAccessibilityTraits = [.button, .link, .adjustable, .searchField, .keyboardKey]
    /// Traits expected to expose an accessibility value describing their state.
    static let adjustableTraits: UIAccessibilityTraits = [.adjustable]
    /// Traits whose elements must carry an accessible description.
    static let describableTraits: UIAccessibilityTraits = [.button, .link, .adjustable, .searchField, .image]

    /// All issues for one screen, combining the supplemental frame/label
    /// checks with the in-process missing-description and screen-title checks.
    static func issues(in root: AccessibilityNode, navigationBarTitles: [String]) -> [Issue] {
        let interactive = interactiveElements(in: root, within: root.frame)
        let describable = elementsRequiringDescription(in: root, within: root.frame)
        let adjustable = adjustableElements(in: root, within: root.frame)

        var issues: [Issue] = []
        issues += SupplementalAccessibilityChecks.targetSizeIssues(interactiveElements: interactive)
        issues += SupplementalAccessibilityChecks.targetSpacingIssues(interactiveElements: interactive)
        issues += SupplementalAccessibilityChecks.duplicateLabelIssues(interactiveElements: interactive)
        issues += SupplementalAccessibilityChecks.labelInNameIssues(interactiveElements: interactive)
        issues += SupplementalAccessibilityChecks.genericLabelIssues(interactiveElements: interactive)
        issues += SupplementalAccessibilityChecks.labelHygieneIssues(interactiveElements: interactive)
        issues += SupplementalAccessibilityChecks.adjustableValueIssues(adjustableElements: adjustable)
        issues += SupplementalAccessibilityChecks.missingElementDescriptionIssues(elements: describable)
        issues += SupplementalAccessibilityChecks.screenTitleIssues(navigationBarTitles: navigationBarTitles)
        return issues
    }

    /// Outermost interactive elements intersecting `bounds`; descendants of an
    /// interactive element are treated as part of its composite.
    static func interactiveElements(in root: AccessibilityNode, within bounds: CGRect) -> [AuditedElement] {
        collectOutermost(root, within: bounds, matching: interactiveTraits) { node in
            AuditedElement(
                identifier: node.identifier,
                label: node.label,
                frame: node.frame,
                visibleTextLabels: descendantStaticTexts(of: node),
                requiresDescription: true
            )
        }
    }

    /// Outermost interactive-or-image elements intersecting `bounds`, for the
    /// missing-description check.
    static func elementsRequiringDescription(in root: AccessibilityNode, within bounds: CGRect) -> [AuditedElement] {
        collectOutermost(root, within: bounds, matching: describableTraits) { node in
            AuditedElement(
                identifier: node.identifier,
                label: node.label,
                frame: node.frame,
                requiresDescription: true
            )
        }
    }

    /// Adjustable elements intersecting `bounds`, carrying their value.
    static func adjustableElements(in root: AccessibilityNode, within bounds: CGRect) -> [AuditedElement] {
        collectOutermost(root, within: bounds, matching: adjustableTraits) { node in
            AuditedElement(
                identifier: node.identifier,
                label: node.label,
                frame: node.frame,
                value: node.value,
                requiresDescription: true
            )
        }
    }

    // MARK: - Traversal

    private static func collectOutermost(
        _ node: AccessibilityNode,
        within bounds: CGRect,
        matching traits: UIAccessibilityTraits,
        _ make: (AccessibilityNode) -> AuditedElement
    ) -> [AuditedElement] {
        if !node.traits.isDisjoint(with: traits) {
            guard bounds.intersects(node.frame), !node.frame.isEmpty else { return [] }
            return [make(node)]
        }
        return node.children.flatMap { collectOutermost($0, within: bounds, matching: traits, make) }
    }

    /// Visible static-text labels nested under an element (for Label in Name).
    /// Best-effort: SwiftUI frequently merges these into a single leaf.
    private static func descendantStaticTexts(of node: AccessibilityNode) -> [String] {
        node.children.flatMap { child -> [String] in
            if !child.traits.isDisjoint(with: [.staticText]), !child.label.isEmpty {
                return [child.label]
            }
            return descendantStaticTexts(of: child)
        }
    }
}
#endif
