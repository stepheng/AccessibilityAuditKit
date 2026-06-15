//
//  TargetSpacingFixtureView.swift
//  AccessibilityFixtures
//
//  Created by Stephen Gurnett on 14/06/2026.
//

import SwiftUI

struct TargetSpacingFixtureView: View {
    let check = FixtureCatalog.first(id: "targetSpacing")!
    var body: some View {
        FixtureScaffold(check: check) {
            // Two undersized targets 40pt apart centre-to-centre → circles clear.
            board {
                dot("targetSpacing.passA", x: 40, color: .green)
                dot("targetSpacing.passB", x: 80, color: .green)
            }
        } fail: {
            // Two undersized targets 16pt apart centre-to-centre → circles overlap.
            board {
                dot("targetSpacing.failA", x: 52, color: .red)
                dot("targetSpacing.failB", x: 68, color: .red)
            }
        }
    }
    func board<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        ZStack(alignment: .topLeading) { content() }
            .frame(width: 200, height: 60, alignment: .topLeading)
    }
    func dot(_ id: String, x: CGFloat, color: Color) -> some View {
        Button(action: {}) { color.frame(width: 20, height: 20) }
            .buttonStyle(.plain)
            .accessibilityLabel(id)
            .accessibilityIdentifier(id)
            .position(x: x, y: 30)
    }
}
