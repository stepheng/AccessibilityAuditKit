//  LabelInNameFixtureView.swift
import SwiftUI

struct LabelInNameFixtureView: View {
    let check = FixtureCatalog.first(id: "labelInName")!
    var body: some View {
        FixtureScaffold(check: check) {
            Button(action: {}) { Text("Submit").frame(minWidth: 88, minHeight: 44) }
                .accessibilityLabel("Submit form")               // contains "Submit"
                .accessibilityIdentifier("labelInName.pass")
        } fail: {
            Button(action: {}) { Text("Submit").frame(minWidth: 88, minHeight: 44) }
                .accessibilityLabel("Send")                      // missing "Submit"
                .accessibilityIdentifier("labelInName.fail")
        }
    }
}
