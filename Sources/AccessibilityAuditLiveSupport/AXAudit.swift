//
//  AXAudit.swift
//  AccessibilityAuditReport
//
//  Created by Stephen Gurnett on 14/06/2026.
//

#if DEBUG && canImport(UIKit)
import AccessibilityAuditReport
import Foundation
import UIKit

/// LLDB-callable accessibility audit for the manually-running app.
///
/// Examples (at a paused breakpoint, or after `process interrupt`):
/// ```
/// (lldb) po AXAudit.run()              // audit current screen, write report, print path
/// (lldb) po AXAudit.record("Memories") // accumulate screens…
/// (lldb) po AXAudit.dump()             // …then one combined report
/// ```
@MainActor
@objc(AXAudit)
public final class AXAudit: NSObject {
    private static var report = AccessibilityAuditHTMLReport(title: "In-Process Accessibility Audit")
    private static var screenCounter = 0
    private static var dumpCounter = 0

    /// Checks the in-process path cannot run; surfaced as manual follow-up.
    private static let inspectorPointer =
        "These need Accessibility Inspector — in-process auditing can't do them reliably for SwiftUI: " +
        "Contrast, Text Clipped, Element Detection. In Xcode: Open Developer Tool → " +
        "Accessibility Inspector → audit this screen."

    /// Audits the current screen and writes a report immediately. Returns the
    /// report file path.
    @discardableResult
    @objc public static func run() -> String {
        record()
        return dump()
    }

    /// Audits the current screen under an explicit name, recording it into the
    /// in-progress session. Returns the screen's issue count.
    @discardableResult
    @objc(recordScreen:) public static func record(_ name: String) -> Int {
        guard let scan = LiveAccessibilityScanner.scan() else {
            print("AXAudit: no foreground window found.")
            return 0
        }
        report.record(
            ScreenResult(
                name: name,
                screenshotPNGData: scan.screenshotPNGData,
                screenshotSize: scan.screenshotSize,
                issues: scan.issues
            )
        )
        report.recordElementInventory(screenName: name, elements: scan.inventory)
        print("AXAudit — \(name): \(scan.issues.count) issue(s).")
        return scan.issues.count
    }

    /// Audits the current screen under an auto-generated name.
    @discardableResult
    @objc public static func record() -> Int {
        screenCounter += 1
        return record("Screen \(screenCounter)")
    }

    /// Renders the accumulated report, writes it to a temp file, resets the
    /// session, and returns the file path.
    ///
    /// When more than one screen was recorded, a synthetic "Consistent
    /// Identification" screen is appended. Its screenshot comes from a fresh
    /// scan of whatever screen is on display at dump time, which may differ
    /// from any screen you explicitly recorded.
    @discardableResult
    @objc public static func dump() -> String {
        if report.elementInventories.count > 1,
           let scan = LiveAccessibilityScanner.scan() {
            report.recordConsistentIdentificationCheck(
                screenshotPNGData: scan.screenshotPNGData,
                screenshotSize: scan.screenshotSize
            )
        }
        report.additionalManualChecks = [inspectorPointer]

        dumpCounter += 1
        let path = (NSTemporaryDirectory() as NSString)
            .appendingPathComponent("accessibility-audit-\(dumpCounter).html")
        do {
            try report.renderHTML().write(toFile: path, atomically: true, encoding: .utf8)
            print("AXAudit — report written. Open with:\n  open \(path)")
        } catch {
            print("AXAudit — failed to write report: \(error)")
        }
        reset()
        return path
    }

    /// Discards the in-progress session. The report filename counter is
    /// intentionally preserved across resets so successive reports keep unique
    /// `accessibility-audit-<n>.html` names within a process.
    @objc public static func reset() {
        report = AccessibilityAuditHTMLReport(title: "In-Process Accessibility Audit")
        screenCounter = 0
    }
}
#endif
