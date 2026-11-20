//
//  FormFieldsUITests.swift
//  TanyaAISandboxUITests
//
//  Created by Wendra on 12/11/26.
//

import XCTest

/// `--form-demo`: pesan gateway menampilkan form dari inquiry host.
final class FormFieldsUITests: XCTestCase {
    private let application = XCUIApplication()

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    func testFormatChangesTheDeliveryField() {
        application.launchReferenceLetter()
        let email = application.textFields["Delivery email"]
        application.revealReferenceLetter(email)
        XCTAssertFalse(email.isEnabled)
        XCTAssertEqual(email.value as? String, "lara@example.com")

        application.revealReferenceLetter(application.buttons["Document format"])
        application.buttons["Document format"].tap()
        let hardcopy = application.buttons["Hardcopy"]
        XCTAssertTrue(hardcopy.waitForExistence(timeout: 5))
        hardcopy.tap()
        let address = application.textFields["Delivery address"]
        application.revealReferenceLetter(address)
        XCTAssertFalse(address.isEnabled)
        XCTAssertFalse(email.exists)
    }

    func testSeveralAccountsCanBeSelected() {
        application.launchReferenceLetter()
        let accounts = application.buttons["Accounts to include"]
        application.revealReferenceLetter(accounts)
        accounts.tap()

        let first = application.buttons["Tanda 360 - 2345 5678 2386"]
        XCTAssertTrue(first.waitForExistence(timeout: 5))
        XCTAssertEqual(first.value as? String, "IDR 1.000.000")
        first.tap()
        application.buttons["Giro Bisnis - 7781 2003 4551"].tap()
        application.buttons["Select"].tap()
        XCTAssertEqual(accounts.value as? String, "2 accounts selected")
    }

    func testInvalidFormOpensFirstChoice() {
        application.launchReferenceLetter()
        let send = application.buttons["Send"]
        application.revealReferenceLetter(send)
        send.tap()
        XCTAssertTrue(application.buttons["Tanda 360 - 2345 5678 2386"].waitForExistence(timeout: 5))
        XCTAssertFalse(application.buttons["pin.digit.1"].exists)
    }

    func testCancelShowsStatusCard() {
        application.launchReferenceLetter()
        let cancel = application.buttons["Cancel"]
        application.revealReferenceLetter(cancel)
        cancel.tap()
        let status = application.descendants(matching: .any).matching(
            NSPredicate(format: "label CONTAINS %@", "You cancelled the reference letter request.")
        ).firstMatch
        XCTAssertTrue(status.waitForExistence(timeout: 5))
        XCTAssertFalse(application.buttons["Document format"].exists)
    }
}

// MARK: - Helpers

extension XCUIApplication {
    func launchReferenceLetter() {
        launchArguments = ["--language", "en", "--form-demo", "--with-history"]
        launch()
        let entry = buttons["sandbox.open"]
        XCTAssertTrue(entry.waitForExistence(timeout: 10))
        entry.tap()
        let input = textViews["composer.input"]
        XCTAssertTrue(input.waitForExistence(timeout: 10))
        input.tap()
        input.typeText("Ajukan Surat Referensi")
        buttons["composer.send"].tap()
        XCTAssertTrue(buttons["Document format"].waitForExistence(timeout: 10))
    }

    /// Field awal dan tombol di akhir kartu tidak selalu terlihat dalam viewport yang sama.
    func revealReferenceLetter(_ element: XCUIElement) {
        let table = tables["chat.messages"]
        for _ in 0..<3 where !element.isHittable { table.swipeUp() }
        for _ in 0..<3 where !element.isHittable { table.swipeDown() }
        XCTAssertTrue(element.isHittable)
    }
}
