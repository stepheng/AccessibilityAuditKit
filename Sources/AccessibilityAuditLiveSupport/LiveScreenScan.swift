//
//  LiveScreenScan.swift
//  AccessibilityAuditLiveSupport
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
                reviewerHints: reviewerHints(for: node, auditType: "Interactive Element"),
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
                reviewerHints: reviewerHints(for: node, auditType: "Element Description"),
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
                reviewerHints: reviewerHints(for: node, auditType: "Adjustable Value"),
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
        if isSystemScrollBar(node) {
            // A UIScrollView scroll indicator is exposed as an `.adjustable`
            // element, so the trait-driven scan would otherwise treat it as an
            // interactive target. Its size and position are user-agent
            // controlled, not authored, so it is exempt from the target-size
            // criteria (WCAG 2.5.5/2.5.8 user-agent-control exception) and is
            // not an audit target at all. The XCTest path skips it implicitly
            // (`.scrollBar` is absent from its interactive set); this coarser
            // path must skip it explicitly. Its subtree holds nothing
            // auditable, so we do not recurse into it.
            return []
        }
        if !node.traits.isDisjoint(with: traits) {
            if node.frame.isEmpty {
                // A zero-frame match (e.g. an unlaid-out container) is not itself a
                // visible target, but its descendants may be — recurse rather than
                // drop them.
                return node.children.flatMap { collectOutermost($0, within: bounds, matching: traits, make) }
            }
            guard bounds.intersects(node.frame) else { return [] }
            return [make(node)]
        }
        return node.children.flatMap { collectOutermost($0, within: bounds, matching: traits, make) }
    }

    /// Whether the node is a system scroll indicator: iOS exposes it as an
    /// `.adjustable` element that is a direct child of a `UIScrollView`. The
    /// owner check is the primary, locale-independent signal; the English
    /// "scroll bar" label is kept only as a fallback for any case the owner
    /// relationship does not capture. iOS renders and sizes these, so they are
    /// not authored targets.
    private static func isSystemScrollBar(_ node: AccessibilityNode) -> Bool {
        guard node.traits.contains(.adjustable) else { return false }
        return node.ownerIsScrollView || node.label.lowercased().contains("scroll bar")
    }

    private static func reviewerHints(for node: AccessibilityNode, auditType: String) -> [IssueReviewerHint] {
        IssueReviewerHints.elementLocatorHints(
            identifier: node.identifier,
            label: node.label,
            auditType: auditType
        ) + IssueReviewerHints.runtimeHints(
            objectClassName: node.objectClassName,
            objectModuleName: node.objectModuleName,
            ownerClassName: node.ownerClassName,
            ownerModuleName: node.ownerModuleName
        )
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
