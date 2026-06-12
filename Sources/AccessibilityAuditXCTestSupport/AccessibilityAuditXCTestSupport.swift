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
            issues.append(
                Issue(
                    auditType: AccessibilityAuditTypeNameFormatter.name(for: issue.auditType),
                    compactDescription: issue.compactDescription,
                    detailedDescription: issue.detailedDescription,
                    elementIdentifier: element?.identifier ?? "No element identifier",
                    elementLabel: element?.label ?? "No element label",
                    elementFrame: element?.frame
                )
            )
            return true
        }

        if !supplementalChecks.isEmpty {
            issues += SupplementalAuditScanner.issues(in: try snapshot(), checks: supplementalChecks)
        }

        let screenshot = screenshot ?? XCUIScreen.main.screenshot()
        report.record(
            ScreenResult(
                variant: variant,
                name: name,
                screenshotPNGData: screenshot.pngRepresentation,
                screenshotSize: screenshot.image.size,
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
