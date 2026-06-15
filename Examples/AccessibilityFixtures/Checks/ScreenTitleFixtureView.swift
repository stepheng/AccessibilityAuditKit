//
//  ScreenTitleFixtureView.swift
//  AccessibilityFixtures
//
//  Created by Stephen Gurnett on 14/06/2026.
//

import SwiftUI

struct ScreenTitleFixtureView: View {
    enum Mode { case fail, pass }
    let mode: Mode
    var body: some View {
        NavigationStack {
            Text(mode == .pass ? "Titled screen" : "Untitled screen")
                .navigationTitle(mode == .pass ? "Settings" : "")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    // Force the navigation bar to render even with an empty title.
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Action") {}.accessibilityIdentifier("screenTitle.toolbar")
                    }
                }
        }
    }
}
