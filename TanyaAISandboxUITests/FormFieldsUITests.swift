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
        let confirm = application.buttons["Confirm"]
        application.revealReferenceLetter(confirm)
        let formRow = application.tables["chat.messages"].cells
            .containing(.any, identifier: "chat.referenceLetter.form").firstMatch
        let heightBeforeValidation = formRow.frame.height
        confirm.tap()
        XCTAssertTrue(application.buttons["Tanda 360 - 2345 5678 2386"].waitForExistence(timeout: 5))
        XCTAssertFalse(application.buttons["pin.digit.1"].exists)
        application.buttons["sheet.handle"].tap()

        let inlineError = application.staticTexts["Please complete this field."].firstMatch
        XCTAssertTrue(inlineError.waitForExistence(timeout: 5))
        XCTAssertGreaterThan(formRow.frame.height, heightBeforeValidation)
    }

    func testInquiryFailureHidesTheCard() {
        application.launchReferenceLetter(
            extraArguments: ["--reference-letter-inquiry-failure"],
            isWaitingForForm: false
        )
        let elements = application.descendants(matching: .any)
        let loading = elements["chat.referenceLetter.loading"]
        XCTAssertTrue(loading.waitForExistence(timeout: 5))
        let hidden = expectation(for: NSPredicate(format: "exists == false"), evaluatedWith: loading)
        wait(for: [hidden], timeout: 8)

        let reply = "Silakan lengkapi data pengajuan Surat Referensi."
        XCTAssertTrue(application.staticTexts[reply].exists)
        XCTAssertFalse(elements["chat.referenceLetter.form"].exists)
        XCTAssertFalse(application.staticTexts["Order a reference letter"].exists)
        XCTAssertFalse(application.buttons["Retry loading the reference letter form"].exists)
    }

    func testRowGrowsAfterInquiryLoads() {
        application.launchReferenceLetter(extraArguments: ["--reference-letter-slow-inquiry"], isWaitingForForm: false)
        let table = application.tables["chat.messages"]
        let loadingRow = table.cells.containing(.any, identifier: "chat.referenceLetter.loading").firstMatch
        XCTAssertTrue(loadingRow.waitForExistence(timeout: 5))
        let loadingHeight = loadingRow.frame.height
        let formRow = table.cells.containing(.any, identifier: "chat.referenceLetter.form").firstMatch
        XCTAssertTrue(formRow.waitForExistence(timeout: 8))
        XCTAssertGreaterThan(formRow.frame.height, loadingHeight)
        application.revealReferenceLetter(application.buttons["Confirm"])
    }

    func testCancelShowsStatusCard() {
        application.launchReferenceLetter()
        let cancel = application.buttons["Cancel"]
        application.revealReferenceLetter(cancel)
        let table = application.tables["chat.messages"]
        let formRow = table.cells.containing(.any, identifier: "chat.referenceLetter.form").firstMatch
        let formHeight = formRow.frame.height
        cancel.tap()
        let status = table.cells.containing(.any, identifier: "chat.referenceLetter.cancelled").firstMatch
        XCTAssertTrue(status.waitForExistence(timeout: 5))
        XCTAssertLessThan(status.frame.height, formHeight)
        XCTAssertFalse(application.buttons["Document format"].exists)
    }
}

// MARK: - Helpers

extension XCUIApplication {
    func launchReferenceLetter(extraArguments: [String] = [], isWaitingForForm: Bool = true) {
        launchArguments = ["--language", "en", "--form-demo", "--with-history"] + extraArguments
        launch()
        let entry = buttons["sandbox.open"]
        XCTAssertTrue(entry.waitForExistence(timeout: 10))
        entry.tap()
        let input = textViews["composer.input"]
        XCTAssertTrue(input.waitForExistence(timeout: 10))
        input.tap()
        input.typeText("Ajukan Surat Referensi")
        buttons["composer.send"].tap()
        if isWaitingForForm {
            XCTAssertTrue(buttons["Document format"].waitForExistence(timeout: 10))
        }
    }

    /// Field awal dan tombol di akhir kartu tidak selalu terlihat dalam viewport yang sama.
    func revealReferenceLetter(_ element: XCUIElement) {
        let table = tables["chat.messages"]
        for _ in 0..<3 where !element.isHittable { table.swipeUp() }
        for _ in 0..<3 where !element.isHittable { table.swipeDown() }
        XCTAssertTrue(element.isHittable)
    }
}
