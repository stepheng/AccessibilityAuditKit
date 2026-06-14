//  EmptyValueSlider.swift
import SwiftUI
import UIKit

/// A UISlider whose accessibilityValue is forced empty, so the Adjustable Value
/// check (which flags adjustable controls with no value) fires. This is the one
/// fixture that needs UIKit — SwiftUI's Slider always exposes a value.
final class ValuelessUISlider: UISlider {
    override var accessibilityValue: String? {
        get { "" }
        set { /* ignore */ }
    }
}

struct EmptyValueSlider: UIViewRepresentable {
    func makeUIView(context: Context) -> ValuelessUISlider {
        let slider = ValuelessUISlider()
        slider.minimumValue = 0; slider.maximumValue = 1; slider.value = 0.5
        slider.isAccessibilityElement = true
        slider.accessibilityIdentifier = "adjustable.fail"
        slider.accessibilityLabel = "Brightness"
        return slider
    }
    func updateUIView(_ uiView: ValuelessUISlider, context: Context) {}
}
