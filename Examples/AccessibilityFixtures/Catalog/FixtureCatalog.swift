//
//  FixtureCatalog.swift
//  AccessibilityFixtures
//
//  Created by Stephen Gurnett on 15/06/2026.
//

//  The single source of truth for app, tests, and docs.
import Foundation

enum FixtureCatalog {
    static let all: [FixtureCheck] = [

        // ── Tier 1: deterministic supplemental, single screen ──────────────
        FixtureCheck(
            id: "targetSizeMinimum", title: "Target Size (Minimum)", wcag: "2.5.8", level: "AA",
            category: .supplemental, tier: .exact, severity: .error,
            auditType: "Target Size (Minimum)", supplementalKinds: [.targetSize],
            screenId: "targetSize",
            failIdentifiers: ["targetSize.min20"], passIdentifiers: ["targetSize.ok44"],
            summary: "Interactive targets smaller than 24×24pt.",
            expectedOutcome: "20pt button flagged (error); 44pt button clean."),
        FixtureCheck(
            id: "targetSizeEnhanced", title: "Target Size (Enhanced)", wcag: "2.5.5", level: "AAA",
            category: .supplemental, tier: .exact, severity: .warning,
            auditType: "Target Size (Enhanced)", supplementalKinds: [.targetSize],
            screenId: "targetSize",
            failIdentifiers: ["targetSize.enhanced30"], passIdentifiers: ["targetSize.ok44"],
            summary: "Targets between 24 and 44pt.",
            expectedOutcome: "30pt button flagged (warning); 44pt button clean."),
        FixtureCheck(
            id: "targetSpacing", title: "Target Spacing", wcag: "2.5.8", level: "AA",
            category: .supplemental, tier: .exact, severity: .error,
            auditType: "Target Spacing", supplementalKinds: [.targetSpacing],
            screenId: "targetSpacing",
            failIdentifiers: ["targetSpacing.failA"],
            passIdentifiers: ["targetSpacing.passA", "targetSpacing.passB"],
            failMatch: .any,
            summary: "Undersized targets whose 24pt spacing circles overlap.",
            expectedOutcome: "Close undersized pair flagged; well-spaced pair clean."),
        FixtureCheck(
            id: "screenTitle", title: "Screen Title", wcag: "2.4.2", level: "AA",
            category: .supplemental, tier: .exact, severity: .error,
            auditType: "Screen Title", supplementalKinds: [.screenTitle],
            failScreenId: "screenTitleFail", passScreenId: "screenTitlePass",
            summary: "Navigation bars with no title text.",
            expectedOutcome: "Empty-title nav bar flagged; titled nav bar clean."),
        FixtureCheck(
            id: "duplicateLabels", title: "Duplicate Labels", wcag: "2.4.6", level: "AA",
            category: .supplemental, tier: .exact, severity: .error,
            auditType: "Duplicate Labels", supplementalKinds: [.duplicateLabels],
            screenId: "duplicateLabels",
            failIdentifiers: ["dup.openA", "dup.openB"],
            passIdentifiers: ["dup.photos", "dup.files"],
            failMatch: .any,
            summary: "Interactive elements sharing an accessible label.",
            expectedOutcome: "Two “Open” buttons flagged; distinct labels clean."),
        FixtureCheck(
            id: "labelInName", title: "Label in Name", wcag: "2.5.3", level: "A",
            category: .supplemental, tier: .exact, severity: .error,
            auditType: "Label in Name", supplementalKinds: [.labelInName],
            screenId: "labelInName",
            failIdentifiers: ["labelInName.fail"], passIdentifiers: ["labelInName.pass"],
            summary: "Accessible label missing the element's visible text.",
            expectedOutcome: "Visible “Submit”/label “Send” flagged; label “Submit form” clean."),
        FixtureCheck(
            id: "genericLabel", title: "Generic Label", wcag: "2.4.4", level: "A",
            category: .supplemental, tier: .exact, severity: .warning,
            auditType: "Generic Label", supplementalKinds: [.genericLabels],
            screenId: "genericLabel",
            failIdentifiers: ["generic.fail"], passIdentifiers: ["generic.pass"],
            summary: "Role-word / asset-name / code-like labels.",
            expectedOutcome: "Label “Button” flagged (warning); “Delete photo” clean."),
        FixtureCheck(
            id: "labelHygiene", title: "Label Hygiene", wcag: "4.1.2", level: "A",
            category: .supplemental, tier: .exact, severity: .warning,
            auditType: "Label Hygiene", supplementalKinds: [.labelHygiene],
            screenId: "labelHygiene",
            failIdentifiers: ["hygiene.fail"], passIdentifiers: ["hygiene.pass"],
            summary: "Redundant role suffix / whitespace / all-caps labels.",
            expectedOutcome: "Label “Save button” flagged (warning); “Save” clean."),
        FixtureCheck(
            id: "adjustableValue", title: "Adjustable Value", wcag: "4.1.2", level: "A",
            category: .supplemental, tier: .exact, severity: .error,
            auditType: "Adjustable Value", supplementalKinds: [.adjustableValue],
            screenId: "adjustableValue",
            failIdentifiers: ["adjustable.fail"], passIdentifiers: ["adjustable.pass"],
            summary: "Sliders/pickers exposing no accessibility value.",
            expectedOutcome: "Empty-value slider flagged; SwiftUI Slider clean."),
        FixtureCheck(
            id: "inputPurpose", title: "Input Purpose", wcag: "1.3.5", level: "AA",
            category: .supplemental, tier: .exact, severity: .warning,
            auditType: "Input Purpose", supplementalKinds: [.inputPurpose],
            screenId: "inputPurpose",
            failIdentifiers: ["inputPurpose.fail"], passIdentifiers: ["inputPurpose.pass"],
            summary: "Personal-data fields that should declare a textContentType.",
            expectedOutcome: "“Email address” field flagged (warning); “Album name” clean."),

        // ── Cross-screen ───────────────────────────────────────────────────
        FixtureCheck(
            id: "consistentIdentification", title: "Consistent Identification", wcag: "3.2.4", level: "AA",
            category: .supplemental, tier: .exact, severity: .error,
            auditType: "Consistent Identification", supplementalKinds: [.consistentIdentification],
            failScreenId: "cidA", passScreenId: "cidB",
            failIdentifiers: ["cid.control"], passIdentifiers: ["cid.consistent"],
            summary: "Same identifier, different label across screens.",
            expectedOutcome: "“cid.control” (Profile/Account) flagged; “cid.consistent” clean."),

        // ── Tier 2: Apple performAccessibilityAudit (lenient) ──────────────
        // Downgraded to .manual: Apple's `.contrast` audit did not fire on a clear
        // ~1.5:1 grey-on-white text violation on iPhone 16 / iOS 18.5, across a
        // value tweak (0.72→0.85) and a structural change (full-screen white
        // backdrop). The other Apple audits fire, so this is specific to the
        // contrast audit in this environment, not the harness. Gallery-only;
        // verify by hand (and re-promote to .lenient if a future OS detects it).
        FixtureCheck(
            id: "appleContrast", title: "Contrast", wcag: "1.4.3", level: "AA",
            category: .appleAudit, tier: .manual, auditType: "Contrast", appleKind: .contrast,
            failScreenId: "apple.contrast.fail", passScreenId: "apple.contrast.pass",
            summary: "Text contrast below 4.5:1.",
            expectedOutcome: "Light-grey-on-white text flagged; black-on-white clean. (Downgraded: not auto-detected on simulator.)"),
        FixtureCheck(
            id: "appleHitRegion", title: "Hit Region", wcag: "—", level: "—",
            category: .appleAudit, tier: .lenient, auditType: "Hit Region", appleKind: .hitRegion,
            failScreenId: "apple.hitRegion.fail", passScreenId: "apple.hitRegion.pass",
            summary: "Tap target hit region below the minimum.",
            expectedOutcome: "Tiny control flagged; 44pt control clean."),
        FixtureCheck(
            id: "appleSufficientDescription", title: "Sufficient Element Description", wcag: "—", level: "—",
            category: .appleAudit, tier: .lenient, auditType: "Sufficient Element Description",
            appleKind: .sufficientElementDescription,
            failScreenId: "apple.description.fail", passScreenId: "apple.description.pass",
            summary: "Controls with no accessible description.",
            expectedOutcome: "Unlabelled image button flagged; labelled button clean."),
        FixtureCheck(
            id: "appleDynamicType", title: "Dynamic Type", wcag: "1.4.4", level: "AA",
            category: .appleAudit, tier: .lenient, auditType: "Dynamic Type", appleKind: .dynamicType,
            failScreenId: "apple.dynamicType.fail", passScreenId: "apple.dynamicType.pass",
            summary: "Text that does not scale with Dynamic Type.",
            expectedOutcome: "Fixed-point text flagged; scalable text clean."),
        FixtureCheck(
            id: "appleTextClipped", title: "Text Clipped", wcag: "—", level: "—",
            category: .appleAudit, tier: .lenient, auditType: "Text Clipped", appleKind: .textClipped,
            failScreenId: "apple.textClipped.fail", passScreenId: "apple.textClipped.pass",
            summary: "Text truncated/clipped by its frame.",
            expectedOutcome: "Clipped text flagged; full text clean."),
        // Downgraded to .manual: Apple's `.trait` audit flags trait *conflicts*,
        // not a plain "missing header trait", so this fixture cannot fire
        // deterministically on the simulator. Gallery-only; verify by hand.
        FixtureCheck(
            id: "appleTrait", title: "Trait", wcag: "—", level: "—",
            category: .appleAudit, tier: .manual, auditType: "Trait", appleKind: .trait,
            failScreenId: "apple.trait.fail", passScreenId: "apple.trait.pass",
            summary: "Conflicting / missing accessibility traits.",
            expectedOutcome: "Mis-trait element flagged; correct traits clean. (Downgraded: not auto-detected.)"),
        // Downgraded to .manual: Apple's `.elementDetection` audit (undetectable
        // elements, e.g. text baked into images) does not fire for a translucent
        // SwiftUI overlay, so this cannot be asserted deterministically on the
        // simulator. Gallery-only; verify by hand.
        FixtureCheck(
            id: "appleElementDetection", title: "Element Detection", wcag: "—", level: "—",
            category: .appleAudit, tier: .manual, auditType: "Element Detection", appleKind: .elementDetection,
            failScreenId: "apple.elementDetection.fail", passScreenId: "apple.elementDetection.pass",
            summary: "Elements the audit cannot properly detect.",
            expectedOutcome: "Obscured/overlapping element flagged; clean layout clean. (Downgraded: not auto-detected.)"),

        // ── Tier 3: Orientation ────────────────────────────────────────────
        FixtureCheck(
            id: "orientation", title: "Orientation", wcag: "1.3.4", level: "AA",
            category: .orientation, tier: .lenient, auditType: "Orientation",
            screenId: "orientation",
            summary: "Layout locked to a single orientation.",
            expectedOutcome: "Launched with -lockOrientation portrait: flagged; normal launch clean."),

        // ── Tier 4: Manual review (gallery only) ───────────────────────────
        FixtureCheck(
            id: "voiceOverFocusOrder", title: "VoiceOver Focus Order", wcag: "1.3.2 / 2.4.3", level: "A",
            category: .manualReview, tier: .manual, screenId: "manual.voiceOverFocusOrder",
            summary: "Focus order follows the visual / task flow.",
            expectedOutcome: "Swipe through with VoiceOver: the good column reads top-to-bottom; the bad column jumps around."),
        FixtureCheck(
            id: "fullKeyboardAccess", title: "Full Keyboard Access", wcag: "2.1.1", level: "A",
            category: .manualReview, tier: .manual, screenId: "manual.fullKeyboardAccess",
            summary: "All controls reachable/activatable by keyboard.",
            expectedOutcome: "With Full Keyboard Access on, every control in the good row is reachable; the bad row traps focus."),
        FixtureCheck(
            id: "switchControl", title: "Switch Control", wcag: "2.1.1", level: "A",
            category: .manualReview, tier: .manual, screenId: "manual.switchControl",
            summary: "All controls reachable/activatable by Switch Control.",
            expectedOutcome: "With Switch Control scanning, the good controls are reachable; the bad ones are skipped."),
        FixtureCheck(
            id: "voiceControlNaming", title: "Voice Control Naming", wcag: "2.5.3", level: "A",
            category: .manualReview, tier: .manual, screenId: "manual.voiceControlNaming",
            summary: "Names are unique enough to speak.",
            expectedOutcome: "“Show numbers” in Voice Control: the good buttons have speakable unique names; the bad ones collide."),
        FixtureCheck(
            id: "groupedContent", title: "Grouped Content", wcag: "1.3.1", level: "A",
            category: .manualReview, tier: .manual, screenId: "manual.groupedContent",
            summary: "Custom groups expose the right children.",
            expectedOutcome: "VoiceOver on the good card reads it as one grouped element; the bad card exposes stray fragments."),

        // ── Tier 5: Scripted assertion fixtures ───────────────────────────
        FixtureCheck(
            id: "nonTextContrast", title: "Non-text Contrast", wcag: "1.4.11", level: "AA",
            category: .scripted, tier: .scripted,
            severity: .warning, auditType: "Non-text Contrast", supplementalKinds: [.nonTextContrast],
            screenId: "future.nonTextContrast",
            summary: "Screenshot-backed check for two-toned graphical objects.",
            expectedOutcome: "Low-contrast glyph flagged as advisory warning; high-contrast glyph clean."),
        FixtureCheck(
            id: "statusMessages", title: "Status Messages", wcag: "4.1.3", level: "AA",
            category: .scripted, tier: .scripted,
            severity: .warning, auditType: "Status Messages",
            screenId: "future.statusMessages",
            summary: "Scripted observation of status-change announcements.",
            expectedOutcome: "Silent status change flagged as advisory warning; announced change clean."),
        FixtureCheck(
            id: "resizeReflow", title: "Resize Text / Reflow", wcag: "1.4.4 / 1.4.10", level: "AA",
            category: .scripted, tier: .scripted,
            severity: .warning, auditType: "Resize Text / Reflow",
            screenId: "future.resizeReflow",
            summary: "Scripted large-text layout observation.",
            expectedOutcome: "Fixed-width overflow flagged as advisory warning; wrapping text clean."),
    ]

    static func first(id: String) -> FixtureCheck? { all.first { $0.id == id } }
}
