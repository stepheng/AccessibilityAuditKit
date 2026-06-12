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

    public static let all: SupplementalAuditType = [
        .targetSize, .targetSpacing, .screenTitle, .duplicateLabels
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

    public static func issues(
        in snapshot: any XCUIElementSnapshot,
        checks: SupplementalAuditType
    ) -> [Issue] {
        var issues: [Issue] = []
        let needsInteractive = !checks.isDisjoint(with: [.targetSize, .targetSpacing, .duplicateLabels])
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

        return issues
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
                    frame: snapshot.frame
                )
            ]
        }
        return snapshot.children.flatMap { interactiveElements(in: $0, within: bounds) }
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
