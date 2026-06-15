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
no UI test.

Setup (one-time):

1. Link the product into your app target (its code is all behind `#if DEBUG`,
   so nothing ships in Release).
2. Call `AXAudit.link()` once at launch under `#if DEBUG`. This is required:
   nothing else references the module, so without a reachable reference the
   linker dead-strips it and `AXAudit` is absent at runtime (`po [AXAudit
   runDeferred]` then fails to resolve the class). For example, in your `App.init()`:

   ```swift
   #if DEBUG
   import AccessibilityAuditLiveSupport
   #endif

   init() {
       #if DEBUG
       AXAudit.link()
       #endif
       // …
   }
   ```

Then call it from LLDB at a paused breakpoint — via `runDeferred` + `continue`:

```
(lldb) po [AXAudit runDeferred]      // audit current screen on the runloop…
(lldb) continue                      // …prints findings + writes HTML
```

Do **not** `po AXAudit.run()` directly. A direct `po` evaluates `run()` in
LLDB's expression sandbox, whose exception guard breaks on a benign
`NSException` UIKit throws (and catches itself) while rendering and traversing
the screen, aborting with "internal ObjC exception breakpoint(-8)" and rolling
the call back. `runDeferred` schedules the audit on the real runloop, where
UIKit swallows that exception and the audit completes. Launching the app with
the `-AXAuditAtLaunch` argument runs an audit automatically at startup.

For a multi-screen report, defer each call the same way, navigating between:

```
(lldb) e -- (void)dispatch_async(dispatch_get_main_queue(), ^{ (void)[AXAudit recordScreen:@"Memories"]; })
(lldb) continue                      // navigate to the next screen, then repeat…
(lldb) e -- (void)dispatch_async(dispatch_get_main_queue(), ^{ (void)[AXAudit recordScreen:@"Photos"]; })
(lldb) continue
(lldb) e -- (void)dispatch_async(dispatch_get_main_queue(), ^{ (void)[AXAudit dump]; })
(lldb) continue                      // …then one combined report (+ consistent identification)
```

`run()`/`dump()` print a plain-text summary of the findings straight to the
LLDB/Xcode console — counts, then each screen's issues (errors, then warnings,
then accepted) with element identifier, label, frame, and details — so you (or
an LLM reading the session) can act on them without opening the report. They
also write a self-contained HTML report (with screenshots and issue overlays)
to `NSTemporaryDirectory()` and print its path; on the simulator, `open <path>`
shows it.

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
| `.inputPurpose` | 1.3.5 | Text fields (not search fields) whose label, identifier, or visible text suggests they collect personal data (email, password, phone, postal address, name, …), prompting verification that the field declares a matching `textContentType`. Advisory **warning**: XCUITest cannot read `textContentType`, so it flags candidates, not confirmed failures. |
| `.nonTextContrast` | 1.4.11 | Icons and icon-only controls (image elements, and `.button`/`.menuItem`/`.link` with no visible text) whose dominant graphical content has less than 3:1 contrast against its background, measured from the screenshot pixels. Advisory **warning**: the foreground/background split is inferred from pixels, and only clearly two-toned regions are judged — photos, gradients, flat fills, and thin/tiny glyphs are skipped, so it can miss real failures and is not a substitute for manual review. Needs the screenshot, so it runs from `recordAccessibilityAuditScreen`, not the bare `issues(in:checks:)` path. |

Pass `.all` to run every check, or a subset such as `[.targetSize, .screenTitle]`. Issues appear in the report alongside XCTest audit issues.

Status Messages (WCAG 4.1.3) are event-based rather than snapshot-based. Use
`StatusMessageObservation` with `SupplementalAccessibilityChecks.statusMessageIssues`
after a scripted interaction or app test hook records the announcement that was
posted for the status change. Missing or mismatched observations are advisory
warnings because XCTest cannot directly inspect `UIAccessibility.post` or
SwiftUI live-region events from a static accessibility tree.

Resize Text / Reflow (WCAG 1.4.4 and 1.4.10) is variant-based rather than a
single-snapshot semantic property. Use `ResizeReflowObservation` with
`SupplementalAccessibilityChecks.resizeReflowIssues` after launching an explicit
large-text and/or orientation variant. Horizontal overflow and supplied clipping
observations are advisory warnings because snapshots cannot expose every visual
text-clipping state.

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

## Severity tiers

Every finding carries a severity:

- **Error** (blocking) — deterministic checks (Target Size, Target Spacing, Screen
  Title, Duplicate Labels, Label in Name, Adjustable Value, Consistent
  Identification, Orientation) and all `performAccessibilityAudit` issues.
- **Warning** (non-blocking) — the heuristic checks (Generic Label, Label
  Hygiene, Input Purpose, Non-text Contrast), which flag *likely* or advisory
  problems rather than certain ones.

Warnings appear in the report but never fail the build.

## Acceptance baseline

A checked-in JSON file marks specific findings as accepted — either a false
positive or a violation human review judged acceptable under the current
conditions. Each rule:

| Field | Required | Meaning |
|---|---|---|
| `screen` | yes | Screen name the finding appears on |
| `auditType` | yes | The check that produced it (e.g. `Label in Name`) |
| `reason` | yes | Why it is accepted — a rule without this fails to load |
| `variant` | no | Match a single variant; omit or `null` to match any |
| `elementIdentifier` | no | Identity match when present |
| `elementLabel` | no | Fallback match when there is no usable identifier |
| `context` | no | The finding's original description; if it later drifts, the acceptance is flagged stale |

Example baseline:

```json
[
  {
    "screen": "Home",
    "auditType": "Label in Name",
    "elementIdentifier": "saveButton",
    "elementLabel": "Save",
    "context": "Accessible label \"Save\" does not contain visible text \"OK\"",
    "reason": "Reviewed 2026-06-13 SG — visible 'OK' is decorative"
  }
]
```

Load it and gate the test on unaccepted errors:

```swift
report.acceptanceRules = try AcceptanceBaseline.load(from: baselineURL)
// … record screens …
XCTAssertEqual(report.blockingIssueCount, 0, "Unaccepted accessibility errors present")
```

A stale acceptance — one whose `context` no longer matches the current finding —
stays non-blocking but is flagged with a re-review badge in the report, so drift
is visible without breaking CI.

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

## Known Coverage Gaps (Future Iterations)

No explicit machine-detectable WCAG criteria are currently left in this bucket.
Keep this section for future audit gaps that are practical but not yet
implemented as supplemental checks.

Non-text contrast (1.4.11) is now partially covered for icon-style graphical objects by the `.nonTextContrast` supplemental check; control borders and focus/state indicators remain manual review items.
Status messages (4.1.3) are covered when callers provide scripted event
observations; they remain outside static snapshot scanning.
Resize text/reflow (1.4.4/1.4.10) is covered when callers provide scripted
large-text or orientation observations; arbitrary clipping still needs manual
review when it cannot be represented by an observation.

## Running Package Tests

From the repository root:

```bash
xcodebuild test \
  -scheme AccessibilityAuditReport-Package \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```
