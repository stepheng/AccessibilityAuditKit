//
//  ScreenResult.swift
//  AccessibilityAuditReport
//
//  Created by Stephen Gurnett on 12/06/2026.
//

import CoreGraphics
import Foundation

public struct ScreenResult {
    public let variant: String
    public let name: String
    public let screenshotPNGData: Data
    public let screenshotSize: CGSize
    public let issues: [Issue]

    public init(
        variant: String = "Default",
        name: String,
        screenshotPNGData: Data,
        screenshotSize: CGSize,
        issues: [Issue]
    ) {
        self.variant = variant
        self.name = name
        self.screenshotPNGData = screenshotPNGData
        self.screenshotSize = screenshotSize
        self.issues = issues
    }
}
