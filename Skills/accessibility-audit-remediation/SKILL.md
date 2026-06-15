---
name: accessibility-audit-remediation
description: Use when triaging or fixing AccessibilityAuditKit JSON reports, XCTest accessibility audit artifacts, supplemental accessibility findings, or LLDB live-audit output in an iOS/macOS codebase.
---

# Accessibility Audit Remediation

## Overview

Use the JSON artifact as the source of truth for triage and the HTML report as
the visual cross-check. Fix source behavior; do not silence audits, update
baselines, or accept findings as a substitute for remediation.

## Inputs

Ask for or locate:

- The `.json` artifact from `attachAccessibilityAuditArtifacts` or
  `AccessibilityAuditArtifactWriter.write`.
- The matching `.html` report when frame, contrast, or grouped visual evidence
  matters.
- The app source tree and the command that produced the audit.

If field meanings are unclear, read `references/json-artifact.md`.

## Workflow

1. Parse JSON first. Check `schemaVersion`, `summary.blockingErrors`,
   `summary.warnings`, and `summary.accepted`.
2. Build the worklist in this order: active errors, stale accepted issues,
   active warnings, then non-stale accepted issues only if requested.
3. Cluster findings by `auditType`, then by `elementIdentifier`, `elementLabel`,
   shared reviewer hints, and screen variant.
4. Follow `reviewerHints` before guessing. Search identifiers first, then labels,
   localization keys, and shared accessibility helpers.
5. Inspect likely shared owners: SwiftUI view, UIKit cell/view, button style,
   row component, text field wrapper, icon asset, or localization helper.
6. Patch the source with the smallest behavior-preserving fix.
7. Re-run the smallest audit or UI test that reproduces the finding. Then run
   the broader audit before claiming completion.

## Search Patterns

Prefer `rg`:

```bash
rg "element.identifier"
rg "Visible label"
rg "accessibilityLabel|accessibilityIdentifier|textContentType"
rg "ButtonStyle|Label|TextField|UIImage|Image\\("
```

For SwiftUI, inspect both the failing view and any modifier/style/wrapper that
sets accessibility metadata. For UIKit, inspect the cell/view/controller and any
shared accessibility configuration helper.

## Fix Rules

- Preserve stable accessibility identifiers.
- Preserve visible text unless the product copy is wrong.
- Make Label-in-Name fixes include the visible text in the accessible name.
- Fix target-size and spacing issues in shared control layout when possible.
- Treat Input Purpose as advisory: verify and set the correct content type.
- Treat contrast findings as design-token or asset issues when shared styling is
  involved.
- Do not update acceptance baselines, suppress assertions, remove checks, or
  weaken tests as the fix.

## Output

Report:

- Triage summary by severity and audit type.
- Source locations inspected and why.
- Code changes made.
- Verification commands and results.
- Residual warnings, manual follow-up, or accepted findings left unchanged.
