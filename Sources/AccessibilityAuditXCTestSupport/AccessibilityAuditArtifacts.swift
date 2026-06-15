//
//  AccessibilityAuditArtifacts.swift
//  AccessibilityAuditXCTestSupport
//
//  Created by Stephen Gurnett on 15/06/2026.
//

import AccessibilityAuditReport
import Foundation
import XCTest

public struct AccessibilityAuditArtifactURLs: Sendable, Equatable {
    public let html: URL
    public let json: URL

    public init(html: URL, json: URL) {
        self.html = html
        self.json = json
    }
}

public enum AccessibilityAuditArtifactWriter {
    public static func write(
        _ report: AccessibilityAuditHTMLReport,
        to directory: URL,
        baseFilename: String = "accessibility-audit"
    ) throws -> AccessibilityAuditArtifactURLs {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let sanitized = sanitizedFilename(baseFilename)
        let htmlURL = directory.appendingPathComponent("\(sanitized).html")
        let jsonURL = directory.appendingPathComponent("\(sanitized).json")

        try report.renderHTML().write(to: htmlURL, atomically: true, encoding: .utf8)
        try report.renderJSON().write(to: jsonURL, options: [.atomic])

        return AccessibilityAuditArtifactURLs(html: htmlURL, json: jsonURL)
    }

    private static func sanitizedFilename(_ name: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_."))
        let scalars = name.unicodeScalars.map { scalar -> String in
            allowed.contains(scalar) ? String(scalar) : "-"
        }
        let collapsed = scalars.joined()
            .split(separator: "-", omittingEmptySubsequences: true)
            .joined(separator: "-")
        return collapsed.isEmpty ? "accessibility-audit" : collapsed
    }
}

public extension XCTestCase {
    @discardableResult
    func attachAccessibilityAuditArtifacts(
        _ report: AccessibilityAuditHTMLReport,
        name: String = "Accessibility Audit Report"
    ) throws -> AccessibilityAuditArtifactURLs {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("AccessibilityAuditArtifacts-\(UUID().uuidString)")
        let urls = try AccessibilityAuditArtifactWriter.write(report, to: directory, baseFilename: name)

        let htmlAttachment = XCTAttachment(contentsOfFile: urls.html)
        htmlAttachment.name = "\(name).html"
        htmlAttachment.lifetime = .keepAlways
        add(htmlAttachment)

        let jsonAttachment = XCTAttachment(contentsOfFile: urls.json)
        jsonAttachment.name = "\(name).json"
        jsonAttachment.lifetime = .keepAlways
        add(jsonAttachment)

        return urls
    }
}
