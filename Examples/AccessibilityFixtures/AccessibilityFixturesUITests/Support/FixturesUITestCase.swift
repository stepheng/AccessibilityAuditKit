//  FixturesUITestCase.swift
import AccessibilityAuditReport
import AccessibilityAuditXCTestSupport
import XCTest

@MainActor
class FixturesUITestCase: XCTestCase {
    let app = XCUIApplication()

    override func setUp() { continueAfterFailure = false }

    /// Launches the app straight into one fixture screen.
    func launch(fixture screenId: String, extraArgs: [String] = []) {
        app.launchArguments = ["-fixtureScreen", screenId] + extraArgs
        app.launch()
    }

    /// Runs the given supplemental checks against the current screen by calling
    /// the package's pure scanner directly on the app snapshot — no Apple audit,
    /// fully deterministic.
    ///
    /// For the `.screenTitle` check the accessibility snapshot produced by
    /// `XCUIApplication.snapshot()` does not include a `.navigationBar` node for
    /// SwiftUI `NavigationStack` bars (they flatten away in the VoiceOver tree).
    /// To keep the check deterministic the helper falls back to querying
    /// `app.navigationBars` directly and running
    /// `SupplementalAccessibilityChecks.screenTitleIssues` on the result, then
    /// merges those issues with the snapshot-based issues from the other checks.
    @available(iOS 17.0, *)
    func supplementalIssues(_ kinds: [SupplementalKind]) throws -> [Issue] {
        let snapshot = try app.snapshot()
        let checks = CatalogMapping.supplementalType(kinds)
        var issues = SupplementalAuditScanner.issues(in: snapshot, checks: checks)

        if checks.contains(.screenTitle) {
            // Collect navigation bar titles via the live query so SwiftUI
            // NavigationStack bars (which are absent from the snapshot) are included.
            var liveBarTitles: [String] = []
            let bars = app.navigationBars
            for index in 0..<bars.count {
                let bar = bars.element(boundBy: index)
                let id = bar.identifier
                // Skip SwiftUI internal type-name identifiers (e.g. "_TtGC7SwiftUI…").
                if id.isEmpty || id.hasPrefix("_Tt") {
                    // Fall back to the first static-text child label.
                    let statics = bar.staticTexts
                    var found = false
                    for si in 0..<statics.count {
                        let t = statics.element(boundBy: si).label
                        if !t.isEmpty {
                            liveBarTitles.append(t)
                            found = true
                            break
                        }
                    }
                    if !found { liveBarTitles.append("") }
                } else {
                    liveBarTitles.append(id)
                }
            }
            // Only append live-query issues that aren't already covered by the
            // snapshot scan to avoid double-counting.
            let snapshotScreenTitleCount = issues.filter { $0.auditType == "Screen Title" }.count
            if snapshotScreenTitleCount == 0 {
                issues += SupplementalAccessibilityChecks.screenTitleIssues(
                    navigationBarTitles: liveBarTitles)
            }
        }

        return issues
    }

    /// Element inventory for cross-screen checks.
    @available(iOS 17.0, *)
    func inventory(screenName: String) throws -> AuditedScreenElements {
        let snapshot = try app.snapshot()
        return AuditedScreenElements(
            screenName: screenName,
            elements: SupplementalAuditScanner.interactiveElementInventory(in: snapshot))
    }
}
