//
//  FormFieldsUITests.swift
//  TanyaAISandboxUITests
//
//  Created by Wendra on 12/11/26.
//

import XCTest

/// `--form-demo`: field pilihan membuka daftar di bottom sheet, pilihan menentukan field berikutnya, rekening boleh
/// lebih dari satu dan daftarnya dimuat dulu, field nonaktif tidak bisa diubah, Konfirmasi menandai field kosong
/// sambil membuka sheet pilihan kosong paling atas, dan Batalkan mengosongkan form.
final class FormFieldsUITests: XCTestCase {
    private let application = XCUIApplication()

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    func testAFormatChoiceSwapsTheDependentField() {
        launchDemo()
        let email = application.textFields["sandbox.form.email"]
        XCTAssertTrue(email.waitForExistence(timeout: 10))
        XCTAssertFalse(email.isEnabled, "email tersimpan tidak bisa diubah")
        application.buttons["sandbox.form.format"].tap()
        let sheet = sheetElement
        XCTAssertTrue(sheet.waitForExistence(timeout: 5))
        application.buttons["Hardcopy"].tap()
        waitUntilGone(sheet)
        XCTAssertEqual(application.buttons["sandbox.form.format"].value as? String, "Hardcopy")
        XCTAssertTrue(application.textFields["sandbox.form.address"].waitForExistence(timeout: 3))
        XCTAssertFalse(email.exists, "softcopy diganti hardcopy: email tidak tampil")
    }

    func testAccountsLoadFirstThenAllowSeveral() {
        launchDemo()
        application.buttons["sandbox.form.accounts"].tap()
        XCTAssertTrue(sheetElement.waitForExistence(timeout: 5))
        XCTAssertTrue(sheetElement.activityIndicators.firstMatch.exists, "daftar masih dimuat")
        let first = application.buttons["Tanda 360 - 5262 8191 2892 82"]
        XCTAssertTrue(first.waitForExistence(timeout: 5))
        first.tap()
        application.buttons["Giro Bisnis - 7781 2003 4551 9"].tap()
        XCTAssertTrue(sheetElement.exists, "pilihan banyak menunggu tombol Pilih")
        application.buttons["Choose"].tap()
        waitUntilGone(sheetElement)
        XCTAssertEqual(application.buttons["sandbox.form.accounts"].value as? String, "2 accounts selected")
    }

    func testAccountOptionsExposeTitleAndBalanceForAccessibility() {
        launchDemo()
        application.buttons["sandbox.form.accounts"].tap()
        let account = application.buttons["Tanda 360 - 5262 8191 2892 82"]
        XCTAssertTrue(account.waitForExistence(timeout: 5))
        XCTAssertEqual(account.label, "Tanda 360 - 5262 8191 2892 82")
        XCTAssertEqual(account.value as? String, "IDR 1.000.000")
        let plain = application.buttons["Giro Bisnis - 7781 2003 4551 9"]
        XCTAssertTrue(plain.exists)
        XCTAssertEqual(plain.label, "Giro Bisnis - 7781 2003 4551 9")
        XCTAssertTrue((plain.value as? String)?.isEmpty ?? true)
    }

    func testConfirmMarksEmptyFieldsAndOpensTheTopmostEmptyChoice() {
        launchDemo()
        let confirm = application.buttons["sandbox.form.confirm"]
        XCTAssertTrue(confirm.waitForExistence(timeout: 10))
        confirm.tap()
        XCTAssertTrue(sheetElement.waitForExistence(timeout: 5))
        XCTAssertTrue(application.buttons["Hardcopy"].exists, "sheet format, field pilihan kosong paling atas")
        application.buttons["Hardcopy"].tap()
        waitUntilGone(sheetElement)
        XCTAssertTrue(application.staticTexts["Please choose one"].exists, "rekening masih kosong")
        confirm.tap()
        let first = application.buttons["Tanda 360 - 5262 8191 2892 82"]
        XCTAssertTrue(first.waitForExistence(timeout: 5), "sheet rekening, kini pilihan kosong paling atas")
        first.tap()
        application.buttons["Choose"].tap()
        waitUntilGone(sheetElement)
        XCTAssertTrue(application.staticTexts["Please fill this in"].exists, "alamat masih kosong")
        let address = application.textFields["sandbox.form.address"]
        address.tap()
        address.typeText("Jl. Sudirman 1")
        waitUntilGone(application.staticTexts["Please fill this in"])
    }

    func testCancelEmptiesTheForm() {
        launchDemo()
        let format = application.buttons["sandbox.form.format"]
        application.buttons["sandbox.form.confirm"].tap()
        XCTAssertTrue(application.buttons["Hardcopy"].waitForExistence(timeout: 5))
        application.buttons["Hardcopy"].tap()
        waitUntilGone(sheetElement)
        XCTAssertEqual(format.value as? String, "Hardcopy")
        application.buttons["sandbox.form.cancel"].tap()
        XCTAssertNotEqual(format.value as? String, "Hardcopy", "pilihan dikosongkan")
        XCTAssertFalse(application.staticTexts["Please choose one"].exists, "tanda wajib ikut hilang")
        XCTAssertTrue(application.textFields["sandbox.form.email"].exists, "field alamat kembali jadi email")
    }
}

// MARK: - Helpers

private extension FormFieldsUITests {
    /// Sheet membawa trait modal, jadi XCUITest melaporkannya sebagai alert, bukan elemen biasa.
    var sheetElement: XCUIElement { application.descendants(matching: .any)["sheet"] }

    func launchDemo() {
        application.launchArguments = ["--language", "en", "--form-demo", "--with-history"]
        application.launch()
        let entry = application.buttons["sandbox.open"]
        XCTAssertTrue(entry.waitForExistence(timeout: 10))
        entry.tap()
        XCTAssertTrue(application.buttons["sandbox.form.format"].waitForExistence(timeout: 10))
    }

    func waitUntilGone(_ element: XCUIElement) {
        let gone = expectation(for: NSPredicate(format: "exists == false"), evaluatedWith: element)
        wait(for: [gone], timeout: 5)
    }
}
