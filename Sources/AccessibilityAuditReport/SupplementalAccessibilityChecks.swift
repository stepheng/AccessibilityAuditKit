//
//  SupplementalAccessibilityChecks.swift
//  AccessibilityAuditReport
//
//  Created by Stephen Gurnett on 12/06/2026.
//

import CoreGraphics
import Foundation

public struct AuditedElement {
    public let identifier: String
    public let label: String
    public let frame: CGRect

    public init(identifier: String, label: String, frame: CGRect) {
        self.identifier = identifier
        self.label = label
        self.frame = frame
    }
}

/// Frame- and label-based checks that close coverage gaps left by
/// `XCUIApplication.performAccessibilityAudit`, mirroring rules from the
/// Level Access mobile accessibility tester.
public enum SupplementalAccessibilityChecks {
    public static let defaultMinimumTargetDimension: CGFloat = 44
    public static let defaultMinimumTargetSpacing: CGFloat = 6

    /// Flags interactive elements smaller than `minimumDimension` in either
    /// dimension (WCAG 2.5.5 Target Size).
    public static func targetSizeIssues(
        interactiveElements: [AuditedElement],
        minimumDimension: CGFloat = defaultMinimumTargetDimension
    ) -> [Issue] {
        interactiveElements
            .filter { !$0.frame.isEmpty }
            .filter { $0.frame.width < minimumDimension || $0.frame.height < minimumDimension }
            .map { element in
                Issue(
                    auditType: "Target Size",
                    compactDescription: "Interactive target is smaller than \(format(minimumDimension))×\(format(minimumDimension))pt",
                    detailedDescription: "The element measures \(format(element.frame.width))×\(format(element.frame.height))pt. WCAG 2.5.5 recommends a minimum target size of \(format(minimumDimension))×\(format(minimumDimension))pt.",
                    elementIdentifier: element.identifier,
                    elementLabel: element.label,
                    elementFrame: element.frame
                )
            }
    }

    /// Flags pairs of interactive elements that overlap or sit closer than
    /// `minimumSpacing` (WCAG 2.5.8 Target Size (Minimum) spacing exception).
    /// Pairs where one frame fully contains the other are treated as
    /// parent/child composites and skipped.
    public static func targetSpacingIssues(
        interactiveElements: [AuditedElement],
        minimumSpacing: CGFloat = defaultMinimumTargetSpacing
    ) -> [Issue] {
        let elements = interactiveElements.filter { !$0.frame.isEmpty }
        var issues: [Issue] = []

        for (index, first) in elements.enumerated() {
            for second in elements.dropFirst(index + 1) {
                if first.frame.contains(second.frame) || second.frame.contains(first.frame) {
                    continue
                }
                guard gap(between: first.frame, and: second.frame) < minimumSpacing else {
                    continue
                }
                issues.append(
                    Issue(
                        auditType: "Target Spacing",
                        compactDescription: "Interactive targets are closer than \(format(minimumSpacing))pt apart",
                        detailedDescription: "The element is less than \(format(minimumSpacing))pt away from (and may be overlapping) \"\(second.identifier)\" (\(second.label)). WCAG 2.5.8 requires undersized targets to have sufficient spacing.",
                        elementIdentifier: first.identifier,
                        elementLabel: first.label,
                        elementFrame: first.frame
                    )
                )
            }
        }

        return issues
    }

    /// Flags navigation bars whose title text is empty (WCAG 2.4.2 Page Titled).
    public static func screenTitleIssues(navigationBarTitles: [String]) -> [Issue] {
        navigationBarTitles
            .filter { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .map { _ in
                Issue(
                    auditType: "Screen Title",
                    compactDescription: "Navigation bar does not contain a title",
                    detailedDescription: "The navigation bar has no title text, so the screen's purpose is not announced. WCAG 2.4.2 requires screens to be titled.",
                    elementIdentifier: "No element identifier",
                    elementLabel: "No element label",
                    elementFrame: nil
                )
            }
    }

    /// Flags groups of interactive elements sharing the same accessible label
    /// (WCAG 2.4.6 Headings and Labels; ambiguous for Voice Control users).
    public static func duplicateLabelIssues(interactiveElements: [AuditedElement]) -> [Issue] {
        let labelled = interactiveElements.filter {
            !$0.label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        let groups = Dictionary(grouping: labelled) {
            $0.label.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        }

        return groups.values
            .filter { $0.count > 1 }
            .sorted { $0[0].label < $1[0].label }
            .map { group in
                let identifiers = group.map { "\"\($0.identifier)\"" }.joined(separator: ", ")
                return Issue(
                    auditType: "Duplicate Labels",
                    compactDescription: "\(group.count) interactive elements share the label \"\(group[0].label)\"",
                    detailedDescription: "Elements \(identifiers) share the same accessible label, which is ambiguous for Voice Control and screen reader users. WCAG 2.4.6 requires labels that distinguish controls.",
                    elementIdentifier: group[0].identifier,
                    elementLabel: group[0].label,
                    elementFrame: group[0].frame
                )
            }
    }

    /// Flags a layout that stays portrait-proportioned after the device
    /// rotates to landscape (WCAG 1.3.4 Orientation). The comparison is
    /// inconclusive — and skipped — when either size is empty or the window
    /// was not taller than wide before rotating.
    public static func orientationLockIssues(
        portraitWindowSize: CGSize,
        landscapeWindowSize: CGSize
    ) -> [Issue] {
        guard portraitWindowSize.width > 0, portraitWindowSize.height > 0,
              landscapeWindowSize.width > 0, landscapeWindowSize.height > 0,
              portraitWindowSize.height > portraitWindowSize.width else {
            return []
        }
        guard landscapeWindowSize.width <= landscapeWindowSize.height else {
            return []
        }
        return [
            Issue(
                auditType: "Orientation",
                compactDescription: "Layout did not respond to device rotation",
                detailedDescription: "The root window stayed \(format(landscapeWindowSize.width))×\(format(landscapeWindowSize.height))pt (portrait-proportioned) after the device rotated to landscape, so the app or screen appears locked to a single orientation. WCAG 1.3.4 requires content to work in both portrait and landscape unless a specific orientation is essential.",
                elementIdentifier: "No element identifier",
                elementLabel: "No element label",
                elementFrame: nil
            )
        ]
    }

    /// Shortest edge-to-edge distance between two non-intersecting rects;
    /// zero when they intersect.
    private static func gap(between first: CGRect, and second: CGRect) -> CGFloat {
        let horizontalGap = max(0, max(first.minX - second.maxX, second.minX - first.maxX))
        let verticalGap = max(0, max(first.minY - second.maxY, second.minY - first.maxY))
        return hypot(horizontalGap, verticalGap)
    }

    private static func format(_ value: CGFloat) -> String {
        value.rounded() == value
            ? String(Int(value))
            : String(format: "%.1f", value)
    }
}
