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
    public let reviewerHints: [IssueReviewerHint]
    /// Whether this element must carry an accessible description — an
    /// interactive control or a meaningful image. Used by the in-process
    /// missing-description check, the equivalent of Apple's
    /// `sufficientElementDescription` audit (which only runs under XCTest).
    public let requiresDescription: Bool

    public init(
        identifier: String,
        label: String,
        frame: CGRect,
        visibleTextLabels: [String] = [],
        value: String? = nil,
        reviewerHints: [IssueReviewerHint] = [],
        requiresDescription: Bool = false
    ) {
        self.identifier = identifier
        self.label = label
        self.frame = frame
        self.visibleTextLabels = visibleTextLabels
        self.value = value
        self.reviewerHints = reviewerHints
        self.requiresDescription = requiresDescription
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
    /// WCAG 2.5.8's minimum target dimension. A target smaller than this in
    /// either dimension is "undersized" and must instead satisfy the spacing
    /// exception: a circle of this diameter centred on it must not overlap a
    /// neighbouring target (or another undersized target's circle).
    public static let undersizedTargetThreshold: CGFloat = 24

    static func issueReviewerHints(for element: AuditedElement, auditType: String) -> [IssueReviewerHint] {
        deduplicatedReviewerHints(
            element.reviewerHints + IssueReviewerHints.remediationHints(auditType: auditType)
        )
    }

    static func deduplicatedReviewerHints(_ hints: [IssueReviewerHint]) -> [IssueReviewerHint] {
        var seen: Set<String> = []
        var result: [IssueReviewerHint] = []
        for hint in hints {
            let key = "\(hint.automationKey ?? "")|\(hint.title)|\(hint.detail)"
            if seen.insert(key).inserted {
                result.append(hint)
            }
        }
        return result
    }

    /// Flags interactive elements below the WCAG target-size thresholds,
    /// bucketing each element to its worst failing level so it is reported
    /// once. An element smaller than `minimumDimension` in a dimension fails
    /// 2.5.8 Target Size (Minimum), Level AA (`.error`); an element that clears
    /// `minimumDimension` but is smaller than `enhancedDimension` fails only
    /// 2.5.5 Target Size (Enhanced), Level AAA (`.warning`).
    public static func targetSizeIssues(
        interactiveElements: [AuditedElement],
        minimumDimension: CGFloat = undersizedTargetThreshold,
        enhancedDimension: CGFloat = defaultMinimumTargetDimension
    ) -> [Issue] {
        interactiveElements
            .filter { !$0.frame.isEmpty }
            .compactMap { element -> Issue? in
                let frame = element.frame
                if frame.width < minimumDimension || frame.height < minimumDimension {
                    return Issue(
                        auditType: "Target Size (Minimum)",
                        compactDescription: "Interactive target is smaller than \(format(minimumDimension))×\(format(minimumDimension))pt",
                        detailedDescription: "The element measures \(format(frame.width))×\(format(frame.height))pt. WCAG 2.5.8 (Level AA) requires a minimum target size of \(format(minimumDimension))×\(format(minimumDimension))pt unless the target has sufficient spacing (see Target Spacing).",
                        elementIdentifier: element.identifier,
                        elementLabel: element.label,
                        elementFrame: frame,
                        reviewerHints: issueReviewerHints(for: element, auditType: "Target Size (Minimum)"),
                        severity: .error
                    )
                }
                if frame.width < enhancedDimension || frame.height < enhancedDimension {
                    return Issue(
                        auditType: "Target Size (Enhanced)",
                        compactDescription: "Interactive target is smaller than \(format(enhancedDimension))×\(format(enhancedDimension))pt",
                        detailedDescription: "The element measures \(format(frame.width))×\(format(frame.height))pt. WCAG 2.5.5 (Level AAA) recommends a minimum target size of \(format(enhancedDimension))×\(format(enhancedDimension))pt.",
                        elementIdentifier: element.identifier,
                        elementLabel: element.label,
                        elementFrame: frame,
                        reviewerHints: issueReviewerHints(for: element, auditType: "Target Size (Enhanced)"),
                        severity: .warning
                    )
                }
                return nil
            }
    }

    /// Flags pairs of interactive elements that fail WCAG 2.5.8's spacing
    /// exception: at least one element is undersized (smaller than
    /// `threshold` in a dimension) and a `threshold`pt-diameter circle centred
    /// on it overlaps the neighbouring target — or, when both are undersized,
    /// their circles overlap. Well-sized targets that merely touch or overlap
    /// each other are not flagged, since 2.5.8's spacing rule applies only to
    /// undersized targets. Pairs where one frame fully contains the other are
    /// treated as parent/child composites and skipped.
    public static func targetSpacingIssues(
        interactiveElements: [AuditedElement],
        threshold: CGFloat = undersizedTargetThreshold
    ) -> [Issue] {
        let radius = threshold / 2
        let elements = interactiveElements.filter { !$0.frame.isEmpty }
        var issues: [Issue] = []

        for (index, first) in elements.enumerated() {
            for second in elements.dropFirst(index + 1) {
                if first.frame.contains(second.frame) || second.frame.contains(first.frame) {
                    continue
                }
                let firstUndersized = isUndersized(first.frame, threshold: threshold)
                let secondUndersized = isUndersized(second.frame, threshold: threshold)
                guard firstUndersized || secondUndersized else { continue }
                guard spacingCirclesOverlap(
                    first.frame,
                    second.frame,
                    firstUndersized: firstUndersized,
                    secondUndersized: secondUndersized,
                    radius: radius
                ) else { continue }

                issues.append(
                    Issue(
                        auditType: "Target Spacing",
                        compactDescription: "Undersized interactive target is too close to a neighbour",
                        detailedDescription: "This target and \"\(second.identifier)\" (\(second.label)) are positioned so that a \(format(threshold))pt target-spacing circle on an undersized target overlaps the other. WCAG 2.5.8 requires undersized targets (smaller than \(format(threshold))×\(format(threshold))pt) to be spaced so their \(format(threshold))pt-diameter circles do not overlap neighbouring targets.",
                        elementIdentifier: first.identifier,
                        elementLabel: first.label,
                        elementFrame: first.frame,
                        reviewerHints: deduplicatedReviewerHints(
                            first.reviewerHints
                                + second.reviewerHints
                                + IssueReviewerHints.remediationHints(auditType: "Target Spacing")
                        )
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
            .compactMap { group -> Issue? in
                // Collapse elements that occupy the same frame: one control
                // surfaced more than once in the accessibility tree (e.g. a
                // system tab bar item exposed twice) is not a real
                // duplicate-label violation. Only genuinely distinct positions
                // count toward the duplicate.
                let distinct = collapsingCoincidentFrames(group)
                guard distinct.count > 1 else { return nil }

                let members = distinct
                    .map { "\"\($0.identifier)\" (\(describe($0.frame)))" }
                    .joined(separator: ", ")
                return Issue(
                    auditType: "Duplicate Labels",
                    compactDescription: "\(distinct.count) interactive elements share the label \"\(distinct[0].label)\"",
                    detailedDescription: "Elements \(members) share the same accessible label, which is ambiguous for Voice Control and screen reader users. WCAG 2.4.6 requires labels that distinguish controls.",
                    elementIdentifier: distinct[0].identifier,
                    elementLabel: distinct[0].label,
                    elementFrame: distinct[0].frame,
                    additionalFrames: distinct.dropFirst().map(\.frame),
                    reviewerHints: deduplicatedReviewerHints(
                        distinct.flatMap(\.reviewerHints)
                            + IssueReviewerHints.remediationHints(auditType: "Duplicate Labels")
                    )
                )
            }
            .sorted { $0.elementLabel < $1.elementLabel }
    }

    /// One representative element per distinct on-screen position, preserving
    /// order. Elements whose frames coincide (within half a point) are treated
    /// as the same control surfaced more than once and collapsed to the first.
    private static func collapsingCoincidentFrames(_ elements: [AuditedElement]) -> [AuditedElement] {
        var representatives: [AuditedElement] = []
        for element in elements
        where !representatives.contains(where: { framesApproximatelyEqual($0.frame, element.frame) }) {
            representatives.append(element)
        }
        return representatives
    }

    private static func framesApproximatelyEqual(
        _ lhs: CGRect,
        _ rhs: CGRect,
        tolerance: CGFloat = 0.5
    ) -> Bool {
        abs(lhs.minX - rhs.minX) <= tolerance
            && abs(lhs.minY - rhs.minY) <= tolerance
            && abs(lhs.width - rhs.width) <= tolerance
            && abs(lhs.height - rhs.height) <= tolerance
    }

    /// A compact "x, y, w×h" summary of a frame for finding detail text.
    private static func describe(_ frame: CGRect) -> String {
        "x: \(format(frame.minX)), y: \(format(frame.minY)), \(format(frame.width))×\(format(frame.height))"
    }

    /// Labels that describe the control's role or prompt rather than its
    /// purpose; matched against the whole label, case-insensitively.
    private static let genericLabelWords: Set<String> = [
        "button", "link", "image", "icon", "picture", "graphic",
        "item", "label", "element", "view", "untitled", "more",
        "tap", "tap here", "click", "click here"
    ]

    /// Flags interactive elements whose label is a generic role word ("Button",
    /// "More"), an asset/file name ("IMG_0123.png", "ic_chevron"), a leaked
    /// identifier or code-style string ("files.backupStatus", "backup_status",
    /// "chevron.right"), or a bare symbol ("★") instead of a description of the
    /// control's purpose (WCAG 2.4.4; also undermines 4.1.2 Name, Role, Value).
    /// Empty labels are left to Apple's sufficientElementDescription audit.
    public static func genericLabelIssues(interactiveElements: [AuditedElement]) -> [Issue] {
        interactiveElements.compactMap { element in
            let label = element.label.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !label.isEmpty else { return nil }

            let reason: String
            if genericLabelWords.contains(label.lowercased()) {
                reason = "a generic word that describes the control's role, not its purpose"
            } else if !element.identifier.isEmpty,
                      label.caseInsensitiveCompare(element.identifier) == .orderedSame {
                reason = "the accessibility identifier leaking into the accessible label"
            } else if isFilenameLike(label) {
                reason = "an asset or file name leaking into the accessibility tree"
            } else if isCodeLike(label) {
                reason = "a code-style string (camelCase, snake_case, or a symbol name) rather than human-readable text"
            } else if label.rangeOfCharacter(from: .alphanumerics) == nil {
                reason = "a bare symbol or emoji, which VoiceOver may announce unhelpfully or not at all"
            } else {
                return nil
            }

            return Issue(
                auditType: "Generic Label",
                compactDescription: "Accessible label \"\(label)\" does not describe the element's purpose",
                detailedDescription: "The label \"\(label)\" is \(reason). Screen reader and Voice Control users cannot tell what the control does. WCAG 2.4.4 requires the purpose of each control to be determinable from its label.",
                elementIdentifier: element.identifier,
                elementLabel: element.label,
                elementFrame: element.frame,
                reviewerHints: issueReviewerHints(for: element, auditType: "Generic Label"),
                severity: .warning
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

    /// A single token in snake_case, camelCase, or dotted-path style
    /// ("backup_status", "backupStatus", "chevron.right").
    private static func isCodeLike(_ label: String) -> Bool {
        guard !label.contains(where: \.isWhitespace) else { return false }
        if label.contains("_") {
            return true
        }
        var previous: Character?
        for character in label {
            if let previous, previous.isLowercase, character.isUppercase {
                return true
            }
            previous = character
        }
        let dottedParts = label.split(separator: ".")
        return dottedParts.count > 1 && dottedParts.allSatisfy { $0.first?.isLetter == true }
    }

    /// Role words VoiceOver already announces from the element's traits.
    private static let redundantRoleSuffixes: Set<String> = [
        "button", "tab", "link", "icon", "image", "menu"
    ]

    /// Flags labels that announce badly through VoiceOver: a redundant role
    /// suffix ("Save button" announces as "Save button, button" — WCAG 4.1.2
    /// hygiene), leading/trailing whitespace, or all-caps styling leaking into
    /// the label (VoiceOver may spell it out letter by letter). One issue per
    /// problem found. Short acronyms ("OK", "PDF") are not treated as all-caps.
    public static func labelHygieneIssues(interactiveElements: [AuditedElement]) -> [Issue] {
        interactiveElements.flatMap { element -> [Issue] in
            let label = element.label.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !label.isEmpty else { return [] }

            var issues: [Issue] = []
            func record(_ compactDescription: String, _ detail: String) {
                issues.append(
                    Issue(
                        auditType: "Label Hygiene",
                        compactDescription: compactDescription,
                        detailedDescription: detail,
                        elementIdentifier: element.identifier,
                        elementLabel: element.label,
                        elementFrame: element.frame,
                        reviewerHints: issueReviewerHints(for: element, auditType: "Label Hygiene"),
                        severity: .warning
                    )
                )
            }

            let words = label.lowercased().split(whereSeparator: \.isWhitespace)
            if words.count > 1, let lastWord = words.last,
               redundantRoleSuffixes.contains(String(lastWord)) {
                record(
                    "Accessible label ends with the redundant role word \"\(lastWord)\"",
                    "VoiceOver already announces the element's role from its traits, so \"\(label)\" is read as \"\(label), \(lastWord)\". WCAG 4.1.2 expects the role to come from the element's traits, not its name."
                )
            }

            if element.label != label {
                record(
                    "Accessible label has leading or trailing whitespace",
                    "The label \"\(element.label)\" is padded with whitespace, which can affect VoiceOver pronunciation and Voice Control matching. Trim the label."
                )
            }

            let letters = label.filter(\.isLetter)
            if !letters.isEmpty, letters.allSatisfy(\.isUppercase),
               words.count > 1 || letters.count >= 5 {
                record(
                    "Accessible label is written in all capitals",
                    "The label \"\(label)\" is all-caps, so VoiceOver may spell it out letter by letter. Use sentence case in the accessible label and apply capitalisation visually."
                )
            }

            return issues
        }
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
                elementFrame: element.frame,
                reviewerHints: issueReviewerHints(for: element, auditType: "Label in Name")
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
                    elementFrame: element.frame,
                    reviewerHints: issueReviewerHints(for: element, auditType: "Adjustable Value")
                )
            }
    }

    /// Personal-data input purposes (WCAG 1.3.5) recognised from a field's
    /// label, identifier, or visible text. Evaluated in order, so the first
    /// match wins — "email address" resolves to email, not postal address.
    private static func recognisedInputPurpose(in tokens: Set<String>) -> String? {
        if tokens.contains("email") || tokens.contains("emailaddress") {
            return "an email address"
        }
        if !tokens.isDisjoint(with: ["password", "passcode", "passphrase", "pwd"]) {
            return "a password or passcode"
        }
        if !tokens.isDisjoint(with: ["username", "userid"]) {
            return "a username"
        }
        if !tokens.isDisjoint(with: ["phone", "telephone", "tel", "mobile"]) {
            return "a phone number"
        }
        if !tokens.isDisjoint(with: ["address", "street", "city", "postcode", "postalcode", "zip", "zipcode", "country"]) {
            return "a postal address"
        }
        if tokens.contains("birth") || !tokens.isDisjoint(with: ["birthday", "birthdate", "dob"]) {
            return "a date of birth"
        }
        if !tokens.isDisjoint(with: ["creditcard", "cardnumber", "cvv", "cvc"]) {
            return "a payment card number"
        }
        if tokens.contains("surname") {
            return "a person's name"
        }
        // "name" alone is ambiguous ("Album name"); only flag it with a
        // personal qualifier so generic title fields do not warn.
        if tokens.contains("name"),
           !tokens.isDisjoint(with: ["first", "last", "full", "given", "family", "middle", "nick"]) {
            return "a person's name"
        }
        return nil
    }

    /// Lower-cased alphanumeric tokens from a string, split on non-alphanumeric
    /// separators and camelCase boundaries ("signup.emailAddress" →
    /// ["signup", "email", "address"]).
    private static func purposeTokens(in string: String) -> [String] {
        var tokens: [String] = []
        var current = ""
        var previous: Character?
        for character in string {
            if character.isLetter || character.isNumber {
                if let previous, previous.isLowercase, character.isUppercase, !current.isEmpty {
                    tokens.append(current.lowercased())
                    current = String(character)
                } else {
                    current.append(character)
                }
                previous = character
            } else if !current.isEmpty {
                tokens.append(current.lowercased())
                current = ""
                previous = nil
            }
        }
        if !current.isEmpty {
            tokens.append(current.lowercased())
        }
        return tokens
    }

    /// Flags text-entry fields that appear to collect a recognised personal-data
    /// input purpose (email, password, phone, postal address, name, …) so a
    /// reviewer can confirm the field declares a matching `textContentType`
    /// (WCAG 1.3.5 Identify Input Purpose, Level AA).
    ///
    /// This is an advisory **warning**, not a deterministic failure: XCUITest
    /// snapshots do not expose `textContentType`, so the check cannot tell a
    /// correctly-configured field from one missing its input purpose — it only
    /// surfaces the fields where input purpose applies. Search fields are not
    /// passed here; their content is not information about the user.
    public static func inputPurposeIssues(textEntryElements: [AuditedElement]) -> [Issue] {
        textEntryElements.compactMap { element in
            var tokens: Set<String> = []
            tokens.formUnion(purposeTokens(in: element.label))
            tokens.formUnion(purposeTokens(in: element.identifier))
            for visible in element.visibleTextLabels {
                tokens.formUnion(purposeTokens(in: visible))
            }

            guard let purpose = recognisedInputPurpose(in: tokens) else { return nil }

            return Issue(
                auditType: "Input Purpose",
                compactDescription: "Verify the field collecting \(purpose) declares a textContentType",
                detailedDescription: "This field appears to collect \(purpose). WCAG 1.3.5 (Level AA) requires fields that collect information about the user to expose their input purpose so autofill and assistive technologies can identify them — set the matching `textContentType` (for example `.emailAddress`, `.password`, `.telephoneNumber`, or `.fullStreetAddress`). XCUITest cannot read `textContentType`, so this warning cannot confirm whether it is already set; verify in source.",
                elementIdentifier: element.identifier,
                elementLabel: element.label,
                elementFrame: element.frame,
                reviewerHints: issueReviewerHints(for: element, auditType: "Input Purpose"),
                severity: .warning
            )
        }
    }

    /// Flags elements that must carry an accessible description (interactive
    /// controls and meaningful images) but whose label is empty. This is the
    /// in-process equivalent of Apple's `sufficientElementDescription` audit,
    /// which only runs under XCTest. Severity `.error`: an unlabelled control or
    /// image is unusable with VoiceOver (WCAG 4.1.2 Name, Role, Value;
    /// WCAG 1.1.1 Non-text Content).
    public static func missingElementDescriptionIssues(elements: [AuditedElement]) -> [Issue] {
        elements
            .filter(\.requiresDescription)
            .filter { $0.label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .map { element in
                Issue(
                    auditType: "Element Description",
                    compactDescription: "Interactive or image element has no accessible label",
                    detailedDescription: "The element exposes no accessible label, so VoiceOver announces it only by role, or not at all. WCAG 4.1.2 requires every control to expose a name, and WCAG 1.1.1 requires meaningful images to have a text alternative.",
                    elementIdentifier: element.identifier,
                    elementLabel: element.label,
                    elementFrame: element.frame,
                    reviewerHints: issueReviewerHints(for: element, auditType: "Element Description"),
                    severity: .error
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
                    elementFrame: nil,
                    reviewerHints: deduplicatedReviewerHints(
                        group.flatMap { $0.element.reviewerHints }
                            + IssueReviewerHints.remediationHints(auditType: "Consistent Identification")
                    )
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

    private static func isUndersized(_ frame: CGRect, threshold: CGFloat) -> Bool {
        frame.width < threshold || frame.height < threshold
    }

    /// Whether the WCAG 2.5.8 spacing circles for the pair overlap a
    /// neighbouring target. Each undersized target carries a circle of the
    /// given radius centred on it; that circle must clear the other target's
    /// frame, and two undersized circles must clear each other.
    private static func spacingCirclesOverlap(
        _ first: CGRect,
        _ second: CGRect,
        firstUndersized: Bool,
        secondUndersized: Bool,
        radius: CGFloat
    ) -> Bool {
        let firstCentre = CGPoint(x: first.midX, y: first.midY)
        let secondCentre = CGPoint(x: second.midX, y: second.midY)

        if firstUndersized, distance(from: firstCentre, to: second) < radius {
            return true
        }
        if secondUndersized, distance(from: secondCentre, to: first) < radius {
            return true
        }
        if firstUndersized, secondUndersized,
           hypot(firstCentre.x - secondCentre.x, firstCentre.y - secondCentre.y) < radius * 2 {
            return true
        }
        return false
    }

    /// Shortest distance from a point to a rect; zero when the point is inside.
    private static func distance(from point: CGPoint, to rect: CGRect) -> CGFloat {
        let horizontal = max(0, max(rect.minX - point.x, point.x - rect.maxX))
        let vertical = max(0, max(rect.minY - point.y, point.y - rect.maxY))
        return hypot(horizontal, vertical)
    }

    private static func format(_ value: CGFloat) -> String {
        value.rounded() == value
            ? String(Int(value))
            : String(format: "%.1f", value)
    }
}
