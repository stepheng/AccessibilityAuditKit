//  ConsistentIdentificationFixtureView.swift
import SwiftUI

struct ConsistentIdentificationFixtureView: View {
    enum Screen { case a, b }
    let screen: Screen
    let check = FixtureCatalog.first(id: "consistentIdentification")!

    var body: some View {
        VStack(spacing: 24) {
            Text("Consistent Identification — screen \(screen == .a ? "A" : "B")")
                .font(.headline)
            // FAIL element: same identifier, different label across the two screens.
            Button(action: {}) {
                Image(systemName: "person.crop.circle").frame(width: 44, height: 44)
            }
            .accessibilityLabel(screen == .a ? "Profile" : "Account")
            .accessibilityIdentifier("cid.control")
            // PASS element: same identifier AND same label across both screens.
            Button(action: {}) {
                Image(systemName: "gear").frame(width: 44, height: 44)
            }
            .accessibilityLabel("Settings")
            .accessibilityIdentifier("cid.consistent")
        }
        .padding()
    }
}
