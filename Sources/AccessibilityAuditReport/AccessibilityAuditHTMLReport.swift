//
//  AccessibilityAuditHTMLReport.swift
//  AccessibilityAuditReport
//
//  Created by Stephen Gurnett on 12/06/2026.
//

import CoreGraphics
import Foundation

public struct AccessibilityAuditHTMLReport {
    public let title: String
    public private(set) var screens: [ScreenResult] = []
    public private(set) var elementInventories: [AuditedScreenElements] = []

    /// Baseline rules used to mark findings as accepted. Resolved at
    /// consumption time, so every recorded screen is covered uniformly.
    public var acceptanceRules: [AcceptanceRule] = []

    /// Extra manual follow-up notes appended to the report's manual checklist.
    /// The in-process audit path uses this to point at Accessibility Inspector
    /// for checks it cannot run (Contrast, Text Clipped, Element Detection).
    public var additionalManualChecks: [String] = []

    public var issueCount: Int {
        screens.reduce(0) { partialResult, screen in
            partialResult + screen.issues.count
        }
    }

    /// Screens with acceptance resolved against `acceptanceRules`.
    private var resolvedScreens: [ScreenResult] {
        screens.map { screen in
            ScreenResult(
                variant: screen.variant,
                name: screen.name,
                screenshotPNGData: screen.screenshotPNGData,
                screenshotSize: screen.screenshotSize,
                issues: AcceptanceResolver.resolve(
                    issues: screen.issues,
                    screen: screen.name,
                    variant: screen.variant,
                    rules: acceptanceRules
                )
            )
        }
    }

    private var resolvedIssues: [Issue] {
        resolvedScreens.flatMap(\.issues)
    }

    /// Active (non-accepted) error findings. This is the build gate.
    public var blockingIssueCount: Int {
        resolvedIssues.filter { $0.severity == .error && $0.acceptance == nil }.count
    }

    /// Alias of `blockingIssueCount`, named for report summaries.
    public var errorCount: Int { blockingIssueCount }

    /// Active (non-accepted) warning findings.
    public var warningCount: Int {
        resolvedIssues.filter { $0.severity == .warning && $0.acceptance == nil }.count
    }

    /// Findings marked accepted by the baseline (including stale ones).
    public var acceptedCount: Int {
        resolvedIssues.filter { $0.acceptance != nil }.count
    }

    public init(title: String) {
        self.title = title
    }

    public mutating func record(_ screen: ScreenResult) {
        screens.append(screen)
    }

    /// Stores a screen's interactive elements for cross-screen checks; pair
    /// with `recordConsistentIdentificationCheck` once all screens are audited.
    public mutating func recordElementInventory(screenName: String, elements: [AuditedElement]) {
        elementInventories.append(
            AuditedScreenElements(screenName: screenName, elements: elements)
        )
    }

    /// Compares the recorded element inventories across screens and records a
    /// Consistent Identification result screen (WCAG 3.2.4).
    public mutating func recordConsistentIdentificationCheck(
        name: String = "Consistent Identification",
        variant: String = "Default",
        screenshotPNGData: Data,
        screenshotSize: CGSize
    ) {
        record(
            ScreenResult(
                variant: variant,
                name: name,
                screenshotPNGData: screenshotPNGData,
                screenshotSize: screenshotSize,
                issues: SupplementalAccessibilityChecks.consistentIdentificationIssues(
                    screens: elementInventories
                )
            )
        )
    }

    public func renderHTML() -> String {
        """
        <!doctype html>
        <html lang="en">
        <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <title>\(Self.htmlEscaped(title))</title>
        <style>
        \(Self.styles)
        \(Self.issueHighlightStyles(screens))
        </style>
        </head>
        <body>
        <main>
        <header>
        <h1>\(Self.htmlEscaped(title))</h1>
        <dl class="summary">
        <dt>Screens audited</dt><dd>\(screens.count)</dd>
        <dt>Issues found</dt><dd>\(issueCount)</dd>
        </dl>
        <h2>Issue counts by variant</h2>
        <dl class="summary variant-summary">
        \(Self.renderVariantSummary(screens))
        </dl>
        \(Self.renderManualChecklist(additionalManualChecks))
        </header>
        \(screens.enumerated().map { Self.renderScreen($0.element, screenIndex: $0.offset) }.joined(separator: "\n"))
        </main>
        </body>
        </html>
        """
    }

    private static func renderVariantSummary(_ screens: [ScreenResult]) -> String {
        let summaries = Dictionary(grouping: screens, by: \.variant)
            .map { variant, screens in
                let issueCount = screens.reduce(0) { partialResult, screen in
                    partialResult + screen.issues.count
                }
                return (variant: variant, issueCount: issueCount, screenCount: screens.count)
            }
            .sorted { $0.variant < $1.variant }

        guard summaries.isEmpty == false else {
            return "<dt>None</dt><dd>0 issue(s), 0 screen(s)</dd>"
        }

        return summaries.map { summary in
            """
            <dt>\(htmlEscaped(summary.variant))</dt><dd>\(summary.issueCount) issue(s), \(summary.screenCount) screen(s)</dd>
            """
        }
        .joined(separator: "\n")
    }

