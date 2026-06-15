//
//  AppDelegate.swift
//  AccessibilityFixtures
//
//  Created by Stephen Gurnett on 14/06/2026.
//

import UIKit

#if DEBUG
import AccessibilityAuditLiveSupport
#endif

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
#if DEBUG
        // Keep the in-process accessibility audit in the binary so it can be
        // driven from LLDB (`po AXAudit.run()`); nothing else references it.
        AXAudit.link()
#endif

        // The Orientation fixture launches with `-lockOrientation portrait` to
        // force the failing (locked) case; otherwise the app adapts.
        if UserDefaults.standard.string(forKey: "lockOrientation") == "portrait" {
            return .portrait
        }
        return .allButUpsideDown
    }
}
