//  DeepLinkRouter.swift
import SwiftUI

/// Maps the `-fixtureScreen <id>` launch argument (read via UserDefaults'
/// NSArgumentDomain) to a root view. Absent the argument, shows the gallery.
struct DeepLinkRouter: View {
    var screenId: String? { UserDefaults.standard.string(forKey: "fixtureScreen") }

    var body: some View {
        if let id = screenId {
            view(for: id)
        } else {
            FixtureListView()
        }
    }

    @ViewBuilder
    func view(for id: String) -> some View {
        switch id {
        case "targetSize":        TargetSizeFixtureView()
        case "targetSpacing":     TargetSpacingFixtureView()
        case "screenTitleFail":   ScreenTitleFixtureView(mode: .fail)
        case "screenTitlePass":   ScreenTitleFixtureView(mode: .pass)
        case "duplicateLabels":   DuplicateLabelsFixtureView()
        case "labelInName":       LabelInNameFixtureView()
        case "genericLabel":      GenericLabelFixtureView()
        case "labelHygiene":      LabelHygieneFixtureView()
        case "adjustableValue":   AdjustableValueFixtureView()
        case "inputPurpose":      InputPurposeFixtureView()
        case "cidA":              ConsistentIdentificationFixtureView(screen: .a)
        case "cidB":              ConsistentIdentificationFixtureView(screen: .b)
        case "orientation":       OrientationFixtureView()
        default:
            if id.hasPrefix("apple."),
               let (kind, mode) = AppleAuditFixtureView.parse(id) {
                AppleAuditFixtureView(kind: kind, mode: mode)
            } else if let check = FixtureCatalog.first(id: manualId(from: id)) {
                ManualReviewFixtureView(check: check)
            } else {
                Text("Unknown fixture: \(id)")
            }
        }
    }

    /// Manual/future screen ids are stored on the catalog entry as
    /// "manual.<id>" / "future.<id>"; map the screen id back to its entry.
    func manualId(from screenId: String) -> String {
        FixtureCatalog.all.first { $0.screenId == screenId }?.id ?? screenId
    }
}
