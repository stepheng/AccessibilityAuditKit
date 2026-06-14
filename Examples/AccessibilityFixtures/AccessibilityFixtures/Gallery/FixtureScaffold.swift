//  FixtureScaffold.swift
import SwiftUI

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
                    Text("WCAG \(check.wcag) · Level \(check.level)").font(.caption).foregroundStyle(.secondary)
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

/// Gallery view for manual-review and future-gap checks: shows the expected
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
