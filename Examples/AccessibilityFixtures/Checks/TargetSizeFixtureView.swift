//
//  TargetSizeFixtureView.swift
//  AccessibilityFixtures
//
//  Created by Stephen Gurnett on 14/06/2026.
//

import SwiftUI

struct TargetSizeFixtureView: View {
    let check = FixtureCatalog.first(id: "targetSizeMinimum")!
    var body: some View {
        FixtureScaffold(check: check) {
            swatch("targetSize.ok44", size: 44, color: .green)
        } fail: {
            VStack(alignment: .leading, spacing: 12) {
                swatch("targetSize.min20", size: 20, color: .red)        // 2.5.8 error
                swatch("targetSize.enhanced30", size: 30, color: .orange) // 2.5.5 warning
            }
        }
    }
    func swatch(_ id: String, size: CGFloat, color: Color) -> some View {
        Button(action: {}) { color.frame(width: size, height: size) }
            .buttonStyle(.plain)
            .accessibilityLabel("Size \(Int(size))")
            .accessibilityIdentifier(id)
    }
}
