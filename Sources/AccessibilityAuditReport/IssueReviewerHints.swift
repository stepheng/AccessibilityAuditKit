//
//  IssueReviewerHints.swift
//  AccessibilityAuditReport
//
//  Created by Stephen Gurnett on 14/06/2026.
//

import Foundation

public enum IssueReviewerHints {
    public static func elementLocatorHints(
        identifier: String,
        label: String,
        auditType: String
    ) -> [IssueReviewerHint] {
        var hints: [IssueReviewerHint] = []
        if isUsefulIdentifier(identifier) {
            hints.append(
                IssueReviewerHint(
                    title: "Search source by identifier",
                    detail: "Search for accessibility identifier \"\(identifier)\". If the screen composes shared components, inspect the component that assigns or forwards that identifier.",
                    automationKey: "source.search.identifier"
                )
            )
        }
        if isUsefulLabel(label) {
            hints.append(
                IssueReviewerHint(
                    title: "Search source by label",
                    detail: "Search for visible text, localized string keys, and accessibility labels matching \"\(label)\".",
                    automationKey: "source.search.label"
                )
            )
        }
        _ = auditType
        return hints
    }

    public static func remediationHints(auditType: String) -> [IssueReviewerHint] {
        switch auditType {
        case "Target Size (Minimum)", "Target Size (Enhanced)", "Target Spacing", "Hit Region":
            return [
                IssueReviewerHint(
                    title: "Inspect owning control layout",
                    detail: "Check the reusable control, hit area, padding, or button style that owns this target before changing only the containing screen.",
                    automationKey: "audit.remediation.target-size"
                )
            ]
        case "Duplicate Labels", "Generic Label", "Label Hygiene", "Label in Name", "Element Description", "Sufficient Element Description":
            return [
                IssueReviewerHint(
                    title: "Inspect label construction",
                    detail: "Check visible text, localization keys, accessibility label construction, and reused cell or row components.",
                    automationKey: "audit.remediation.label"
                )
            ]
        case "Consistent Identification":
            return [
                IssueReviewerHint(
                    title: "Inspect shared component labels",
                    detail: "Check shared tab, toolbar, row, and localized label construction so the same control is named consistently across screens.",
                    automationKey: "audit.remediation.consistent-identification"
                )
            ]
        case "Adjustable Value", "Trait":
            return [
                IssueReviewerHint(
                    title: "Inspect custom control semantics",
                    detail: "Check the custom slider, picker, or adjustable control wrapper that exposes name, role, value, and traits.",
                    automationKey: "audit.remediation.adjustable-value"
                )
            ]
        case "Input Purpose":
            return [
                IssueReviewerHint(
                    title: "Verify text field content type",
                    detail: "Inspect the text field wrapper in source and verify it sets the appropriate textContentType.",
                    automationKey: "audit.remediation.input-purpose"
                )
            ]
        case "Non-text Contrast", "Contrast":
            return [
                IssueReviewerHint(
                    title: "Inspect graphical asset and colors",
                    detail: "Check icon assets, tint, foreground/background semantic colors, and shared icon button styles.",
                    automationKey: "audit.remediation.non-text-contrast"
                )
            ]
        default:
            return []
        }
    }

    public static func runtimeHints(
        objectClassName: String,
        objectModuleName: String?,
        ownerClassName: String?,
        ownerModuleName: String?
    ) -> [IssueReviewerHint] {
        var hints: [IssueReviewerHint] = []
        if objectClassName.isEmpty == false {
            hints.append(
                IssueReviewerHint(
                    title: "Backing accessibility object",
                    detail: "Runtime object: \(qualifiedName(module: objectModuleName, className: objectClassName)). Treat this as a breadcrumb, not proof of root cause.",
                    automationKey: "runtime.class"
                )
            )
        }
        if let ownerClassName, ownerClassName.isEmpty == false {
            hints.append(
                IssueReviewerHint(
                    title: "Owning runtime object",
                    detail: "Immediate owner: \(qualifiedName(module: ownerModuleName, className: ownerClassName)). Shared wrappers or hosting views may forward accessibility metadata.",
                    automationKey: "runtime.ownerClass"
                )
            )
        }
        return hints
    }

    private static func isUsefulIdentifier(_ value: String) -> Bool {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty == false && trimmed != "No element identifier"
    }

    private static func isUsefulLabel(_ value: String) -> Bool {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty == false && trimmed != "No element label"
    }

    private static func qualifiedName(module: String?, className: String) -> String {
        guard let module, module.isEmpty == false else { return className }
        return "\(module).\(className)"
    }
}
