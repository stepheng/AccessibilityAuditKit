# LLM Workflow

AccessibilityAuditKit is designed to produce two complementary artifacts:

- `.json` for agent triage, source search, and remediation planning.
- `.html` for screenshot overlays, visual inspection, and manual review.

Use JSON as the first LLM input. It is smaller, deterministic, and contains the
fields an agent needs to decide where to look in source. Use HTML after the
agent has a concrete question about visual placement or a screenshot overlay.

Agents that support reusable skills can use the bundled
`Skills/accessibility-audit-remediation` skill. For Codex, copy that folder into
`~/.codex/skills/` before starting a remediation session.

## Produce Agent-Friendly Artifacts

From XCTest, attach both HTML and JSON:

```swift
try attachAccessibilityAuditArtifacts(report)
```

For CI, write the files to a known directory:

```swift
let urls = try AccessibilityAuditArtifactWriter.write(
    report,
    to: URL(fileURLWithPath: "/tmp/accessibility-audit"),
    baseFilename: "primary-screens"
)
```

## Prompt Template

```text
Read this AccessibilityAuditKit JSON report. Triage active errors before
warnings. Ignore accepted issues unless acceptance.isStale is true.

For each finding:
1. Summarize the user-visible accessibility problem.
2. Use reviewerHints, elementIdentifier, elementLabel, auditType, and frame to
   identify source search terms and likely owning components.
3. Propose the smallest code fix that preserves visible text and behavior.
4. State the verification command or audit rerun needed after the fix.

Do not silence the audit, update baselines, remove identifiers, or accept a
finding as the fix.
```

## JSON Fields Agents Should Use

| Field | Use |
|---|---|
| `schemaVersion` | Detect incompatible report formats. |
| `summary.blockingErrors` | Prioritize release-blocking work. |
| `summary.warnings` | Track advisory findings after errors. |
| `screens[].variant` | Separate default, appearance, Dynamic Type, orientation, or locale variants. |
| `screens[].name` | Anchor findings to app navigation context. |
| `screens[].screenshot.width/height` | Interpret issue frames against the screenshot dimensions. |
| `issues[].severity` | `error`, `warning`, or `accepted`; use for triage order. |
| `issues[].rawSeverity` | Original severity before acceptance is applied. |
| `issues[].auditType` | Choose the remediation strategy. |
| `issues[].elementIdentifier` | Search source and UI tests for stable ownership hints. |
| `issues[].elementLabel` | Search visible text, localization keys, and accessibility labels. |
| `issues[].frame` | Match issue location to screenshot overlays in the HTML report. |
| `issues[].additionalFrames` | Inspect all elements in grouped findings such as duplicate labels. |
| `issues[].reviewerHints` | Follow structured source-search and remediation hints first. |
| `issues[].acceptance` | Skip accepted issues unless `isStale` is true. |

## Triage Order

1. Active `error` findings.
2. Stale accepted findings.
3. Active `warning` findings.
4. Non-stale accepted findings only when auditing acceptance debt.

Within each group, cluster by `auditType`, then by `elementIdentifier` or shared
component hints. Fixing a shared button style, label helper, cell, or wrapper is
usually better than patching every screen separately.

## Source Search Strategy

Use reviewer hints first. Common searches:

```bash
rg "element.identifier"
rg "Visible label"
rg "accessibilityLabel|accessibilityIdentifier|textContentType"
```

For SwiftUI, inspect the view that renders the failing element and any shared
button style, row, cell, or wrapper it uses. For UIKit, inspect the owning view,
cell, view controller, and accessibility configuration helpers.

## Fix Rules

- Fix the source behavior; do not silence the finding.
- Preserve visible text unless the UX copy itself is wrong.
- Preserve stable identifiers; agents need them for future audits.
- Do not update acceptance baselines as a shortcut.
- Re-run the smallest audit or UI test that reproduces the finding, then run the
  broader audit before claiming completion.

## When to Use the HTML

Open the HTML when:

- `frame` data is ambiguous.
- The issue depends on visual geometry or contrast.
- Multiple elements share a grouped finding.
- A manual follow-up item needs human judgment.

The JSON does not embed screenshot pixels. The HTML contains screenshot images
and overlays, so it is the right artifact for visual confirmation.
