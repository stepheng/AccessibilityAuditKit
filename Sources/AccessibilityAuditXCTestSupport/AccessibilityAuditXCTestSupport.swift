//
//  AccessibilityAuditXCTestSupport.swift
//  AccessibilityAuditReport
//
//  Created by Stephen Gurnett on 12/06/2026.
//

import AccessibilityAuditReport
import Foundation
import XCTest

public enum AccessibilityAuditTypeNameFormatter {
    @available(iOS 17.0, macOS 14.0, *)
    public static func name(for auditType: XCUIAccessibilityAuditType) -> String {
        var names: [String] = []

        if auditType.contains(.contrast) {
            names.append("Contrast")
        }
        if auditType.contains(.elementDetection) {
            names.append("Element Detection")
        }
        if auditType.contains(.hitRegion) {
            names.append("Hit Region")
        }
        if auditType.contains(.sufficientElementDescription) {
            names.append("Sufficient Element Description")
        }
        #if os(iOS)
        if auditType.contains(.dynamicType) {
            names.append("Dynamic Type")
        }
        if auditType.contains(.textClipped) {
            names.append("Text Clipped")
        }
        if auditType.contains(.trait) {
            names.append("Trait")
        }
        #endif

        return names.isEmpty ? "Audit Type \(auditType.rawValue)" : names.joined(separator: ", ")
    }
}

public enum AccessibilityAuditIssueHints {
    public static func locatorHints(
        auditType: String,
        identifier: String,
        label: String
    ) -> [IssueReviewerHint] {
        IssueReviewerHints.elementLocatorHints(
            identifier: identifier,
            label: label,
            auditType: auditType
        ) + IssueReviewerHints.remediationHints(auditType: auditType)
    }
}

public extension XCTestCase {
    @MainActor
    func attachAccessibilityAuditReport(
        _ report: AccessibilityAuditHTMLReport,
        name: String = "Accessibility Audit Report"
    ) {
        let attachment = XCTAttachment(
            data: Data(report.renderHTML().utf8),
            uniformTypeIdentifier: "public.html"
        )
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}

public extension AccessibilityAuditHTMLReport {
    @MainActor
    mutating func recordReadinessFailure(
        for name: String,
        variant: String,
        screenshot: XCUIScreenshot = XCUIScreen.main.screenshot()
    ) {
        recordReadinessFailure(
            for: name,
            variant: variant,
            screenshotPNGData: screenshot.pngRepresentation,
            screenshotSize: screenshot.image.size
        )
    }

    /// Evaluates the Consistent Identification check (WCAG 3.2.4) over every
    /// element inventory recorded so far and appends the result screen.
    @MainActor
    mutating func recordConsistentIdentificationCheck(
        variant: String = "Default",
        screenshot: XCUIScreenshot = XCUIScreen.main.screenshot()
    ) {
        recordConsistentIdentificationCheck(
            variant: variant,
            screenshotPNGData: screenshot.pngRepresentation,
            screenshotSize: screenshot.image.size
        )
    }

    @MainActor
    mutating func recordNavigationFailure(
        for name: String,
        variant: String,
        reason: String,
        screenshot: XCUIScreenshot = XCUIScreen.main.screenshot()
    ) {
        recordNavigationFailure(
            for: name,
            variant: variant,
            reason: reason,
            screenshotPNGData: screenshot.pngRepresentation,
            screenshotSize: screenshot.image.size
        )
    }
}

public extension XCUIApplication {
    @MainActor
    @available(iOS 17.0, macOS 14.0, *)
    func recordAccessibilityAuditScreen(
        _ name: String,
        variant: String = "Default",
        auditTypes: XCUIAccessibilityAuditType,
        supplementalChecks: SupplementalAuditType = [],
        in report: inout AccessibilityAuditHTMLReport,
        screenshot: XCUIScreenshot? = nil
    ) throws {
        var issues: [Issue] = []

        try performAccessibilityAudit(for: auditTypes) { issue in
            let element = issue.element
            let auditTypeName = AccessibilityAuditTypeNameFormatter.name(for: issue.auditType)
            let identifier = element?.identifier ?? "No element identifier"
            let label = element?.label ?? "No element label"
            issues.append(
                Issue(
                    auditType: auditTypeName,
                    compactDescription: issue.compactDescription,
                    detailedDescription: issue.detailedDescription,
                    elementIdentifier: identifier,
                    elementLabel: label,
                    elementFrame: element?.frame,
                    reviewerHints: AccessibilityAuditIssueHints.locatorHints(
                        auditType: auditTypeName,
                        identifier: identifier,
                        label: label
                    )
                )
            )
            return true
        }

        let capturedScreenshot = screenshot ?? XCUIScreen.main.screenshot()

        if !supplementalChecks.isEmpty {
            let snapshot = try snapshot()
            issues += SupplementalAuditScanner.issues(in: snapshot, checks: supplementalChecks)
            if supplementalChecks.contains(.consistentIdentification) {
                report.recordElementInventory(
                    screenName: name,
                    elements: SupplementalAuditScanner.interactiveElementInventory(in: snapshot)
                )
            }
            // A failed PNG decode skips the check silently — it is an advisory
            // warning, so a decode failure must not fail the test run.
            if supplementalChecks.contains(.nonTextContrast),
               let image = PixelImage(pngData: capturedScreenshot.pngRepresentation) {
                let pointSize = capturedScreenshot.image.size
                let scale = pointSize.width > 0 ? CGFloat(image.width) / pointSize.width : 1
                issues += SupplementalAccessibilityChecks.nonTextContrastIssues(
                    graphicalElements: SupplementalAuditScanner.graphicalElementInventory(in: snapshot),
                    image: image,
                    scale: scale
                )
            }
        }

        report.record(
            ScreenResult(
                variant: variant,
                name: name,
                screenshotPNGData: capturedScreenshot.pngRepresentation,
                screenshotSize: capturedScreenshot.image.size,
                issues: issues
            )
        )
    }

    #if os(iOS)
    /// Rotates the device from portrait to landscape, compares the root
    /// window's proportions before and after, and records an Orientation
    /// issue (WCAG 1.3.4) when the layout does not respond. The device is
    /// restored to its starting orientation afterwards.
    @MainActor
    func recordOrientationLockCheck(
        _ name: String = "Orientation",
        variant: String = "Default",
        settleTime: TimeInterval = 1,
        in report: inout AccessibilityAuditHTMLReport
    ) {
        let device = XCUIDevice.shared
        let initialOrientation = device.orientation

        device.orientation = .portrait
        RunLoop.current.run(until: Date(timeIntervalSinceNow: settleTime))
        let portraitWindowSize = windows.firstMatch.frame.size

        device.orientation = .landscapeLeft
        RunLoop.current.run(until: Date(timeIntervalSinceNow: settleTime))
        let landscapeWindowSize = windows.firstMatch.frame.size
        let screenshot = XCUIScreen.main.screenshot()

        device.orientation = initialOrientation == .unknown ? .portrait : initialOrientation
        RunLoop.current.run(until: Date(timeIntervalSinceNow: settleTime))

        report.record(
            ScreenResult(
                variant: variant,
                name: name,
                screenshotPNGData: screenshot.pngRepresentation,
                screenshotSize: screenshot.image.size,
                issues: SupplementalAccessibilityChecks.orientationLockIssues(
                    portraitWindowSize: portraitWindowSize,
                    landscapeWindowSize: landscapeWindowSize
                )
            )
        )
    }
    #endif
}
