//
//  AdjustableValueFixtureView.swift
//  AccessibilityFixtures
//
//  Created by Stephen Gurnett on 14/06/2026.
//

import SwiftUI

struct AdjustableValueFixtureView: View {
    let check = FixtureCatalog.first(id: "adjustableValue")!
    @State private var value = 0.5
    var body: some View {
        FixtureScaffold(check: check) {
            Slider(value: $value)                           // exposes "50%"
                .accessibilityLabel("Volume")
                .accessibilityIdentifier("adjustable.pass")
        } fail: {
            EmptyValueSlider().frame(height: 30)            // exposes no value
        }
    }
}
