//
//  JSONRenderingTests.swift
//  AccessibilityAuditReportTests
//
//  Created by Stephen Gurnett on 15/06/2026.
//

import AccessibilityAuditReport
import CoreGraphics
import Foundation
import XCTest

final class JSONRenderingTests: XCTestCase {
    func testRenderJSONIncludesSummaryScreensAndResolvedIssues() throws {
        var report = AccessibilityAuditHTMLReport(title: "Capsyl Accessibility Audit")
        report.record(
            ScreenResult(
                variant: "AX XXXL",
                name: "Home",
                screenshotPNGData: Data([0, 1, 2]),
                screenshotSize: CGSize(width: 390, height: 844),
                issues: [
                    Issue(
                        auditType: "Target Size (Minimum)",
                        compactDescription: "Interactive target is smaller than 24x24pt",
                        detailedDescription: "The element measures 20x20pt.",
                        elementIdentifier: "home.close",
                        elementLabel: "Close",
                        elementFrame: CGRect(x: 10, y: 20, width: 20, height: 20),
                        reviewerHints: [
                            IssueReviewerHint(
                                title: "Search source by identifier",
                                detail: "Search for accessibility identifier \"home.close\".",
                                automationKey: "source.search.identifier"
                            )
                        ],
                        severity: .error
                    )
                ]
            )
        )
        report.acceptanceRules = [
            AcceptanceRule(
                screen: "Home",
                variant: "AX XXXL",
                auditType: "Target Size (Minimum)",
                elementIdentifier: "home.close",
                context: "Old context",
                reason: "Legacy control pending redesign"
            )
        ]

        let data = try report.renderJSON()
        let root = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let summary = try XCTUnwrap(root["summary"] as? [String: Any])
        let screens = try XCTUnwrap(root["screens"] as? [[String: Any]])
        let screen = try XCTUnwrap(screens.first)
        let screenshot = try XCTUnwrap(screen["screenshot"] as? [String: Any])
        let issues = try XCTUnwrap(screen["issues"] as? [[String: Any]])
        let issue = try XCTUnwrap(issues.first)
        let frame = try XCTUnwrap(issue["frame"] as? [String: Any])
        let acceptance = try XCTUnwrap(issue["acceptance"] as? [String: Any])
        let hints = try XCTUnwrap(issue["reviewerHints"] as? [[String: Any]])

        XCTAssertEqual(root["schemaVersion"] as? String, "1.0")
        XCTAssertEqual(root["title"] as? String, "Capsyl Accessibility Audit")
        XCTAssertEqual(summary["screensAudited"] as? Int, 1)
        XCTAssertEqual(summary["issuesFound"] as? Int, 1)
        XCTAssertEqual(summary["blockingErrors"] as? Int, 0)
        XCTAssertEqual(summary["accepted"] as? Int, 1)
        XCTAssertEqual(screen["variant"] as? String, "AX XXXL")
        XCTAssertEqual(screen["name"] as? String, "Home")
        XCTAssertEqual(screenshot["width"] as? Double, 390)
        XCTAssertEqual(screenshot["height"] as? Double, 844)
        XCTAssertNil(screenshot["pngData"], "JSON should reference audit metadata, not inline screenshot bytes.")
        XCTAssertEqual(issue["auditType"] as? String, "Target Size (Minimum)")
        XCTAssertEqual(issue["severity"] as? String, "accepted")
        XCTAssertEqual(issue["rawSeverity"] as? String, "error")
        XCTAssertEqual(issue["elementIdentifier"] as? String, "home.close")
        XCTAssertEqual(frame["x"] as? Double, 10)
        XCTAssertEqual(frame["width"] as? Double, 20)
        XCTAssertEqual(acceptance["reason"] as? String, "Legacy control pending redesign")
        XCTAssertEqual(acceptance["isStale"] as? Bool, true)
        XCTAssertEqual(hints.first?["automationKey"] as? String, "source.search.identifier")
    }
}
