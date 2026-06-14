//  OrientationFixtureView.swift
import SwiftUI

/// A normal adaptive screen. The pass/fail difference is driven entirely by the
/// `-lockOrientation portrait` launch argument handled in AppDelegate; the view
/// itself simply renders and rotates with the window.
struct OrientationFixtureView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("Orientation fixture").font(.headline)
            Text("Rotate the device. With -lockOrientation portrait the window stays portrait (fail).")
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
