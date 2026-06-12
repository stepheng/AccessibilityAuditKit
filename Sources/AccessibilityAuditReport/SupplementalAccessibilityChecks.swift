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
    /// Static text visible inside the element, used to verify the accessible
    /// label against what sighted users read (WCAG 2.5.3 Label in Name).
    public let visibleTextLabels: [String]
    /// The element's accessibility value, used to verify adjustable controls
    /// announce their current state (WCAG 4.1.2 Name, Role, Value).
    public let value: String?

    public init(
        identifier: String,
        label: String,
        frame: CGRect,
        visibleTextLabels: [String] = [],
        value: String? = nil
    ) {
        self.identifier = identifier
        self.label = label
        self.frame = frame
        self.visibleTextLabels = visibleTextLabels
        self.value = value
    }
}

/// The interactive elements collected from one audited screen, used by
/// cross-screen checks such as Consistent Identification (WCAG 3.2.4).
public struct AuditedScreenElements {
    public let screenName: String
    public let elements: [AuditedElement]

    public init(screenName: String, elements: [AuditedElement]) {
        self.screenName = screenName
        self.elements = elements
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

    /// Labels that describe the control's role or prompt rather than its
    /// purpose; matched against the whole label, case-insensitively.
    private static let genericLabelWords: Set<String> = [
        "button", "link", "image", "icon", "picture", "graphic",
        "item", "label", "element", "view", "untitled", "more",
        "tap", "tap here", "click", "click here"
    ]

    /// Flags interactive elements whose label is a generic role word ("Button",
    /// "More") or an asset/file name ("IMG_0123.png", "ic_chevron") instead of
    /// a description of the control's purpose (WCAG 2.4.4; also undermines
    /// 4.1.2 Name, Role, Value). Empty labels are left to Apple's
    /// sufficientElementDescription audit.
    public static func genericLabelIssues(interactiveElements: [AuditedElement]) -> [Issue] {
        interactiveElements.compactMap { element in
            let label = element.label.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !label.isEmpty else { return nil }

            let reason: String
            if genericLabelWords.contains(label.lowercased()) {
                reason = "a generic word that describes the control's role, not its purpose"
            } else if isFilenameLike(label) {
                reason = "an asset or file name leaking into the accessibility tree"
            } else {
                return nil
            }

            return Issue(
                auditType: "Generic Label",
                compactDescription: "Accessible label \"\(label)\" does not describe the element's purpose",
                detailedDescription: "The label \"\(label)\" is \(reason). Screen reader and Voice Control users cannot tell what the control does. WCAG 2.4.4 requires the purpose of each control to be determinable from its label.",
                elementIdentifier: element.identifier,
                elementLabel: element.label,
                elementFrame: element.frame
            )
        }
    }

    private static func isFilenameLike(_ label: String) -> Bool {
        let lowered = label.lowercased()
        let fileExtensions = ["png", "jpg", "jpeg", "gif", "svg", "pdf", "heic", "webp"]
        if let dotIndex = lowered.lastIndex(of: "."),
           fileExtensions.contains(String(lowered[lowered.index(after: dotIndex)...])),
           !lowered[..<dotIndex].contains(" ") {
            return true
        }
        let assetPrefixes = ["ic_", "ic-", "img_", "img-", "btn_", "btn-", "icon_", "icon-"]
        return assetPrefixes.contains { lowered.hasPrefix($0) }
    }

    /// Flags interactive elements whose accessible label does not contain any
    /// of the text visible inside them (WCAG 2.5.3 Label in Name). Voice
    /// Control users speak the text they see; a mismatched label makes the
    /// control unaddressable. Lenient by design: one matching visible string
    /// is enough, so composite controls with secondary text do not flag.
    public static func labelInNameIssues(interactiveElements: [AuditedElement]) -> [Issue] {
        interactiveElements.compactMap { element in
            let visibleTexts = element.visibleTextLabels
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            guard !visibleTexts.isEmpty else { return nil }

            let label = element.label
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()
            guard !visibleTexts.contains(where: { label.contains($0.lowercased()) }) else {
                return nil
            }

            let quotedTexts = visibleTexts.map { "\"\($0)\"" }.joined(separator: ", ")
            return Issue(
                auditType: "Label in Name",
                compactDescription: "Accessible label does not contain the element's visible text",
                detailedDescription: "The element displays \(quotedTexts) but its accessible label is \"\(element.label)\". Voice Control users speak the visible text to activate controls, so WCAG 2.5.3 requires the accessible name to contain it.",
                elementIdentifier: element.identifier,
                elementLabel: element.label,
                elementFrame: element.frame
            )
        }
    }

    /// Flags adjustable controls (sliders, pickers) that expose no
    /// accessibility value (WCAG 4.1.2 Name, Role, Value). Without a value,
    /// VoiceOver users can move the control but never hear its current state.
    public static func adjustableValueIssues(adjustableElements: [AuditedElement]) -> [Issue] {
        adjustableElements
            .filter { element in
                let value = element.value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                return value.isEmpty
            }
            .map { element in
                Issue(
                    auditType: "Adjustable Value",
                    compactDescription: "Adjustable control does not expose its current value",
                    detailedDescription: "The control has no accessibility value, so VoiceOver users cannot hear its current state or confirm that adjusting it had an effect. WCAG 4.1.2 requires controls to expose their name, role, and value.",
                    elementIdentifier: element.identifier,
                    elementLabel: element.label,
                    elementFrame: element.frame
                )
            }
    }

    /// Flags elements that share an accessibility identifier but carry
    /// different labels across screens (WCAG 3.2.4 Consistent Identification).
    /// The same control renamed from screen to screen forces screen reader
    /// users to re-learn it on every screen.
    public static func consistentIdentificationIssues(screens: [AuditedScreenElements]) -> [Issue] {
        struct Sighting {
            let screenName: String
            let element: AuditedElement
            let normalizedLabel: String
        }

        let sightings = screens.flatMap { screen in
            screen.elements.compactMap { element -> Sighting? in
                let label = element.label
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .lowercased()
                guard !element.identifier.isEmpty, !label.isEmpty else { return nil }
                return Sighting(screenName: screen.screenName, element: element, normalizedLabel: label)
            }
        }

        return Dictionary(grouping: sightings, by: \.element.identifier)
            .filter { _, group in Set(group.map(\.normalizedLabel)).count > 1 }
            .sorted { $0.key < $1.key }
            .map { identifier, group in
                let labelsByScreen = group
                    .map { "\"\($0.element.label)\" on \($0.screenName)" }
                    .joined(separator: ", ")
                return Issue(
                    auditType: "Consistent Identification",
                    compactDescription: "Element \"\(identifier)\" is labelled differently across screens",
                    detailedDescription: "The element appears as \(labelsByScreen). WCAG 3.2.4 requires components with the same function to be identified consistently, so screen reader users can recognise the control wherever it appears.",
                    elementIdentifier: identifier,
                    elementLabel: group[0].element.label,
                    elementFrame: nil
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