    private static func renderManualChecklist(_ additionalChecks: [String]) -> String {
        let baseItems = [
            "VoiceOver focus order follows the visual and task flow.",
            "Full Keyboard Access can reach and activate core controls.",
            "Switch Control can reach and activate core controls.",
            "Voice Control names are unique enough for primary actions.",
            "Custom grouped content exposes the right accessibility children."
        ]
        let items = (baseItems + additionalChecks)
            .map { "<li>\(htmlEscaped($0))</li>" }
            .joined(separator: "\n")
        return """
        <section class="manual-checks" aria-labelledby="manual-checks-heading">
        <h2 id="manual-checks-heading">Manual follow-up checks</h2>
        <ul>
        \(items)
        </ul>
        </section>
        """
    }

    private static func issueHighlightStyles(_ screens: [ScreenResult]) -> String {
        screens.enumerated().flatMap { screenIndex, screen in
            screen.issues.indices.map { issueIndex in
                let issueID = "screen-\(screenIndex)-issue-\(issueIndex)"
                return """
                .screen-layout:has(.issue-card[data-issue-id="\(issueID)"]:hover) .issue-frame[data-issue-id="\(issueID)"],
                .screen-layout:has(.issue-card[data-issue-id="\(issueID)"]:focus-visible) .issue-frame[data-issue-id="\(issueID)"] {
                  opacity: 1;
                  background: rgb(255 45 85 / 30%);
                  box-shadow: 0 0 0 3px rgb(255 255 255 / 95%), 0 0 0 7px rgb(255 45 85 / 55%);
                }
                """
            }
        }
        .joined(separator: "\n")
    }

    private static func renderScreen(_ screen: ScreenResult, screenIndex: Int) -> String {
        let screenshotBase64 = screen.screenshotPNGData.base64EncodedString()
        let issueContent = screen.issues.isEmpty ? """
        <p class="pass">No issues found for this screen.</p>
        """ : """
        <ol class="issues">
        \(screen.issues.enumerated().map {
            let issueID = "screen-\(screenIndex)-issue-\($0.offset)"
            return renderIssue($0.element, issueID: issueID, screenshotSize: screen.screenshotSize)
        }.joined(separator: "\n"))
        </ol>
        """

        return """
        <section class="screen">
        <h2><span class="variant">\(htmlEscaped(screen.variant))</span> \(htmlEscaped(screen.name))</h2>
        <div class="screen-layout">
        <div class="issue-list">
        \(issueContent)
        </div>
        <aside class="screenshot-panel" aria-label="Screenshot for \(htmlEscaped(screen.variant)) \(htmlEscaped(screen.name))">
        <a class="screenshot-link" href="data:image/png;base64,\(screenshotBase64)" target="_blank" rel="noopener">
        <div class="screenshot">
        <img alt="Screenshot for \(htmlEscaped(screen.name))" src="data:image/png;base64,\(screenshotBase64)">
        \(screen.issues.enumerated().map {
            let issueID = "screen-\(screenIndex)-issue-\($0.offset)"
            return renderOverlay($0.element, issueID: issueID, screenshotSize: screen.screenshotSize)
        }.joined(separator: "\n"))
        </div>
        </a>
        <p class="screenshot-caption">Tap the screenshot to open the full-size image.</p>
        </aside>
        </div>
        </section>
        """
    }

    private static func renderOverlay(_ issue: Issue, issueID: String, screenshotSize: CGSize) -> String {
        guard let style = overlayStyle(for: issue.elementFrame, screenshotSize: screenshotSize) else {
            return ""
        }
        return """
        <span aria-hidden="true" class="issue-frame" data-issue-id="\(issueID)" style="\(style)"></span>
        """
    }

    private static func renderIssue(_ issue: Issue, issueID: String, screenshotSize: CGSize) -> String {
        let frameDescription = frameDescription(for: issue.elementFrame, screenshotSize: screenshotSize)

        return """
        <li class="issue-card" tabindex="0" data-issue-id="\(issueID)">
        <h3>\(htmlEscaped(issue.auditType)): \(htmlEscaped(issue.compactDescription))</h3>
        <dl>
        <dt>Details</dt><dd>\(htmlEscaped(issue.detailedDescription))</dd>
        <dt>Element identifier</dt><dd>\(htmlEscaped(issue.elementIdentifier))</dd>
        <dt>Element label</dt><dd>\(htmlEscaped(issue.elementLabel))</dd>
        <dt>Frame</dt><dd>\(htmlEscaped(frameDescription))</dd>
        </dl>
        </li>
        """
    }

