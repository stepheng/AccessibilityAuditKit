//
//  AcceptanceRule.swift
//  AccessibilityAuditReport
//

import Foundation

/// A checked-in declaration that a specific finding has been accepted — either
/// a false positive or a violation human review judged acceptable under the
/// current conditions. Decoded from a JSON baseline file. `reason` is required.
public struct AcceptanceRule: Codable, Sendable, Equatable {
    public let screen: String
    public let variant: String?
    public let auditType: String
    public let elementIdentifier: String?
    public let elementLabel: String?
    public let context: String?
    public let reason: String

    public init(
        screen: String,
        variant: String? = nil,
        auditType: String,
        elementIdentifier: String? = nil,
        elementLabel: String? = nil,
        context: String? = nil,
        reason: String
    ) {
        self.screen = screen
        self.variant = variant
        self.auditType = auditType
        self.elementIdentifier = elementIdentifier
        self.elementLabel = elementLabel
        self.context = context
        self.reason = reason
    }
}
