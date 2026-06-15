//
//  InputPurposeFixtureView.swift
//  AccessibilityFixtures
//
//  Created by Stephen Gurnett on 15/06/2026.
//

import SwiftUI

struct InputPurposeFixtureView: View {
    let check = FixtureCatalog.first(id: "inputPurpose")!
    @State private var pass = ""
    @State private var fail = ""
    var body: some View {
        FixtureScaffold(check: check) {
            TextField("Album name", text: $pass)            // no personal-data tokens
                .textFieldStyle(.roundedBorder)
                .accessibilityLabel("Album name")
                .accessibilityIdentifier("inputPurpose.pass")
        } fail: {
            TextField("Email address", text: $fail)          // personal-data tokens → flagged
                .textFieldStyle(.roundedBorder)
                .accessibilityLabel("Email address")
                .accessibilityIdentifier("inputPurpose.fail")
        }
    }
}
