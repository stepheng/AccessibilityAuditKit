//
//  LabelInNameFixtureView.swift
//  AccessibilityFixtures
//
//  Created by Stephen Gurnett on 15/06/2026.
//

import SwiftUI
import UIKit

// MARK: - UIKit helpers for label-in-name fixture

/// A UIButton that exposes its title label as a child in the accessibility
/// snapshot so the scanner's descendantStaticTextLabels walk finds the visible
/// text even when accessibilityLabel is overridden on the button itself.
private final class LabelInNameButton: UIButton {
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .systemBlue
        setTitleColor(.white, for: .normal)
        titleLabel?.font = .preferredFont(forTextStyle: .body)
        // Do NOT set isAccessibilityElement = false on titleLabel;
        // UIButton exposes its titleLabel as a .staticText child by default.
    }
    required init?(coder: NSCoder) { fatalError() }
}

private struct LabelInNameUIButton: UIViewRepresentable {
    let title: String
    let accessLabel: String
    let identifier: String

    func makeUIView(context: Context) -> LabelInNameButton {
        let button = LabelInNameButton(type: .custom)
        button.setTitle(title, for: .normal)              // visible text → .staticText child in snapshot
        button.accessibilityLabel = accessLabel           // overridden name
        button.accessibilityIdentifier = identifier
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.heightAnchor.constraint(equalToConstant: 44),
            button.widthAnchor.constraint(greaterThanOrEqualToConstant: 88)
        ])
        return button
    }
    func updateUIView(_ uiView: LabelInNameButton, context: Context) {}
}

// MARK: - Fixture view

struct LabelInNameFixtureView: View {
    let check = FixtureCatalog.first(id: "labelInName")!
    var body: some View {
        FixtureScaffold(check: check) {
            // Accessible label "Submit form" contains the visible text "Submit" → clean.
            LabelInNameUIButton(title: "Submit", accessLabel: "Submit form",
                                identifier: "labelInName.pass")
        } fail: {
            // Accessible label "Send" does NOT contain visible text "Submit" → flagged.
            LabelInNameUIButton(title: "Submit", accessLabel: "Send",
                                identifier: "labelInName.fail")
        }
    }
}
