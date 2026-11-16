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
        XCTAssertEqual(application.buttons["pin.delete"].label, "Delete")
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

    func testTheAcceptedPinClosesTheSheet() {
        let sheet = openPinSheet()
        enter("123456")
        waitUntilGone(sheet)
        XCTAssertTrue(application.staticTexts["sandbox.form.submitted"].exists)
    }
}

// MARK: - Helpers

private extension PinEntryUITests {
    var dots: XCUIElement { application.descendants(matching: .any)["pin.dots"] }

    /// Format softcopy (email tersimpan) dan satu rekening, lalu Konfirmasi.
    @discardableResult
    func openPinSheet() -> XCUIElement {
        application.launchArguments = ["--language", "en", "--form-demo", "--with-history"]
        application.launch()
        let entry = application.buttons["sandbox.open"]
        XCTAssertTrue(entry.waitForExistence(timeout: 10))
        entry.tap()
        let sheet = application.descendants(matching: .any)["sheet"]
        application.buttons["sandbox.form.format"].tap()
        application.buttons["Softcopy"].tap()
        waitUntilGone(sheet)
        application.buttons["sandbox.form.accounts"].tap()
        let account = application.buttons["Tanda 360 - 5262 8191 2892 82"]
        XCTAssertTrue(account.waitForExistence(timeout: 5))
        account.tap()
        application.buttons["Choose"].tap()
        waitUntilGone(sheet)
        application.buttons["sandbox.form.confirm"].tap()
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
