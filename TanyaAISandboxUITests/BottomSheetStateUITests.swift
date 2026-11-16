//
//  BottomSheetStateUITests.swift
//  TanyaAISandboxUITests
//
//  Created by Wendra on 14/11/26.
//

import XCTest

/// `--sheet-demo` dengan keadaan khusus wadah: tombol pilihan banyak menempel di bawah sheet, sheet terkunci hanya
/// ditutup isinya, dan sheet naik ke atas keyboard yang dibuka field di dalamnya.
final class BottomSheetStateUITests: XCTestCase {
    private let application = XCUIApplication()

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    /// `--sheet-long --sheet-multi`: tombol konfirmasi sudah terlihat sebelum daftar digeser, tidak berpindah selama
    /// daftar di-scroll, dan baris terakhir berhenti di atasnya. Tepi bawah tombol sejajar tepi bawah kartu composer
    /// (padding 16 di atas safe area).
    func testTheConfirmButtonSticksToTheBottomWhileTheListScrolls() {
        launchDemo(extra: ["--sheet-long", "--sheet-multi"])
        let composer = application.otherElements["composer"].frame
        let sheet = openSheet()
        let choose = application.buttons["Choose"]
        let last = optionButtons.element(boundBy: 19)
        XCTAssertTrue(choose.isHittable, "tombol terlihat tanpa menggeser daftar")
        XCTAssertFalse(choose.isEnabled, "belum ada centang")
        XCTAssertFalse(last.isHittable)
        let pinned = choose.frame
        XCTAssertEqual(pinned.maxY, composer.maxY, accuracy: 1)
        capture("bottom-sheet-pinned-button")
        scrollToTheEnd(of: sheet, until: last)
        XCTAssertEqual(choose.frame.minY, pinned.minY, accuracy: 1, "tombol tidak ikut ter-scroll")
        XCTAssertLessThanOrEqual(last.frame.maxY, choose.frame.minY + 1, "baris terakhir berhenti di atas tombol")
        last.tap()
        XCTAssertTrue(sheet.exists, "pilihan banyak menunggu tombol")
        choose.tap()
        waitUntilGone(sheet)
    }

    /// `--sheet-locked`: ketuk di luar dan geser dari grabber tidak menutup, dan VoiceOver tidak mendapat tombol
    /// tutup. Hanya pemakai yang menutup, di sini lewat pilihan.
    func testALockedSheetOnlyClosesFromItsContent() {
        launchDemo(extra: ["--sheet-locked"])
        let sheet = openSheet()
        application.buttons["header.back"].coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        let grabber = sheet.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0)).withOffset(
            CGVector(dx: 0, dy: 12))
        grabber.press(forDuration: 0.1, thenDragTo: grabber.withOffset(CGVector(dx: 0, dy: 300)))
        let top = sheet.frame.minY
        XCTAssertFalse(application.buttons["sandbox.open"].waitForExistence(timeout: 1), "masih di Tanya AI")
        XCTAssertTrue(sheet.exists, "ketuk di luar dan geseran tidak menutup")
        XCTAssertEqual(sheet.frame.minY, top, accuracy: 1)
        XCTAssertFalse(application.buttons["sheet.handle"].exists, "tanpa tombol tutup")
        optionButtons.firstMatch.tap()
        waitUntilGone(sheet)
    }

    /// `--sheet-input`: field di dalam sheet membuka keyboard; sheet naik sehingga seluruh isinya di atas keyboard,
    /// dan turun lagi setelah ditutup lewat pilihan.
    func testTheSheetRisesAboveTheKeyboard() {
        launchDemo(extra: ["--sheet-input"])
        let sheet = openSheet()
        let field = application.textFields["sandbox.sheet.input"]
        let last = optionButtons.element(boundBy: 3)
        let resting = last.frame.maxY
        field.tap()
        let keyboard = application.keyboards.firstMatch
        XCTAssertTrue(keyboard.waitForExistence(timeout: 5))
        field.typeText("Note")
        XCTAssertLessThan(last.frame.maxY, resting, "sheet naik")
        XCTAssertLessThanOrEqual(last.frame.maxY, keyboard.frame.minY + 1, "baris terakhir di atas keyboard")
        XCTAssertTrue(field.isHittable)
        XCTAssertGreaterThan(sheet.frame.minY, application.frame.minY)
        capture("bottom-sheet-keyboard")
        last.tap()
        waitUntilGone(sheet)
        waitUntilGone(keyboard)
    }
}

// MARK: - Helpers

private extension BottomSheetStateUITests {
    func launchDemo(extra: [String]) {
        application.launchArguments = ["--language", "en", "--sheet-demo", "--with-history"] + extra
        application.launch()
        let entry = application.buttons["sandbox.open"]
        XCTAssertTrue(entry.waitForExistence(timeout: 10))
        entry.tap()
    }

    func openSheet() -> XCUIElement {
        let open = application.buttons["sandbox.sheet.open"]
        XCTAssertTrue(open.waitForExistence(timeout: 10))
        open.tap()
        // Sheet membawa trait modal, jadi XCUITest melaporkannya sebagai alert, bukan elemen biasa.
        let sheet = application.descendants(matching: .any)["sheet"]
        XCTAssertTrue(sheet.waitForExistence(timeout: 5))
        return sheet
    }

    /// Digeser dari bagian daftar, di atas tombol yang menempel: geseran yang mulai dari tombol tidak menggulir. Satu
    /// geseran lagi setelah `row` terlihat memastikan scroll sudah di ujung.
    func scrollToTheEnd(of sheet: XCUIElement, until row: XCUIElement) {
        let lower = sheet.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.7))
        let upper = sheet.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2))
        for _ in 0..<6 where !row.isHittable {
            lower.press(forDuration: 0.05, thenDragTo: upper)
        }
        lower.press(forDuration: 0.05, thenDragTo: upper)
        XCTAssertTrue(row.isHittable, "isi bisa di-scroll sampai baris terakhir")
    }

    /// Baris contoh di `OptionList`, dikenali dari teksnya.
    var optionButtons: XCUIElementQuery {
        application.buttons.matching(NSPredicate(format: "label == %@", "Sample option"))
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
