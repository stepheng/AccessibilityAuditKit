//  LabelHygieneFixtureView.swift
import SwiftUI

struct LabelHygieneFixtureView: View {
    let check = FixtureCatalog.first(id: "labelHygiene")!
    var body: some View {
        FixtureScaffold(check: check) {
            button("hygiene.pass", "Save")
        } fail: {
            button("hygiene.fail", "Save button")   // redundant role suffix
        }
    }
    func button(_ id: String, _ label: String) -> some View {
        Button(action: {}) { Image(systemName: "square.and.arrow.down").frame(width: 44, height: 44) }
            .accessibilityLabel(label)
            .accessibilityIdentifier(id)
    }
}
