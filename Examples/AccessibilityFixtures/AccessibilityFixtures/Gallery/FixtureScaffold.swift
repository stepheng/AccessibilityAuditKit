//  FixtureScaffold.swift
import SwiftUI
import UIKit

/// Shared chrome: a header (title / WCAG / expected outcome) over a PASS and a
/// FAIL section. Individual check views drop their elements into the sections.
struct FixtureScaffold<Pass: View, Fail: View>: View {
    let check: FixtureCheck
    @ViewBuilder var pass: () -> Pass
    @ViewBuilder var fail: () -> Fail

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(check.title).font(.title2).bold()
                    Text("WCAG \(check.wcag) - Level \(check.level)").font(.caption).foregroundStyle(.secondary)
                    Text(check.expectedOutcome).font(.callout).padding(.top, 4)
                }
                section("PASS ✓", tint: .green) { pass() }
                section("FAIL ✗", tint: .red) { fail() }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    func section<Content: View>(_ title: String, tint: Color, @ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(.headline).foregroundStyle(tint)
            content()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tint.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
    }
}

/// Gallery view for manual-review and scripted checks: shows the expected
/// outcome and (where the check defines them) the same good/bad examples a human
/// inspects. No assertion runs against these.
struct ManualReviewFixtureView: View {
    let check: FixtureCheck
    var body: some View {
        FixtureScaffold(check: check) {
            Text("Good example — verify by hand.").accessibilityIdentifier("\(check.id).good")
        } fail: {
            Text("Bad example — verify by hand.").accessibilityIdentifier("\(check.id).bad")
        }
    }
}

struct NonTextContrastFixtureView: View {
    private let check = FixtureCatalog.first(id: "nonTextContrast")!

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(check.title).font(.title2).bold()
                    Text("WCAG \(check.wcag) · Level \(check.level)").font(.caption).foregroundStyle(.secondary)
                    Text(check.expectedOutcome).font(.callout).padding(.top, 4)
                }
                fixtureRow("PASS", tint: .green) {
                    glyph(
                        identifier: "nonTextContrast.pass",
                        label: "High contrast graphic",
                        foreground: 0,
                        background: 255
                    )
                }
                fixtureRow("FAIL", tint: .red) {
                    glyph(
                        identifier: "nonTextContrast.fail",
                        label: "Low contrast graphic",
                        foreground: 118,
                        background: 149
                    )
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color.white)
    }

    private func fixtureRow<Content: View>(
        _ title: String,
        tint: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(.headline).foregroundStyle(tint)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func glyph(
        identifier: String,
        label: String,
        foreground: UInt8,
        background: UInt8
    ) -> some View {
        Image(uiImage: image(foreground: foreground, background: background))
            .resizable()
            .frame(width: 44, height: 44)
            .accessibilityLabel(label)
            .accessibilityIdentifier(identifier)
    }

    private func image(foreground: UInt8, background: UInt8) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 44, height: 44))
        return renderer.image { context in
            UIColor(white: CGFloat(background) / 255, alpha: 1).setFill()
            context.fill(CGRect(x: 0, y: 0, width: 44, height: 44))
            UIColor(white: CGFloat(foreground) / 255, alpha: 1).setFill()
            context.fill(CGRect(x: 10, y: 10, width: 24, height: 24))
        }
    }
}

struct StatusMessagesFixtureView: View {
    private let check = FixtureCatalog.first(id: "statusMessages")!
    @State private var passStatus = "Ready to upload"
    @State private var failStatus = "Draft has unsaved changes"
    @State private var passObserved = "No status message observed"
    @State private var failObserved = "No status message observed"

    var body: some View {
        FixtureScaffold(check: check) {
            statusControl(
                title: "Start upload",
                status: passStatus,
                observed: passObserved,
                buttonIdentifier: "statusMessages.pass",
                observedIdentifier: "statusMessages.pass.observed"
            ) {
                passStatus = "Upload in progress"
                announce("Upload started", observed: $passObserved)
            }
        } fail: {
            statusControl(
                title: "Save draft silently",
                status: failStatus,
                observed: failObserved,
                buttonIdentifier: "statusMessages.fail",
                observedIdentifier: "statusMessages.fail.observed"
            ) {
                failStatus = "Draft saved"
            }
        }
    }

    private func statusControl(
        title: String,
        status: String,
        observed: String,
        buttonIdentifier: String,
        observedIdentifier: String,
        action: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(status)
                .font(.body)
            Button(title, action: action)
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier(buttonIdentifier)
            Text(observed)
                .font(.caption)
                .foregroundStyle(.secondary)
                .accessibilityIdentifier(observedIdentifier)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func announce(_ message: String, observed: Binding<String>) {
        observed.wrappedValue = message
        UIAccessibility.post(notification: .announcement, argument: message)
    }
}

struct ResizeReflowFixtureView: View {
    private let check = FixtureCatalog.first(id: "resizeReflow")!

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(check.title).font(.title2).bold()
                    Text("WCAG \(check.wcag) - Level \(check.level)").font(.caption).foregroundStyle(.secondary)
                    Text(check.expectedOutcome).font(.callout).padding(.top, 4)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("PASS").font(.headline).foregroundStyle(.green)
                    VStack(alignment: .leading) {
                        Text(adaptiveSummary)
                            .font(.body)
                            .lineLimit(nil)
                            .multilineTextAlignment(.leading)
                    }
                    .frame(width: 300, alignment: .leading)
                    .accessibilityElement(children: .combine)
                    .accessibilityIdentifier("resizeReflow.pass")
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("FAIL").font(.headline).foregroundStyle(.red)
                    VStack(alignment: .leading) {
                        Text(fixedWidthSummary)
                            .font(.body)
                            .fixedSize(horizontal: true, vertical: false)
                    }
                    .frame(width: 720, alignment: .leading)
                    .accessibilityElement(children: .combine)
                    .accessibilityIdentifier("resizeReflow.fail")
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var adaptiveSummary: String {
        "Your recovery key is ready. Keep this information somewhere secure so it can wrap naturally at larger text sizes."
    }

    private var fixedWidthSummary: String {
        "Your recovery key is ready, keep this long fixed-width message visible without requiring horizontal scrolling."
    }
}
