//
//  AccessibilityFixturesApp.swift
//  AccessibilityFixtures
//
//  Created by Stephen Gurnett on 14/06/2026.
//

import SwiftUI

@main
struct AccessibilityFixturesApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene {
        WindowGroup { DeepLinkRouter() }
    }
}
