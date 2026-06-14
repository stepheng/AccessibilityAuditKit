//
//  Issue.swift
//  AccessibilityAuditReport
//
//  Created by Stephen Gurnett on 12/06/2026.
//

import CoreGraphics

public enum Severity: String, Sendable, Codable {
    case error
    case warning
}

public struct Acceptance: Sendable, Equatable {
    public let reason: String
    public let isStale: Bool

    public init(reason: String, isStale: Bool) {
        self.reason = reason
        self.isStale = isStale
    }
}

public struct Issue {
    public let auditType: String
    public let compactDescription: String
    public let detailedDescription: String
    public let elementIdentifier: String
    public let elementLabel: String
    public let elementFrame: CGRect?
    /// Frames of any further elements this single finding covers, beyond the
    /// primary `elementFrame`. Used by checks that flag a *group* of elements
    /// (e.g. Duplicate Labels) so the report can highlight every member, not
    /// just the first. Empty for findings about a single element.
    public let additionalFrames: [CGRect]
    public let severity: Severity
    public let acceptance: Acceptance?

    public init(
        auditType: String,
        compactDescription: String,
        detailedDescription: String,
        elementIdentifier: String,
        elementLabel: String,
        elementFrame: CGRect?,
        additionalFrames: [CGRect] = [],
        severity: Severity = .error,
        acceptance: Acceptance? = nil
    ) {
        self.auditType = auditType
        self.compactDescription = compactDescription
        self.detailedDescription = detailedDescription
        self.elementIdentifier = elementIdentifier
        self.elementLabel = elementLabel
        self.elementFrame = elementFrame
        self.additionalFrames = additionalFrames
        self.severity = severity
        self.acceptance = acceptance
    }

    /// Returns a copy of this issue with the given acceptance annotation.
    public func with(acceptance: Acceptance?) -> Issue {
        Issue(
            auditType: auditType,
            compactDescription: compactDescription,
            detailedDescription: detailedDescription,
            elementIdentifier: elementIdentifier,
            elementLabel: elementLabel,
            elementFrame: elementFrame,
            additionalFrames: additionalFrames,
            severity: severity,
            acceptance: acceptance
        )
    }
}
