import AccessibilityAuditReport
import Foundation
import XCTest

final class AcceptanceRuleTests: XCTestCase {
    func testDecodesFullRule() throws {
        let json = """
        {
          "screen": "Home",
          "variant": null,
          "auditType": "Label in Name",
          "elementIdentifier": "saveButton",
          "elementLabel": "Save",
          "context": "Accessible label \\"Save\\" does not contain visible text \\"OK\\"",
          "reason": "Reviewed 2026-06-13 SG"
        }
        """
        let rule = try JSONDecoder().decode(AcceptanceRule.self, from: Data(json.utf8))

        XCTAssertEqual(rule.screen, "Home")
        XCTAssertNil(rule.variant)
        XCTAssertEqual(rule.auditType, "Label in Name")
        XCTAssertEqual(rule.elementIdentifier, "saveButton")
        XCTAssertEqual(rule.elementLabel, "Save")
        XCTAssertEqual(rule.reason, "Reviewed 2026-06-13 SG")
    }

    func testDecodesMinimalRuleWithOptionalsAbsent() throws {
        let json = """
        { "screen": "Home", "auditType": "Generic Label", "reason": "False positive" }
        """
        let rule = try JSONDecoder().decode(AcceptanceRule.self, from: Data(json.utf8))

        XCTAssertNil(rule.variant)
        XCTAssertNil(rule.elementIdentifier)
        XCTAssertNil(rule.elementLabel)
        XCTAssertNil(rule.context)
        XCTAssertEqual(rule.reason, "False positive")
    }

    func testMissingReasonFailsToDecode() {
        let json = """
        { "screen": "Home", "auditType": "Generic Label" }
        """
        XCTAssertThrowsError(try JSONDecoder().decode(AcceptanceRule.self, from: Data(json.utf8)))
    }
}
