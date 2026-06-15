# AccessibilityAuditKit JSON Artifact

Use this reference after loading `accessibility-audit-remediation` when a task
needs field-level interpretation of an AccessibilityAuditKit JSON report.

## Shape

```json
{
  "schemaVersion": "1.0",
  "title": "App Accessibility Audit",
  "summary": {
    "screensAudited": 3,
    "issuesFound": 2,
    "blockingErrors": 1,
    "warnings": 1,
    "accepted": 0
  },
  "screens": [
    {
      "variant": "Default",
      "name": "Home",
      "screenshot": { "width": 402, "height": 874 },
      "issues": []
    }
  ]
}
```

## Issue Fields

| Field | Meaning |
|---|---|
| `auditType` | Rule/check name, e.g. `Target Size (Minimum)` or `Label in Name`. |
| `compactDescription` | Short user-facing finding summary. |
| `detailedDescription` | Longer explanation from XCTest or the supplemental check. |
| `severity` | Effective state: `error`, `warning`, or `accepted`. |
| `rawSeverity` | Original state before acceptance is applied. |
| `elementIdentifier` | Best source-search key when present. |
| `elementLabel` | Visible/accessibility label search key. |
| `frame` | Primary element frame in screenshot coordinates. |
| `additionalFrames` | Other involved frames for grouped findings. |
| `reviewerHints` | Structured hints. Follow these before guessing. |
| `acceptance` | Accepted reason and staleness marker. |

## Reviewer Hint Keys

- `source.search.identifier`: search source for the element identifier.
- `source.search.label`: search visible text, localization keys, and labels.
- `audit.remediation.target-size`: inspect control size, hit area, padding, or button style.
- `audit.remediation.label`: inspect text, localization, and accessibility label construction.
- `audit.remediation.consistent-identification`: inspect shared tab, toolbar, row, or label construction.
- `audit.remediation.adjustable-value`: inspect custom slider, picker, value, role, and traits.
- `audit.remediation.input-purpose`: verify the text field wrapper sets `textContentType`.
- `audit.remediation.non-text-contrast`: inspect image assets, tint, semantic colors, and icon button styles.
- `runtime.class` / `runtime.ownerClass`: runtime breadcrumbs from live audits; useful but not proof of root cause.

## Triage

1. Active errors: `severity == "error"`.
2. Stale accepted issues: `severity == "accepted"` and `acceptance.isStale == true`.
3. Active warnings: `severity == "warning"`.
4. Non-stale accepted issues only when asked to review acceptance debt.

Cluster by `auditType`, then by identifier, label, shared reviewer hints, and
screen variant.
