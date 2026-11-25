//
//  PinEntryUITests.swift
//  TanyaAISandboxUITests
//
//  Created by Wendra on 16/11/26.
//

import XCTest

/// `--form-demo`: form yang valid membuka sheet PIN. Keypad mengisi titik tanpa menampilkan angka, hapus membuang
/// digit terakhir, sheet terkunci selama PIN diperiksa, PIN salah mengosongkan titik dan menampilkan error, dan PIN
/// yang diterima menutup sheet. PIN di sini PIN tiruan sandbox (`SandboxOptions.formPin`).
final class PinEntryUITests: XCTestCase {
    private let application = XCUIApplication()

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    func testTheKeypadFillsTheDotsAndDeleteRemovesTheLastDigit() {
        openPinSheet()
        enter("12")
        XCTAssertEqual(dots.value as? String, "2")
        XCTAssertFalse(application.staticTexts["12"].exists, "angka PIN tidak tampil")
        application.buttons["pin.delete"].tap()
        XCTAssertEqual(dots.value as? String, "1")
        XCTAssertEqual(application.buttons["pin.delete"].label, "Delete digit")
        capture("pin-entry")
    }

    func testAWrongPinKeepsTheSheetOpenWithAnError() {
        let sheet = openPinSheet()
        enter("111111")
        application.buttons["header.back"].coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        XCTAssertTrue(sheet.exists, "terkunci selama PIN diperiksa")
        let error = application.staticTexts["Wrong PIN. Please try again."]
        XCTAssertTrue(error.waitForExistence(timeout: 5))
        XCTAssertEqual(dots.value as? String, "0", "titik dikosongkan")
        capture("pin-entry-wrong")
        enter("1")
        waitUntilGone(error)
    }

    func testBlockedPINCanBeEnteredAgain() {
        let sheet = openPinSheet(extraArguments: ["--reference-letter-pin-blocked"])
        enter("123456")
        let error = application.staticTexts["Your transaction PIN is blocked."]
        XCTAssertTrue(error.waitForExistence(timeout: 5))
        XCTAssertTrue(sheet.exists)
        XCTAssertEqual(dots.value as? String, "0")
        XCTAssertTrue(application.buttons["pin.digit.1"].isEnabled)

        enter("1")
        waitUntilGone(error)
        enter("23456")
        XCTAssertTrue(error.waitForExistence(timeout: 5))
        XCTAssertEqual(dots.value as? String, "0")
        XCTAssertFalse(application.staticTexts["The host could not submit your reference letter."].exists)
    }

    func testAckErrorMovesToTheHostSheet() {
        openPinSheet(extraArguments: ["--reference-letter-ack-failure"])
        enter("123456")
        let hostError = application.staticTexts["The host could not submit your reference letter."]
        XCTAssertTrue(hostError.waitForExistence(timeout: 5))
        XCTAssertFalse(dots.exists, "PIN must be dismissed before the host error is displayed")
        XCTAssertFalse(application.descendants(matching: .any)["chat.referenceLetter.success"].exists)
    }

    func testTheAcceptedPinClosesTheSheet() {
        let sheet = openPinSheet()
        enter("123456")
        waitUntilGone(sheet)
        let success = application.descendants(matching: .any)["chat.referenceLetter.success"]
        XCTAssertTrue(success.waitForExistence(timeout: 5))
        let note = application.staticTexts["Surat referensi akan diproses dalam 3 hari kerja."]
        XCTAssertTrue(note.waitForExistence(timeout: 5))
    }
}

// MARK: - Helpers

private extension PinEntryUITests {
    var dots: XCUIElement { application.descendants(matching: .any)["pin.dots"] }

    /// Format softcopy sudah terpilih. Lengkapi kedutaan, rekening, mata uang, dan bahasa.
    @discardableResult
    func openPinSheet(extraArguments: [String] = []) -> XCUIElement {
        application.launchReferenceLetter(extraArguments: extraArguments)
        let sheet = application.descendants(matching: .any)["sheet"]
        let embassy = application.textFields["Embassy or recipient institution"]
        application.revealReferenceLetter(embassy)
        embassy.tap()
        embassy.typeText("Example Embassy")

        let accounts = application.buttons["Accounts to include"]
        application.revealReferenceLetter(accounts)
        accounts.tap()
        let account = application.buttons["Tanda 360 - 2345 5678 2386"]
        XCTAssertTrue(account.waitForExistence(timeout: 5))
        account.tap()
        application.buttons["Select"].tap()
        waitUntilGone(sheet)

        let currency = application.buttons["Currency to display"]
        application.revealReferenceLetter(currency)
        currency.tap()
        application.buttons["IDR"].tap()
        waitUntilGone(sheet)

        let language = application.buttons["Letter language"]
        application.revealReferenceLetter(language)
        language.tap()
        application.buttons["Indonesia"].tap()
        waitUntilGone(sheet)

        let confirm = application.buttons["Confirm"]
        application.revealReferenceLetter(confirm)
        confirm.tap()
        XCTAssertTrue(application.buttons["pin.digit.1"].waitForExistence(timeout: 5))
        return sheet
    }

    func enter(_ digits: String) {
        for digit in digits {
            application.buttons["pin.digit.\(digit)"].tap()
        }
    }

    func waitUntilGone(_ element: XCUIElement) {
        let gone = expectation(for: NSPredicate(format: "exists == false"), evaluatedWith: element)
        wait(for: [gone], timeout: 5)
    }

    func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: application.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
