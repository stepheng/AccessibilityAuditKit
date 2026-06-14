//  InputPurposeFixtureView.swift
import SwiftUI

struct InputPurposeFixtureView: View {
    let check = FixtureCatalog.first(id: "inputPurpose")!
    @State private var pass = ""
    @State private var fail = ""
    var body: some View {
        FixtureScaffold(check: check) {
            TextField("Album name", text: $pass)            // no personal-data tokens
                .textFieldStyle(.roundedBorder)
                .accessibilityIdentifier("inputPurpose.pass")
        } fail: {
            TextField("Email address", text: $fail)          // personal-data tokens
                .textFieldStyle(.roundedBorder)
                .accessibilityIdentifier("inputPurpose.fail")
        }
    }
}