    private static func frameDescription(for frame: CGRect?, screenshotSize: CGSize) -> String {
        guard let frame else {
            return "No element frame available"
        }

        return [
            "x: \(formatted(frame.origin.x))",
            "y: \(formatted(frame.origin.y))",
            "width: \(formatted(frame.width))",
            "height: \(formatted(frame.height))",
            "screenshot: \(formatted(screenshotSize.width)) x \(formatted(screenshotSize.height))"
        ].joined(separator: ", ")
    }

    private static func overlayStyle(for frame: CGRect?, screenshotSize: CGSize) -> String? {
        guard let frame,
              screenshotSize.width > 0,
              screenshotSize.height > 0,
              frame.width > 0,
              frame.height > 0 else {
            return nil
        }

        let left = percentage(frame.minX, relativeTo: screenshotSize.width)
        let top = percentage(frame.minY, relativeTo: screenshotSize.height)
        let width = percentage(frame.width, relativeTo: screenshotSize.width)
        let height = percentage(frame.height, relativeTo: screenshotSize.height)

        return "left:\(left)%;top:\(top)%;width:\(width)%;height:\(height)%"
    }

    private static func percentage(_ value: CGFloat, relativeTo total: CGFloat) -> String {
        formatted((value / total) * 100)
    }

    private static func formatted(_ value: CGFloat) -> String {
        String(format: "%.2f", Double(value))
    }

    private static func htmlEscaped(_ value: String) -> String {
        value.reduce(into: "") { result, character in
            switch character {
            case "&":
                result += "&amp;"
            case "<":
                result += "&lt;"
            case ">":
                result += "&gt;"
            case "\"":
                result += "&quot;"
            case "'":
                result += "&#39;"
            default:
                result.append(character)
            }
        }
    }

    private static let styles = """
    :root {
      color-scheme: light dark;
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
      background: Canvas;
      color: CanvasText;
    }
    body {
      margin: 0;
    }
    main {
      max-width: 1280px;
      margin: 0 auto;
      padding: 24px;
    }
    h1, h2, h3 {
      margin: 0 0 12px;
    }
    .summary, .issues dl {
      display: grid;
      grid-template-columns: max-content 1fr;
      gap: 8px 12px;
    }
    .summary {
      margin: 0 0 24px;
    }
    .manual-checks {
      margin: 0 0 24px;
      padding: 16px;
      border: 1px solid color-mix(in srgb, CanvasText 18%, transparent);
      border-radius: 8px;
      background: color-mix(in srgb, Canvas 92%, CanvasText 8%);
    }
    .manual-checks ul {
      margin: 0;
      padding-left: 22px;
    }
    .manual-checks li {
      margin: 6px 0;
    }
    dt {
      font-weight: 700;
    }
    dd {
      margin: 0;
    }
    .screen {
      border-top: 1px solid color-mix(in srgb, CanvasText 20%, transparent);
      padding: 24px 0;
    }
    .screen-layout {
      display: grid;
      grid-template-columns: minmax(320px, 1fr) minmax(260px, 420px);
      gap: 24px;
      align-items: start;
    }
    .variant {
      display: inline-block;
      margin-right: 8px;
      padding: 2px 8px;
      border-radius: 999px;
      font-size: 0.75em;
      font-weight: 700;
      background: color-mix(in srgb, CanvasText 12%, transparent);
    }
    .issue-list {
      min-width: 0;
    }
    .screenshot-panel {
      position: sticky;
      top: 16px;
      align-self: start;
    }
    .screenshot-link {
      display: block;
      color: inherit;
      text-decoration: none;
    }
    .screenshot {
      display: inline-block;
      position: relative;
      max-width: 100%;
      max-height: 70vh;
      overflow: hidden;
      line-height: 0;
      border: 1px solid color-mix(in srgb, CanvasText 16%, transparent);
      border-radius: 8px;
      background: #000;
    }
    .screenshot img {
      display: block;
      max-width: 100%;
      max-height: 70vh;
      height: auto;
      object-fit: contain;
    }
    .screenshot-caption {
      margin: 8px 0 0;
      font-size: 0.9em;
      color: color-mix(in srgb, CanvasText 72%, transparent);
    }
    .issue-frame {
      position: absolute;
      box-sizing: border-box;
      border: 3px solid #ff2d55;
      background: rgb(255 45 85 / 18%);
      box-shadow: 0 0 0 2px rgb(255 255 255 / 85%);
      opacity: 0.58;
      transition: opacity 120ms ease, box-shadow 120ms ease, background 120ms ease;
    }
    .issues {
      margin: 0;
      padding-left: 24px;
    }
    .issues li {
      margin-bottom: 18px;
    }
    .issue-card {
      padding: 12px;
      border-radius: 8px;
      outline: none;
    }
    .issue-card:hover,
    .issue-card:focus-visible {
      background: color-mix(in srgb, #ff2d55 14%, transparent);
    }
    .pass {
      color: #16833a;
      font-weight: 700;
    }
    @media (max-width: 820px) {
      main {
        padding: 16px;
      }
      .screen-layout {
        grid-template-columns: 1fr;
      }
      .screenshot-panel {
        position: static;
      }
    }
    """
}
