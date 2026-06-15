//
//  LiveAccessibilityScanner.swift
//  AccessibilityAuditLiveSupport
//
//  Created by Stephen Gurnett on 14/06/2026.
//

#if canImport(UIKit)
import AccessibilityAuditReport
import CoreGraphics
import Foundation
import UIKit

/// Result of scanning the current foreground screen in-process.
struct LiveScreenScanResult {
    let issues: [Issue]
    let inventory: [AuditedElement]
    let screenshotPNGData: Data
    let screenshotSize: CGSize
}

/// Orchestrates the live walk + pure checks + screenshot for the foreground
/// window. Returns `nil` when no foreground window can be found.
enum LiveAccessibilityScanner {
    @MainActor
    static func scan() -> LiveScreenScanResult? {
        guard let window = foregroundWindow() else { return nil }

        let root = UIAccessibilityTreeWalker.node(for: window)
        let titles = UIAccessibilityTreeWalker.navigationBarTitles(in: window)

        return LiveScreenScanResult(
            issues: LiveScreenScan.issues(in: root, navigationBarTitles: titles),
            inventory: LiveScreenScan.interactiveElements(in: root, within: root.frame),
            screenshotPNGData: screenshotPNGData(of: window),
            screenshotSize: window.bounds.size
        )
    }

    /// The key window of the foreground-active scene, falling back to the
    /// first window of any connected window scene.
    @MainActor
    static func foregroundWindow() -> UIWindow? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let active = scenes.first { $0.activationState == .foregroundActive } ?? scenes.first
        guard let scene = active else { return nil }
        return scene.windows.first(where: \.isKeyWindow) ?? scene.windows.first
    }

    /// Renders the window to PNG. `afterScreenUpdates: false` because the app
    /// is paused under LLDB and cannot pump the run loop.
    @MainActor
    private static func screenshotPNGData(of window: UIWindow) -> Data {
        let renderer = UIGraphicsImageRenderer(bounds: window.bounds)
        let image = renderer.image { _ in
            window.drawHierarchy(in: window.bounds, afterScreenUpdates: false)
        }
        return image.pngData() ?? Data()
    }
}
#endif
