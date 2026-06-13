//
//  UIAccessibilityTreeWalker.swift
//  AccessibilityAuditReport
//
//  Created by Stephen Gurnett on 14/06/2026.
//

#if canImport(UIKit)
import CoreGraphics
import UIKit

/// Reads the live accessibility tree of a window into `AccessibilityNode`s and
/// gathers navigation-bar titles, converting frames into window coordinates.
enum UIAccessibilityTreeWalker {
    /// Builds the node tree rooted at `window`.
    @MainActor
    static func node(for window: UIWindow) -> AccessibilityNode {
        node(for: window, window: window)
    }

    @MainActor
    private static func node(for object: NSObject, window: UIWindow) -> AccessibilityNode {
        let children = accessibilityChildren(of: object).map { node(for: $0, window: window) }
        return AccessibilityNode(
            identifier: (object as? UIAccessibilityIdentification)?.accessibilityIdentifier ?? "",
            label: object.accessibilityLabel ?? "",
            value: object.accessibilityValue,
            traits: object.accessibilityTraits,
            frame: windowFrame(forScreenFrame: object.accessibilityFrame, window: window),
            isAccessibilityElement: object.isAccessibilityElement,
            children: children
        )
    }

    /// An element's accessibility children: explicit `accessibilityElements`
    /// when present, otherwise the view's subviews.
    @MainActor
    private static func accessibilityChildren(of object: NSObject) -> [NSObject] {
        if let elements = object.accessibilityElements as? [NSObject] {
            return elements
        }
        if let view = object as? UIView {
            return view.subviews
        }
        return []
    }

    /// Converts a screen-space accessibility frame into window coordinates so
    /// it lines up with the window screenshot.
    @MainActor
    static func windowFrame(forScreenFrame screenFrame: CGRect, window: UIWindow) -> CGRect {
        window.coordinateSpace.convert(screenFrame, from: window.screen.coordinateSpace)
    }

    /// Best-effort navigation-bar titles found in the view tree. SwiftUI may
    /// not populate `topItem.title`, in which case the screen-title check
    /// simply does not fire.
    @MainActor
    static func navigationBarTitles(in window: UIWindow) -> [String] {
        var titles: [String] = []
        func walk(_ view: UIView) {
            if let navBar = view as? UINavigationBar {
                titles.append(navBar.topItem?.title ?? "")
            }
            view.subviews.forEach(walk)
        }
        walk(window)
        return titles
    }
}
#endif
