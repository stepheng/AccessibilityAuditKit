//
//  AccessibilityNode.swift
//  AccessibilityAuditReport
//
//  Created by Stephen Gurnett on 14/06/2026.
//

#if canImport(UIKit)
import CoreGraphics
import UIKit

/// A value snapshot of one accessibility element, decoupled from the live
/// view hierarchy so the scan logic can be unit-tested without real views.
/// Frames are already converted into the audited window's coordinate space.
struct AccessibilityNode {
    var identifier: String
    var label: String
    var value: String?
    var traits: UIAccessibilityTraits
    var frame: CGRect
    var isAccessibilityElement: Bool
    var objectClassName: String
    var objectModuleName: String?
    var ownerClassName: String?
    var ownerModuleName: String?
    /// Whether the source object is a direct child of a `UIScrollView`. iOS
    /// exposes the system scroll indicator this way, so the scan can identify
    /// it structurally rather than by its localized "scroll bar" label.
    var ownerIsScrollView: Bool
    var children: [AccessibilityNode]

    init(
        identifier: String = "",
        label: String = "",
        value: String? = nil,
        traits: UIAccessibilityTraits = .none,
        frame: CGRect = .zero,
        isAccessibilityElement: Bool = false,
        objectClassName: String = "",
        objectModuleName: String? = nil,
        ownerClassName: String? = nil,
        ownerModuleName: String? = nil,
        ownerIsScrollView: Bool = false,
        children: [AccessibilityNode] = []
    ) {
        self.identifier = identifier
        self.label = label
        self.value = value
        self.traits = traits
        self.frame = frame
        self.isAccessibilityElement = isAccessibilityElement
        self.objectClassName = objectClassName
        self.objectModuleName = objectModuleName
        self.ownerClassName = ownerClassName
        self.ownerModuleName = ownerModuleName
        self.ownerIsScrollView = ownerIsScrollView
        self.children = children
    }
}
#endif
