//  DuplicateLabelsFixtureView.swift
import SwiftUI

struct DuplicateLabelsFixtureView: View {
    let check = FixtureCatalog.first(id: "duplicateLabels")!
    var body: some View {
        FixtureScaffold(check: check) {
            HStack {
                labelled("dup.photos", "Open Photos")
                labelled("dup.files", "Open Files")
            }
        } fail: {
            HStack {
                labelled("dup.openA", "Open")
                labelled("dup.openB", "Open")
            }
        }
    }
    func labelled(_ id: String, _ label: String) -> some View {
        Button(action: {}) { Image(systemName: "folder").frame(width: 44, height: 44) }
            .accessibilityLabel(label)
            .accessibilityIdentifier(id)
    }
}
