//  FixtureListView.swift
import SwiftUI

struct FixtureListView: View {
    var body: some View {
        NavigationStack {
            List {
                ForEach(FixtureCategory.allCases, id: \.self) { category in
                    Section(category.rawValue) {
                        ForEach(FixtureCatalog.all.filter { $0.category == category }) { check in
                            NavigationLink(value: check.id) {
                                VStack(alignment: .leading) {
                                    Text(check.title)
                                    Text("WCAG \(check.wcag) · \(check.summary)")
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Accessibility Fixtures")
            .navigationDestination(for: String.self) { id in
                DeepLinkRouter().view(for: galleryScreenId(for: id))
            }
        }
    }

    /// In the gallery, route via the catalog entry's screen id (or a sensible
    /// default for the multi-screen checks so browsing always lands somewhere).
    func galleryScreenId(for checkId: String) -> String {
        guard let check = FixtureCatalog.first(id: checkId) else { return checkId }
        if let s = check.screenId { return s }
        if let s = check.failScreenId { return s }
        return checkId
    }
}
