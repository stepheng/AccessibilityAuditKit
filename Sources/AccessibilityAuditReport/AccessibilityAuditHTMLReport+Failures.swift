//
//  AccessibilityAuditHTMLReport+Failures.swift
//  AccessibilityAuditReport
//
//  Created by Stephen Gurnett on 12/06/2026.
//

import CoreGraphics
import Foundation

public extension AccessibilityAuditHTMLReport {
    mutating func recordReadinessFailure(
        for name: String,
        variant: String,
        screenshotPNGData: Data,
        screenshotSize: CGSize
    ) {
        record(
            ScreenResult(
                variant: variant,
                name: name,
                screenshotPNGData: screenshotPNGData,
                screenshotSize: screenshotSize,
                issues: [
                    Issue(
                        auditType: "Readiness Failure",
                        compactDescription: "\(name) did not finish rendering before the audit timeout.",
                        detailedDescription: "The automated audit skipped this screen because expected content was not ready before screenshot capture.",
                        elementIdentifier: "No element identifier",
                        elementLabel: "No element label",
                        elementFrame: nil
                    )
                ]
            )
        )
    }

    mutating func recordNavigationFailure(
        for name: String,
        variant: String,
        reason: String,
        screenshotPNGData: Data,
        screenshotSize: CGSize
    ) {
        record(
            ScreenResult(
                variant: variant,
                name: name,
                screenshotPNGData: screenshotPNGData,
                screenshotSize: screenshotSize,
                issues: [
                    Issue(
                        auditType: "Navigation Failure",
                        compactDescription: reason,
                        detailedDescription: "The automated audit skipped this screen because the visible UI did not match the expected app screen.",
                        elementIdentifier: "No element identifier",
                        elementLabel: "No element label",
                        elementFrame: nil
                    )
                ]
            )
        )
    }
}
