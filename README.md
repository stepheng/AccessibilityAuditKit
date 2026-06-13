# AccessibilityAuditReport

`AccessibilityAuditReport` builds an HTML accessibility audit report from screen snapshots and audit issues. It is designed for iOS UI test suites that navigate an app, run accessibility audits, capture screenshots, and attach a single HTML report to the test result.

The generated HTML includes:

- Summary counts by screen and audit variant.
- Issue details from XCTest accessibility audits.
- Reduced-size screenshots with annotated issue rectangles.
- Hover and keyboard-focus highlighting between issue rows and screenshot rectangles.
- Full-size screenshot links.
- Manual follow-up reminders for checks XCTest cannot fully automate.

## Products

The package exposes three library products:

| Product | Use when |
|---|---|
| `AccessibilityAuditReport` | You already have screenshot data and issue data, or you want to render reports outside XCTest. |
| `AccessibilityAuditXCTestSupport` | You are writing UI tests with `XCTest`, `XCUIApplication`, `XCUIScreen`, and `performAccessibilityAudit`. |
| `AccessibilityAuditLiveSupport` | You want to audit the live app in-process from LLDB while driving it by hand (see [In-Process Audit From LLDB](#in-process-audit-from-lldb)). |

Both `AccessibilityAuditXCTestSupport` and `AccessibilityAuditLiveSupport` depend on `AccessibilityAuditReport`. Consumers that only need HTML rendering do not need either.

## Requirements

- Swift 6.2 package tools.
- iOS 17 or later for XCTest accessibility audits.
- macOS 13 or later for package development and non-XCTest rendering.

## Basic Rendering

Use `AccessibilityAuditReport` when the caller provides screenshots and issues directly.

```swift
import AccessibilityAuditReport
import CoreGraphics
import Foundation

var report = AccessibilityAuditHTMLReport(title: "App Accessibility Audit")

report.record(
    ScreenResult(
        variant: "Default",
        name: "Home",
        screenshotPNGData: screenshotPNGData,
        screenshotSize: CGSize(width: 402, height: 874),
        issues: [
            Issue(
                auditType: "Contrast",
                compactDescription: "Contrast failed",
                detailedDescription: "Contrast failed for SwiftUI.AccessibilityNode",
                elementIdentifier: "home.backupStatus",
                elementLabel: "Backup",
                elementFrame: CGRect(x: 16, y: 158, width: 57, height: 44)
            )
        ]
    )
)

let html = report.renderHTML()
```

## XCTest UI Test Support

Use `AccessibilityAuditXCTestSupport` from UI tests to run an audit, collect issues, capture a screenshot, and record the result.

```swift
import AccessibilityAuditReport
import AccessibilityAuditXCTestSupport
import XCTest

final class AppAccessibilityTests: XCTestCase {
    @MainActor
    func testAccessibilityReport() throws {
        guard #available(iOS 17.0, *) else {
            throw XCTSkip("Automated accessibility audits require iOS 17 or later.")
        }

        let app = XCUIApplication()
        app.launch()

        var report = AccessibilityAuditHTMLReport(title: "App Accessibility Audit")

        try app.recordAccessibilityAuditScreen(
            "Home",
            variant: "Default",
            auditTypes: [.sufficientElementDescription, .hitRegion, .contrast],
            supplementalChecks: .all,
            in: &report
        )

        attachAccessibilityAuditReport(report)

        XCTAssertEqual(
            report.issueCount,
            0,
            "Accessibility audit report found \(report.issueCount) issue(s). See attached HTML report."
        )
    }
}
```

## In-Process Audit From LLDB

`AccessibilityAuditLiveSupport` runs the frame/label checks against the live app
process, so you can audit the current screen while driving the app by hand —
no UI test. Link the product into your app target (Debug only; all of its code
is behind `#if DEBUG`), then call it from LLDB at a paused breakpoint:

```
(lldb) po AXAudit.run()              // audit current screen, write HTML, print path
(lldb) po AXAudit.record("Memories") // accumulate multiple screens…
(lldb) po AXAudit.record("Photos")
(lldb) po AXAudit.dump()             // …then one combined report (+ consistent identification)
```

`run()`/`dump()` write a self-contained HTML report to `NSTemporaryDirectory()`
and print the path; on the simulator, `open <path>` shows it.

**Coverage.** The in-process path runs the supplemental frame/label checks plus
a missing-element-description check. It cannot run Apple's pixel-based audits
(Contrast, Text Clipped, Element Detection) — for a SwiftUI app there is no
in-process API and text colour/font are not readable — so the report's manual
checklist points you to **Accessibility Inspector** for those. Two fidelity
caveats: interactivity is detected from accessibility traits (coarser than the
XCTest element-type set), and SwiftUI often merges a control into one
accessibility leaf, so Label-in-Name detection is best-effort.

## Supplemental Checks

`performAccessibilityAudit` does not cover every rule that commercial testers (for example Level Access) check. The package adds frame- and label-based checks that close those gaps. They are opt-in via the `supplementalChecks` parameter:

| Check | WCAG | What it flags |
|---|---|---|
| `.targetSize` | 2.5.8 / 2.5.5 | Interactive elements below the target-size thresholds, bucketed to their worst level: smaller than 24×24pt → "Target Size (Minimum)" (2.5.8, Level AA, error severity); 24–44pt → "Target Size (Enhanced)" (2.5.5, Level AAA, warning severity). Each element is reported once. |
| `.targetSpacing` | 2.5.8 (WCAG 2.2) | An undersized target (smaller than 24×24pt) whose 24pt spacing circle overlaps a neighbouring target. Well-sized targets that merely touch or overlap are not flagged — 2.5.8's spacing rule applies only to undersized targets. |
| `.screenTitle` | 2.4.2 | Navigation bars with no title text |
| `.duplicateLabels` | 2.4.6 | Interactive elements sharing the same accessible label (ambiguous for Voice Control) |
| `.labelInName` | 2.5.3 | Accessible labels that do not contain the element's visible text (unaddressable by Voice Control) |
| `.genericLabels` | 2.4.4 | Labels that are generic role words ("Button", "More"), asset/file names ("IMG_0123.png", "ic_chevron"), leaked identifiers or code-style strings ("files.backupStatus", "chevron.right"), or bare symbols ("★") |
| `.labelHygiene` | 4.1.2 | Labels that announce badly: redundant role suffixes ("Save button" → "Save button, button"), leading/trailing whitespace, all-caps styling leaking into the label |
| `.adjustableValue` | 4.1.2 | Sliders and pickers with no accessibility value announcing their current state |
| `.consistentIdentification` | 3.2.4 | Elements sharing an identifier but labelled differently across screens (see below) |

Pass `.all` to run every check, or a subset such as `[.targetSize, .screenTitle]`. Issues appear in the report alongside XCTest audit issues.

`.consistentIdentification` is a cross-screen check: during each screen scan it only records the screen's interactive elements into the report's element inventory. After the last screen, evaluate it:

```swift
report.recordConsistentIdentificationCheck()
```

This appends a "Consistent Identification" result screen flagging any identifier whose label differs between screens.

Notes:

- Checks measure `XCUIElementSnapshot` frames — the visual frame, not an extended hit region from `contentShape` or `accessibilityFrame`. Expect occasional false positives that need screen-specific exclusion.
- Only the outermost interactive element of a composite counts as a target; nested controls inside a button are not flagged against their container.
- Offscreen elements (outside the root snapshot frame) are ignored.

Non-XCTest callers can run the same logic directly via `SupplementalAccessibilityChecks` in `AccessibilityAuditReport` by supplying `AuditedElement` values.

### Orientation Lock Check

Orientation (WCAG 1.3.4) cannot be checked from a snapshot, so it is a separate one-off helper rather than a `supplementalChecks` option. It rotates the device from portrait to landscape, compares the root window's proportions before and after, restores the starting orientation, and records an `Orientation` issue when the layout does not respond:

```swift
app.recordOrientationLockCheck(in: &report)
```

Run it once per audit session (it exercises the whole app, not a single screen), and not from a screen that legitimately locks orientation — WCAG 1.3.4 exempts content where a specific orientation is essential. The comparison is skipped as inconclusive when the window is not portrait-proportioned before rotating (for example iPad multitasking). The pure decision logic is available to non-XCTest callers as `SupplementalAccessibilityChecks.orientationLockIssues(portraitWindowSize:landscapeWindowSize:)`.

## Recording Non-Audit Failures

Report generation can also capture automation failures where a screen could not be audited.

Use these from non-XCTest code when you already have screenshot data:

```swift
report.recordReadinessFailure(
    for: "Memories",
    variant: "AX XXXL",
    screenshotPNGData: screenshotPNGData,
    screenshotSize: screenshotSize
)

report.recordNavigationFailure(
    for: "Photos - Locations",
    variant: "Default",
    reason: "An authentication web view appeared while navigating to Photos > Locations.",
    screenshotPNGData: screenshotPNGData,
    screenshotSize: screenshotSize
)
```

From XCTest UI tests, `AccessibilityAuditXCTestSupport` provides overloads that capture `XCUIScreen.main.screenshot()` automatically:

```swift
report.recordReadinessFailure(for: "Memories", variant: "AX XXXL")

report.recordNavigationFailure(
    for: "Photos - Locations",
    variant: "Default",
    reason: "An authentication web view appeared while navigating to Photos > Locations."
)
```

## Recommended Test Flow

1. Launch the app with any required UI test arguments.
2. Navigate to a known screen.
3. Wait for screen-specific content to finish rendering.
4. Call `recordAccessibilityAuditScreen(_:variant:auditTypes:in:)`.
5. Repeat for each screen, appearance mode, Dynamic Type size, or orientation variant.
6. Attach the final report with `attachAccessibilityAuditReport(_:)`.
7. Assert `report.issueCount == 0` so failing runs keep the report as the diagnostic artifact.

## Manual Follow-Up

The report includes reminders for checks that are not fully covered by automated XCTest audits:

- VoiceOver focus order follows the visual and task flow.
- Full Keyboard Access can reach and activate core controls.
- Switch Control can reach and activate core controls.
- Voice Control names are unique enough for primary actions.
- Custom grouped content exposes the right accessibility children.

These checks should be treated as manual review items for critical flows.

## Running Package Tests

From the repository root:

```sh
swift test --package-path AccessibilityAuditReport
```
