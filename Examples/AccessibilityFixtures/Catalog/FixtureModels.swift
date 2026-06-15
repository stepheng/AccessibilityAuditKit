//
//  FixtureModels.swift
//  AccessibilityFixtures
//
//  Created by Stephen Gurnett on 14/06/2026.
//

//  Pure data shared by the app target and the UITest target (compiled into both).
//  MUST NOT import SwiftUI, UIKit, or the audit package — the app target does not
//  link the package, and keeping this dependency-free is what allows dual membership.
import Foundation

enum FixtureCategory: String, CaseIterable {
    case supplemental   = "Supplemental checks"
    case appleAudit     = "Apple performAccessibilityAudit"
    case orientation    = "Orientation"
    case manualReview   = "Manual review"
    case scripted       = "Scripted assertions"
}

enum AssertionTier {
    case exact      // assert auditType + element identifiers + severity (single screen)
    case lenient    // assert >=1 issue of auditType on fail screen, 0 on pass screen
    case scripted   // asserted by a bespoke fixture/integration test
    case manual     // gallery only, no automated assertion
}

enum ExpectedSeverity { case error, warning }

/// Which supplemental scanner check(s) a fixture exercises. Mirrors
/// `SupplementalAuditType` but stays package-free; the UITest maps it across.
enum SupplementalKind {
    case targetSize, targetSpacing, screenTitle, duplicateLabels
    case labelInName, genericLabels, labelHygiene, adjustableValue
    case consistentIdentification, inputPurpose, nonTextContrast
}

/// Which Apple audit a fixture exercises.
enum AppleAuditKind {
    case contrast, hitRegion, sufficientElementDescription
    case dynamicType, textClipped, trait, elementDetection
}

/// How fail identifiers must match: `.all` = every listed id must be flagged;
/// `.any` = at least one (used where the check emits one issue per group/pair).
enum FailMatch { case all, any }

struct FixtureCheck: Identifiable {
    let id: String
    let title: String
    let wcag: String
    let level: String
    let category: FixtureCategory
    let tier: AssertionTier
    let severity: ExpectedSeverity?
    let auditType: String?
    let supplementalKinds: [SupplementalKind]
    let appleKind: AppleAuditKind?
    let screenId: String?
    let failScreenId: String?
    let passScreenId: String?
    let failIdentifiers: [String]
    let passIdentifiers: [String]
    let failMatch: FailMatch
    let summary: String
    let expectedOutcome: String

    init(
        id: String, title: String, wcag: String, level: String,
        category: FixtureCategory, tier: AssertionTier,
        severity: ExpectedSeverity? = nil, auditType: String? = nil,
        supplementalKinds: [SupplementalKind] = [], appleKind: AppleAuditKind? = nil,
        screenId: String? = nil, failScreenId: String? = nil, passScreenId: String? = nil,
        failIdentifiers: [String] = [], passIdentifiers: [String] = [],
        failMatch: FailMatch = .all, summary: String, expectedOutcome: String
    ) {
        self.id = id; self.title = title; self.wcag = wcag; self.level = level
        self.category = category; self.tier = tier; self.severity = severity
        self.auditType = auditType; self.supplementalKinds = supplementalKinds
        self.appleKind = appleKind; self.screenId = screenId
        self.failScreenId = failScreenId; self.passScreenId = passScreenId
        self.failIdentifiers = failIdentifiers; self.passIdentifiers = passIdentifiers
        self.failMatch = failMatch; self.summary = summary; self.expectedOutcome = expectedOutcome
    }
}
