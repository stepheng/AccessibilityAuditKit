# AccessibilityFixtures

A known-answer fixtures app for `AccessibilityAuditReport`. Each check has a
passing and a failing example. Deterministic checks are asserted by the UITest
target; manual-review and not-yet-implemented checks are gallery-only with a
documented expected outcome.

The app is a sibling of `CapsylDemo` and references the local package at
`../AccessibilityAuditReport`. The app target is package-free; only the UITest
target links the audit package.

## Run

Gallery (browse by hand):

    Open Capsyl.xcworkspace, select the AccessibilityFixtures scheme, Run.

Each fixture screen is also deep-linkable directly via the `-fixtureScreen <id>`
launch argument (this is how the UI tests boot straight into one screen).

Tests:

    xcodebuild test -scheme AccessibilityFixtures \
      -destination 'platform=iOS Simulator,id=<an iPhone 16 simulator udid>'

> Note: a bare `-destination 'platform=iOS Simulator,name=iPhone 16'` is
> ambiguous against "iPhone 16 Pro/Plus/e" and makes xcodebuild only list
> destinations; pass a concrete simulator `id=` (from `xcrun simctl list devices`).

Regenerate the project after adding/removing source files (files under
`AccessibilityFixtures/Catalog/` are compiled into both the app and UITest
targets):

    cd AccessibilityFixtures && ruby generate_project.rb

## Coverage

| Check | WCAG | Level | Tier | Expected outcome |
|---|---|---|---|---|
| Target Size (Minimum) | 2.5.8 | AA | asserted | 20pt button flagged; 44pt clean |
| Target Size (Enhanced) | 2.5.5 | AAA | asserted | 30pt button flagged; 44pt clean |
| Target Spacing | 2.5.8 | AA | asserted | close undersized pair flagged; spaced pair clean |
| Screen Title | 2.4.2 | AA | asserted | empty-title bar flagged; titled clean |
| Duplicate Labels | 2.4.6 | AA | asserted | two “Open” flagged; distinct clean |
| Label in Name | 2.5.3 | A | asserted | label “Send” flagged; “Submit form” clean |
| Generic Label | 2.4.4 | A | asserted | “Button” flagged; “Delete photo” clean |
| Label Hygiene | 4.1.2 | A | asserted | “Save button” flagged; “Save” clean |
| Adjustable Value | 4.1.2 | A | asserted | empty-value slider flagged; Slider clean |
| Consistent Identification | 3.2.4 | AA | asserted | Profile/Account id flagged; consistent clean |
| Input Purpose | 1.3.5 | AA | asserted | “Email address” flagged; “Album name” clean |
| Hit Region | — | — | asserted (lenient) | tiny target flagged; 44pt clean |
| Sufficient Element Description | — | — | asserted (lenient) | unlabelled image flagged; labelled clean |
| Dynamic Type | 1.4.4 | AA | asserted (lenient) | fixed font flagged; scalable clean |
| Text Clipped | — | — | asserted (lenient) | clipped flagged; full clean |
| Orientation | 1.3.4 | AA | asserted | locked launch flagged; normal clean |
| Contrast | 1.4.3 | AA | **gallery-only** | see downgrade note below |
| Trait | — | — | **gallery-only** | see downgrade note below |
| Element Detection | — | — | **gallery-only** | see downgrade note below |
| VoiceOver Focus Order | 1.3.2 / 2.4.3 | A | manual | human verifies focus order |
| Full Keyboard Access | 2.1.1 | A | manual | human verifies keyboard reachability |
| Switch Control | 2.1.1 | A | manual | human verifies switch reachability |
| Voice Control Naming | 2.5.3 | A | manual | human verifies speakable names |
| Grouped Content | 1.3.1 | A | manual | human verifies grouping |
| Non-text Contrast | 1.4.11 | AA | future | gallery only until implemented |
| Status Messages | 4.1.3 | AA | future | gallery only until implemented |
| Resize Text / Reflow | 1.4.4 / 1.4.10 | AA | future | gallery only until implemented |

## Apple-audit downgrades (2026-06-14, iPhone 16 / iOS 18.5)

Three of the seven Apple `performAccessibilityAudit` checks were downgraded from
asserted to gallery-only because their audits did not fire deterministically on
the simulator. The remaining four (Hit Region, Sufficient Element Description,
Dynamic Type, Text Clipped) assert reliably.

- **Contrast (1.4.3)** — `.contrast` raised no issue on a clear ~1.5:1
  grey-on-white text violation, across a value tweak (0.72 → 0.85 grey) and a
  structural change (full-screen white backdrop). The other Apple audits fire on
  the same harness, so this is specific to the contrast audit in this
  environment. The fixture still renders a good/bad example for manual checking.
- **Trait** — Apple's `.trait` audit flags trait *conflicts*, not a plain
  "missing header trait", so a non-header `Text` cannot be made to fire
  deterministically.
- **Element Detection** — `.elementDetection` (undetectable elements, e.g. text
  baked into images) does not fire for a translucent SwiftUI overlay.

Re-promote any of these to `tier: .lenient` in `FixtureCatalog.swift` if a future
OS/simulator detects them.

## Source of truth

`AccessibilityFixtures/Catalog/FixtureCatalog.swift` is the single source of
truth: it drives the gallery, the assertions, and this table. Adding a new
deterministic single-screen supplemental check is just a catalog entry plus a
fixture view — the data-driven `DeterministicChecksTests` picks it up.
