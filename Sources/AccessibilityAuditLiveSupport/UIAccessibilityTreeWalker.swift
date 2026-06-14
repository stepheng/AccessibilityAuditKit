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
    private static func node(
        for object: NSObject,
        window: UIWindow,
        ownerIsScrollView: Bool = false,
        ownerObject: NSObject? = nil
    ) -> AccessibilityNode {
        let objectIsScrollView = object is UIScrollView
        let children = accessibilityChildren(of: object).map {
            node(for: $0, window: window, ownerIsScrollView: objectIsScrollView, ownerObject: object)
        }
        return AccessibilityNode(
            identifier: accessibilityIdentifier(of: object),
            label: object.accessibilityLabel ?? "",
            value: object.accessibilityValue,
            traits: object.accessibilityTraits,
            frame: windowFrame(forScreenFrame: object.accessibilityFrame, window: window),
            isAccessibilityElement: object.isAccessibilityElement,
            objectClassName: className(of: object),
            objectModuleName: moduleName(of: object),
            ownerClassName: ownerObject.map { className(of: $0) },
            ownerModuleName: ownerObject.flatMap { moduleName(of: $0) },
            ownerIsScrollView: ownerIsScrollView,
            children: children
        )
    }

    @MainActor
    private static func accessibilityIdentifier(of object: NSObject) -> String {
        if let identifier = (object as? UIAccessibilityIdentification)?.accessibilityIdentifier {
            return identifier
        }
        if let view = object as? UIView {
            return view.accessibilityIdentifier ?? ""
        }
        return ""
    }

    private static func className(of object: NSObject) -> String {
        String(describing: type(of: object))
    }

    private static func moduleName(of object: NSObject) -> String? {
        let qualified = NSStringFromClass(type(of: object))
        if let separator = qualified.firstIndex(of: ".") {
            return String(qualified[..<separator])
        }
        let reflected = String(reflecting: type(of: object))
        guard let separator = reflected.firstIndex(of: ".") else { return nil }
        return String(reflected[..<separator])
    }

    /// An element's accessibility children: explicit `accessibilityElements`
    /// when present, otherwise the view's subviews.
    @MainActor
    private static func accessibilityChildren(of object: NSObject) -> [NSObject] {
        if let elements = object.accessibilityElements {
            return elements.compactMap { $0 as? NSObject }
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

    /// Best-effort navigation-bar titles found in the view tree. Each bar's title
    /// is resolved from `topItem.title`, then (for SwiftUI, which routes the title
    /// through the accessibility tree) the first non-empty label of a `.header`- or
    /// `.staticText`-trait descendant, and finally "" when nothing is found — so a
    /// genuinely untitled bar is flagged while a detectable title is not. A SwiftUI
    /// title exposed in a way none of these detect may still false-positive.
    @MainActor
    static func navigationBarTitles(in window: UIWindow) -> [String] {
        var titles: [String] = []
        func walk(_ view: UIView) {
            if let navBar = view as? UINavigationBar {
                titles.append(navigationTitle(of: navBar))
            }
            view.subviews.forEach(walk)
        }
        walk(window)
        return titles
    }

    @MainActor
    private static func navigationTitle(of navBar: UINavigationBar) -> String {
        if let title = navBar.topItem?.title, !title.isEmpty {
            return title
        }
        return headerOrTextLabel(in: navBar) ?? ""
    }

    /// The first non-empty label of a `.header`- or `.staticText`-trait descendant,
    /// which is how SwiftUI exposes a navigation title in the accessibility tree.
    @MainActor
    private static func headerOrTextLabel(in view: UIView) -> String? {
        for subview in view.subviews {
            let traits = subview.accessibilityTraits
            if traits.contains(.header) || traits.contains(.staticText),
               let label = subview.accessibilityLabel, !label.isEmpty {
                return label
            }
            if let nested = headerOrTextLabel(in: subview) {
                return nested
            }
        }
        return nil
    }
}
#endif
