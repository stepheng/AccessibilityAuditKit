import Foundation
import XCTest

final class AccessibilityFixturesProjectTests: XCTestCase {
    func testFixturesAppGeneratesLaunchScreenForFullScreenIPhoneLayout() throws {
        let root = packageRoot()
        let generator = try String(
            contentsOf: root.appending(path: "Examples/AccessibilityFixtures/generate_project.rb"),
            encoding: .utf8
        )
        let project = try String(
            contentsOf: root.appending(path: "Examples/AccessibilityFixtures/AccessibilityFixtures.xcodeproj/project.pbxproj"),
            encoding: .utf8
        )

        XCTAssertTrue(
            generator.contains("INFOPLIST_KEY_UILaunchScreen_Generation"),
            "The fixtures project generator should keep a generated launch screen enabled so iPhone uses the full display."
        )
        XCTAssertEqual(
            project.components(separatedBy: "INFOPLIST_KEY_UILaunchScreen_Generation = YES;").count - 1,
            2,
            "Both Debug and Release app configurations should enable a generated launch screen."
        )
    }

    private func packageRoot() -> URL {
        var url = URL(fileURLWithPath: #filePath)
        while url.lastPathComponent != "Tests" {
            url.deleteLastPathComponent()
        }
        url.deleteLastPathComponent()
        return url
    }
}
