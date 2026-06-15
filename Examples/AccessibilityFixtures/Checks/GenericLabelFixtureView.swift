//
//  GenericLabelFixtureView.swift
//  AccessibilityFixtures
//
//  Created by Stephen Gurnett on 15/06/2026.
//

import SwiftUI

struct GenericLabelFixtureView: View {
    let check = FixtureCatalog.first(id: "genericLabel")!
    var body: some View {
        FixtureScaffold(check: check) {
            button("generic.pass", "Delete photo")
        } fail: {
            button("generic.fail", "Button")   // generic role word
        }
    }
    func button(_ id: String, _ label: String) -> some View {
        Button(action: {}) { Image(systemName: "trash").frame(width: 44, height: 44) }
            .accessibilityLabel(label)
            .accessibilityIdentifier(id)
    }
}
