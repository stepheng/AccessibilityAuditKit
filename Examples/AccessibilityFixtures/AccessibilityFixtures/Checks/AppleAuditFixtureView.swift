//
//  AppleAuditFixtureView.swift
//  AccessibilityFixtures
//
//  Created by Stephen Gurnett on 14/06/2026.
//

import SwiftUI

struct AppleAuditFixtureView: View {
    enum Mode: String { case fail, pass }
    let kind: AppleAuditKind
    let mode: Mode

    /// Parses ids like "apple.contrast.fail" → (.contrast, .fail).
    static func parse(_ screenId: String) -> (AppleAuditKind, Mode)? {
        let parts = screenId.split(separator: ".")
        guard parts.count == 3, parts[0] == "apple",
              let mode = Mode(rawValue: String(parts[2])) else { return nil }
        let map: [String: AppleAuditKind] = [
            "contrast": .contrast, "hitRegion": .hitRegion,
            "description": .sufficientElementDescription, "dynamicType": .dynamicType,
            "textClipped": .textClipped, "trait": .trait, "elementDetection": .elementDetection
        ]
        guard let kind = map[String(parts[1])] else { return nil }
        return (kind, mode)
    }

    var body: some View {
        VStack(spacing: 16) { content }.padding().frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder var content: some View {
        switch kind {
        case .contrast:
            ZStack {
                Color.white
                Text("Low contrast text")
                    .foregroundColor(mode == .fail ? Color(white: 0.82) : .black)
            }
        case .hitRegion:
            Button("Tap") {}
                .frame(width: mode == .fail ? 12 : 44, height: mode == .fail ? 12 : 44)
        case .sufficientElementDescription:
            Button(action: {}) { Image(systemName: "bell") }
                .accessibilityLabel(mode == .fail ? "" : "Notifications")
        case .dynamicType:
            Text("Resize me").font(mode == .fail ? .system(size: 17) : .body)
        case .textClipped:
            Text(mode == .fail ? "This text is clipped by a tiny fixed frame" : "This text fits")
                .frame(width: mode == .fail ? 60 : 300, height: mode == .fail ? 12 : 40)
                .clipped()
        case .trait:
            Text("Heading").font(.title)
                .accessibilityAddTraits(mode == .fail ? [] : .isHeader)
        case .elementDetection:
            ZStack {
                Color.blue.frame(width: 80, height: 44)
                if mode == .fail { Color.blue.opacity(0.01).frame(width: 80, height: 44) }
            }
        }
    }
}
