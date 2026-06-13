//
//  AcceptanceBaseline.swift
//  AccessibilityAuditReport
//

import AccessibilityAuditReport
import Foundation

/// Loads a checked-in JSON acceptance baseline into `[AcceptanceRule]`.
/// Decoding errors (malformed JSON, a rule missing its required `reason`)
/// surface to the caller rather than silently yielding an empty baseline.
public enum AcceptanceBaseline {
    public static func load(from url: URL) throws -> [AcceptanceRule] {
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode([AcceptanceRule].self, from: data)
    }
}
