//  AppDelegate.swift
import UIKit

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        // The Orientation fixture launches with `-lockOrientation portrait` to
        // force the failing (locked) case; otherwise the app adapts.
        if UserDefaults.standard.string(forKey: "lockOrientation") == "portrait" {
            return .portrait
        }
        return .allButUpsideDown
    }
}
