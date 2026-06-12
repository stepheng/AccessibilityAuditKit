//
//  Issue.swift
//  AccessibilityAuditReport
//
//  Created by Stephen Gurnett on 12/06/2026.
//

import CoreGraphics

public struct Issue {
    public let auditType: String
    public let compactDescription: String
    public let detailedDescription: String
    public let elementIdentifier: String
    public let elementLabel: String
    public let elementFrame: CGRect?

    public init(
        auditType: String,
        compactDescription: String,
        detailedDescription: String,
        elementIdentifier: String,
        elementLabel: String,
        elementFrame: CGRect?
    ) {
        self.auditType = auditType
        self.compactDescription = compactDescription
        self.detailedDescription = detailedDescription
        self.elementIdentifier = elementIdentifier
        self.elementLabel = elementLabel
        self.elementFrame = elementFrame
    }
}
