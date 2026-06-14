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
    @available(iOS 17.0, *)
    func supplementalIssues(_ kinds: [SupplementalKind]) throws -> [Issue] {
        let snapshot = try app.snapshot()
        return SupplementalAuditScanner.issues(in: snapshot,
                                               checks: CatalogMapping.supplementalType(kinds))
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
