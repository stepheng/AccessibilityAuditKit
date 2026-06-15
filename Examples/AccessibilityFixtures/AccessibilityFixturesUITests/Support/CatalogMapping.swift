//
//  CatalogMapping.swift
//  AccessibilityFixtures
//
//  Created by Stephen Gurnett on 14/06/2026.
//

import AccessibilityAuditReport
import AccessibilityAuditXCTestSupport
import XCTest

enum CatalogMapping {
    @available(iOS 17.0, *)
    static func supplementalType(_ kinds: [SupplementalKind]) -> SupplementalAuditType {
        var type: SupplementalAuditType = []
        for kind in kinds {
            switch kind {
            case .targetSize:                type.insert(.targetSize)
            case .targetSpacing:             type.insert(.targetSpacing)
            case .screenTitle:               type.insert(.screenTitle)
            case .duplicateLabels:           type.insert(.duplicateLabels)
            case .labelInName:               type.insert(.labelInName)
            case .genericLabels:             type.insert(.genericLabels)
            case .labelHygiene:              type.insert(.labelHygiene)
            case .adjustableValue:           type.insert(.adjustableValue)
            case .consistentIdentification:  type.insert(.consistentIdentification)
            case .inputPurpose:              type.insert(.inputPurpose)
            case .nonTextContrast:           type.insert(.nonTextContrast)
            }
        }
        return type
    }

    static func severity(_ expected: ExpectedSeverity) -> Severity {
        switch expected { case .error: return .error; case .warning: return .warning }
    }

    @available(iOS 17.0, *)
    static func auditType(_ kind: AppleAuditKind) -> XCUIAccessibilityAuditType {
        switch kind {
        case .contrast:                     return .contrast
        case .hitRegion:                    return .hitRegion
        case .sufficientElementDescription: return .sufficientElementDescription
        case .dynamicType:                  return .dynamicType
        case .textClipped:                  return .textClipped
        case .trait:                        return .trait
        case .elementDetection:             return .elementDetection
        }
    }
}
