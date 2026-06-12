# AccessibilityAuditXCTestSupport

`AccessibilityAuditXCTestSupport` is the XCTest integration layer for `AccessibilityAuditReport`. Use it from UI test targets that run `performAccessibilityAudit`, capture screenshots with `XCUIScreen`, and attach the generated HTML report to the XCTest result bundle.

Import both products in UI tests:

```swift
import AccessibilityAuditReport
import AccessibilityAuditXCTestSupport
import XCTest
```

## What It Provides

- Human-readable names for `XCUIAccessibilityAuditType` values.
- `XCTestCase.attachAccessibilityAuditReport(_:)` for attaching rendered HTML.
- XCTest screenshot overloads for recording readiness and navigation failures.
- `XCUIApplication.recordAccessibilityAuditScreen(_:variant:auditTypes:in:screenshot:)` for running an audit and appending the screen result to a report.

## Recording an Audited Screen

```swift
@MainActor
func testHomeAccessibilityReport() throws {
    guard #available(iOS 17.0, *) else {
        throw XCTSkip("Automated accessibility audits require iOS 17 or later.")
    }

    let app = XCUIApplication()
    app.launch()

    var report = AccessibilityAuditHTMLReport(title: "Accessibility Audit")

    try app.recordAccessibilityAuditScreen(
        "Home",
        variant: "Default",
        auditTypes: [
            .sufficientElementDescription,
            .hitRegion,
            .contrast
        ],
        in: &report
    )

    attachAccessibilityAuditReport(report)

    XCTAssertEqual(
        report.issueCount,
        0,
        "Accessibility audit report found \(report.issueCount) issue(s). See attached HTML report."
    )
}
```

`recordAccessibilityAuditScreen` collects every issue reported by `performAccessibilityAudit`, captures a screenshot after the audit, and appends a `ScreenResult` to the report.

## Recording Automation Failures

Use these helpers when the test cannot safely run the audit because the expected screen did not appear or did not finish rendering.

```swift
report.recordReadinessFailure(
    for: "Memories",
    variant: "AX XXXL"
)

report.recordNavigationFailure(
    for: "Photos - Locations",
    variant: "Default",
    reason: "An authentication web view appeared while navigating to Photos > Locations."
)
```

Both helpers capture `XCUIScreen.main.screenshot()` automatically. If you already captured a screenshot, pass it explicitly:

```swift
let screenshot = XCUIScreen.main.screenshot()

report.recordNavigationFailure(
    for: "Photos - Locations",
    variant: "Default",
    reason: "The Locations page selector was not available.",
    screenshot: screenshot
)
```

## Attaching the Report

```swift
attachAccessibilityAuditReport(report)
```

The attachment is written as `public.html` and uses `.keepAlways`, so the report remains available in failed test results.

Pass a custom attachment name when needed:

```swift
attachAccessibilityAuditReport(
    report,
    name: "Checkout Accessibility Audit Report"
)
```

## Recommended Pattern

1. Create one `AccessibilityAuditHTMLReport` per test run.
2. Launch and navigate with app-specific UI test helpers.
3. Wait for screen-specific content before auditing.
4. Call `recordAccessibilityAuditScreen` for each screen and variant.
5. Record readiness or navigation failures instead of silently skipping screens.
6. Attach the report in both success and failure paths.
7. Assert `report.issueCount == 0` after attaching the report.

## Availability Notes

`performAccessibilityAudit` requires iOS 17 or later. Keep UI tests guarded with `#available(iOS 17.0, *)` and skip on older runtimes.

Some audit type constants are only available when compiling for iOS. The formatter names those iOS-only cases in iOS UI test builds and falls back to raw audit type values when no known name is available.
