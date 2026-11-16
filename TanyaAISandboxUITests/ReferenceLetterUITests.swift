//
//  ReferenceLetterUITests.swift
//  TanyaAISandboxUITests
//
//  Created by Wendra on 16/11/26.
//

import XCTest

final class ReferenceLetterUITests: XCTestCase {
    private let application = XCUIApplication()

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    func testDefaultsAndReadOnlyDeliveryFollowBackendCodes() {
        launch()
        XCTAssertEqual(application.buttons["referenceLetter.purpose"].value as? String, "Parameter 1")
        XCTAssertEqual(application.buttons["referenceLetter.documentFormat"].value as? String, "Softcopy")
        let email = application.textFields["referenceLetter.email"]
        scrollTo(email)
        XCTAssertFalse(email.isEnabled)
        XCTAssertEqual(email.value as? String, "sample@example.com")
        open("referenceLetter.documentFormat")
        application.buttons["Hardcopy"].tap()
        let address = application.textFields["referenceLetter.address"]
        scrollTo(address)
        XCTAssertFalse(address.isEnabled)
        XCTAssertEqual(address.value as? String, "Jl Bsd Grand Boulevard")
        XCTAssertFalse(email.exists)
    }

    func testInquiryOnlyFormHasNoSubmitCapability() {
        launch()
        let send = application.buttons["referenceLetter.send"]
        scrollTo(send)
        XCTAssertFalse(send.isEnabled)
    }

}

// MARK: - Helpers

private extension ReferenceLetterUITests {
    var sheet: XCUIElement { application.descendants(matching: .any)["sheet"] }

    func launch(extra: [String] = []) {
        application.launchArguments = ["--language", "en", "--reference-letter-demo"] + extra
        application.launch()
        let open = application.buttons["sandbox.open"]
        XCTAssertTrue(open.waitForExistence(timeout: 10))
        open.tap()
        let composer = application.textViews["composer.input"]
        XCTAssertTrue(composer.waitForExistence(timeout: 10))
        composer.tap()
        composer.typeText("Reference letter")
        application.buttons["composer.send"].tap()
        XCTAssertTrue(application.buttons["referenceLetter.purpose"].waitForExistence(timeout: 10))
    }

    func open(_ identifier: String) {
        let field = application.buttons[identifier]
        scrollTo(field)
        field.tap()
    }

    func scrollTo(_ element: XCUIElement) {
        let table = application.tables.firstMatch
        for _ in 0..<12 {
            if element.isHittable { return }
            if element.frame.minY < table.frame.minY {
                table.swipeDown()
            } else {
                table.swipeUp()
            }
        }
        XCTAssertTrue(element.isHittable)
    }
}
