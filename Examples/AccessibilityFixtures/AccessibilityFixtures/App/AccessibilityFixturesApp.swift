//  AccessibilityFixturesApp.swift
import SwiftUI

@main
struct AccessibilityFixturesApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene {
        WindowGroup { DeepLinkRouter() }
    }
}
