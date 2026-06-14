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
/// Invoke from LLDB via `runDeferred`, **not** a direct `po AXAudit.run()`. A
/// direct `po` evaluates `run()` inside LLDB's expression sandbox, whose
/// exception guard breaks on the benign `NSException` UIKit throws (and catches
/// itself) while rendering and traversing the screen, aborting with "internal
/// ObjC exception breakpoint(-8)". `runDeferred` schedules the audit on the real
/// runloop, where UIKit swallows that exception and the audit completes.
///
/// Examples (at a paused breakpoint, or after `process interrupt`):
/// ```
/// (lldb) po [AXAudit runDeferred]      // audit current screen on the runloop…
/// (lldb) continue                      // …then let it run: prints findings + writes HTML
/// ```
/// For a multi-screen report, defer each call the same way, navigating between:
/// ```
/// (lldb) e -- (void)dispatch_async(dispatch_get_main_queue(), ^{ (void)[AXAudit recordScreen:@"Memories"]; })
/// (lldb) continue                      // navigate to the next screen, then repeat…
/// (lldb) e -- (void)dispatch_async(dispatch_get_main_queue(), ^{ (void)[AXAudit dump]; })
/// (lldb) continue                      // …then one combined report
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

    /// Keeps the audit in the host binary so `po AXAudit.run()` resolves from
    /// LLDB. The app calls this once at launch (under `#if DEBUG`); the module
    /// is otherwise unreferenced, so the linker dead-strips it — and an empty
    /// body or a dead-store reference anchors nothing the optimizer can't drop.
    /// The launch-argument check is a genuine runtime branch the linker cannot
    /// evaluate, so it must keep `run()` and its whole call graph. A normal
    /// launch does nothing; pass `-AXAuditAtLaunch` to audit immediately.
    nonisolated public static func link() {
        guard ProcessInfo.processInfo.arguments.contains("-AXAuditAtLaunch") else { return }
        Task { @MainActor in print(run()) }
    }

    /// Audits the current screen and writes a report immediately. Returns the
    /// report file path.
    @discardableResult
    @objc public static func run() -> String {
        record()
        return dump()
    }

    /// Schedules `run()` on the next main-loop turn and prints its output. This
    /// is the LLDB entry point: `po [AXAudit runDeferred]` then `continue`.
    /// Unlike a direct `po AXAudit.run()`, deferring to the runloop keeps the
    /// scan out of LLDB's expression sandbox, so the benign `NSException` UIKit
    /// throws and catches during the scan does not abort the call. Mirrors how
    /// `link()` runs the launch-time audit.
    @objc nonisolated public static func runDeferred() {
        Task { @MainActor in print(run()) }
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

        // Print the findings to the console so a person — or an LLM reading the
        // LLDB session — can act on them without opening the HTML report.
        print(report.renderPlainText())

        dumpCounter += 1
        let path = (NSTemporaryDirectory() as NSString)
            .appendingPathComponent("accessibility-audit-\(dumpCounter).html")
        do {
            try report.renderHTML().write(toFile: path, atomically: true, encoding: .utf8)
            print("\nAXAudit — full HTML report (with screenshots) written. Open with:\n  open \(path)")
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
