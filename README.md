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

The package exposes two library products:

| Product | Use when |
|---|---|
| `AccessibilityAuditReport` | You already have screenshot data and issue data, or you want to render reports outside XCTest. |
| `AccessibilityAuditXCTestSupport` | You are writing UI tests with `XCTest`, `XCUIApplication`, `XCUIScreen`, and `performAccessibilityAudit`. |

`AccessibilityAuditXCTestSupport` depends on `AccessibilityAuditReport`. Consumers that only need HTML rendering do not need to link XCTest.

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
