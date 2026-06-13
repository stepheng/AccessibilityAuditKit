//
//  AcceptanceResolver.swift
//  AccessibilityAuditReport
//

/// Annotates issues with acceptance state by matching them against baseline
/// rules. Pure and synchronous — no XCUITest dependency. Identity-first:
/// match on element identifier when the rule provides a usable one, otherwise
/// fall back to the accessible label. A matched rule whose `context` no longer
/// equals the issue's current `compactDescription` is flagged stale (still
/// accepted, but surfaced for re-review).
public enum AcceptanceResolver {
    private static let placeholderIdentifiers: Set<String> = ["", "No element identifier"]

    public static func resolve(
        issues: [Issue],
        screen: String,
        variant: String,
        rules: [AcceptanceRule]
    ) -> [Issue] {
        issues.map { issue in
            guard let rule = rules.first(where: {
                matches($0, issue: issue, screen: screen, variant: variant)
            }) else {
                return issue
            }
            let isStale = rule.context != nil && rule.context != issue.compactDescription
            return issue.with(acceptance: Acceptance(reason: rule.reason, isStale: isStale))
        }
    }

    private static func matches(
        _ rule: AcceptanceRule,
        issue: Issue,
        screen: String,
        variant: String
    ) -> Bool {
        guard rule.screen == screen, rule.auditType == issue.auditType else {
            return false
        }
        if let ruleVariant = rule.variant, ruleVariant != variant {
            return false
        }
        if let identifier = rule.elementIdentifier,
           !placeholderIdentifiers.contains(identifier) {
            return issue.elementIdentifier == identifier
        }
        return rule.elementLabel == issue.elementLabel
    }
}
