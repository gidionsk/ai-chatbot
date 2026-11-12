//
//  BottomSheetUITests.swift
//  TanyaAISandboxUITests
//
//  Created by Wendra on 12/11/26.
//

import XCTest

/// `--sheet-demo`: bottom sheet contoh di atas halaman Tanya AI. Sheet menempel di bawah, setinggi isinya, menutupi
/// header dengan latar gelap, dan menutup lewat ketuk di luar, geser ke bawah, atau pilihan di dalamnya.
/// `--with-history` membuat tombol contoh langsung tampak di ujung daftar. Swipe-back ditahan host selama sheet
/// terbuka.
final class BottomSheetUITests: XCTestCase {
    private let application = XCUIApplication()

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    /// Isi sheet berhenti di atas safe area bawah. Kartu composer juga berhenti padding 16 di atas safe area, jadi
    /// tepi bawahnya menjadi patokan yang benar untuk perangkat dengan maupun tanpa home indicator.
    func testSheetSitsAtTheBottomAsTallAsItsContent() {
        launchDemo()
        let composer = application.otherElements["composer"].frame
        let sheet = openSheet()
        let screen = application.frame
        let options = application.buttons.matching(identifier: "sandbox.sheet.option")
        XCTAssertEqual(options.count, 4)
        XCTAssertGreaterThanOrEqual(sheet.frame.maxY, screen.maxY, "permukaan sheet sampai ke tepi bawah layar")
        XCTAssertEqual(options.element(boundBy: 3).frame.maxY, composer.maxY, accuracy: 1)
        XCTAssertEqual(sheet.frame.width, screen.width, accuracy: 1)
        XCTAssertGreaterThan(sheet.frame.minY, screen.midY, "empat baris contoh tidak sampai setengah layar")
        XCTAssertEqual(application.buttons["sheet.handle"].label, "Close sheet")
        capture("bottom-sheet-open")
    }

    /// Latar gelap menutupi header juga: ketukan di posisi tombol kembali menutup sheet, bukan keluar dari halaman.
    func testTappingOutsideClosesTheSheetEvenOverTheHeader() {
        launchDemo()
        let sheet = openSheet()
        application.buttons["header.back"].coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        waitUntilGone(sheet)
        XCTAssertTrue(application.buttons["sandbox.sheet.open"].exists, "halaman Tanya AI masih terbuka")
    }

    func testDraggingDownClosesTheSheetAndAShortDragDoesNot() {
        launchDemo()
        let sheet = openSheet()
        let handle = application.buttons["sheet.handle"].coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        // Ditahan sebelum dilepas supaya tidak terhitung sentakan: sentakan ke bawah memang menutup.
        handle.press(
            forDuration: 0.1,
            thenDragTo: handle.withOffset(CGVector(dx: 0, dy: 20)),
            withVelocity: .slow,
            thenHoldForDuration: 0.5
        )
        XCTAssertTrue(sheet.exists, "geseran pendek mengembalikan sheet")
        handle.press(forDuration: 0.1, thenDragTo: handle.withOffset(CGVector(dx: 0, dy: 240)))
        waitUntilGone(sheet)
    }

    func testChoosingAnOptionClosesTheSheet() {
        launchDemo()
        let sheet = openSheet()
        application.buttons.matching(identifier: "sandbox.sheet.option").firstMatch.tap()
        waitUntilGone(sheet)
    }

    /// `--sheet-max --sheet-long`: batas 60% layar dan 20 baris yang lebih panjang dari itu. Sheet berhenti di batas,
    /// isinya di-scroll tanpa menutup sheet dan tanpa mengubah tinggi. Seperti scroll view bawaan, isi boleh lewat di
    /// bawah home indicator saat digeser, tetapi di ujung scroll baris terakhir berhenti di atas safe area (patokan:
    /// tepi bawah kartu composer). Geser grabber ke bawah tetap menutup.
    func testAMaxHeightStopsLongContentThereAndScrolls() {
        launchDemo(extra: ["--sheet-max", "--sheet-long"])
        let composer = application.otherElements["composer"].frame
        let sheet = openSheet()
        let screen = application.frame
        XCTAssertEqual(screen.maxY - sheet.frame.minY, screen.height * 0.6, accuracy: 1)
        let last = application.buttons.matching(identifier: "sandbox.sheet.option").element(boundBy: 19)
        XCTAssertFalse(last.isHittable, "baris terakhir di luar sheet sebelum di-scroll")
        scrollToTheEnd(of: sheet, until: last)
        XCTAssertTrue(sheet.exists, "scroll tidak menutup sheet")
        XCTAssertEqual(screen.maxY - sheet.frame.minY, screen.height * 0.6, accuracy: 1, "tinggi tidak berubah")
        XCTAssertEqual(last.frame.maxY, composer.maxY, accuracy: 1, "baris terakhir berhenti di atas safe area")
        dragHandleDown()
        waitUntilGone(sheet)
    }

    /// `--sheet-max` dengan 4 baris: batas tidak membesarkan sheet, jadi tetap setinggi isinya.
    func testAMaxHeightKeepsShortContentSmall() {
        launchDemo(extra: ["--sheet-max"])
        let composer = application.otherElements["composer"].frame
        let sheet = openSheet()
        let screen = application.frame
        let options = application.buttons.matching(identifier: "sandbox.sheet.option")
        XCTAssertEqual(options.count, 4)
        XCTAssertLessThan(screen.maxY - sheet.frame.minY, screen.height * 0.6, "lebih kecil dari batas")
        XCTAssertEqual(options.element(boundBy: 3).frame.maxY, composer.maxY, accuracy: 1)
    }

    /// `--sheet-long` tanpa batas: 20 baris lebih panjang dari layar. Sheet berhenti tepat di bawah status bar (tidak
    /// layar penuh, masih di dalam area header), isinya di-scroll, dan grabber tetap menutup.
    func testLongContentWithoutAMaxStopsBelowTheStatusBarAndScrolls() {
        launchDemo(extra: ["--sheet-long"])
        let composer = application.otherElements["composer"].frame
        let back = application.buttons["header.back"].frame
        let sheet = openSheet()
        XCTAssertGreaterThan(sheet.frame.minY, application.frame.minY, "tidak layar penuh")
        XCTAssertLessThanOrEqual(sheet.frame.minY, back.maxY, "naik sampai area header, di bawah status bar")
        let last = application.buttons.matching(identifier: "sandbox.sheet.option").element(boundBy: 19)
        XCTAssertFalse(last.isHittable)
        scrollToTheEnd(of: sheet, until: last)
        XCTAssertTrue(sheet.exists, "scroll tidak menutup sheet")
        XCTAssertEqual(last.frame.maxY, composer.maxY, accuracy: 1, "baris terakhir berhenti di atas safe area")
        dragHandleDown()
        waitUntilGone(sheet)
    }

    /// Selama sheet terbuka, swipe dari tepi kiri tidak keluar dari halaman; setelah ditutup, swipe-back jalan lagi.
    func testSwipeBackIsHeldWhileTheSheetIsOpen() {
        launchDemo()
        let sheet = openSheet()
        swipeFromLeadingEdge()
        XCTAssertFalse(application.buttons["sandbox.open"].waitForExistence(timeout: 2), "masih di Tanya AI")
        XCTAssertTrue(sheet.exists)
        application.buttons.matching(identifier: "sandbox.sheet.option").firstMatch.tap()
        waitUntilGone(sheet)
        swipeFromLeadingEdge()
        XCTAssertTrue(application.buttons["sandbox.open"].waitForExistence(timeout: 5), "kembali ke halaman host")
    }
}

// MARK: - Helpers

private extension BottomSheetUITests {
    func launchDemo(extra: [String] = []) {
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

    /// Digeser dari tengah isi sheet, bukan dari baris tertentu yang ikut keluar layar setelah geseran pertama. Satu
    /// geseran lagi setelah `row` terlihat memastikan scroll sudah di ujung.
    func scrollToTheEnd(of sheet: XCUIElement, until row: XCUIElement) {
        let lower = sheet.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.85))
        let upper = sheet.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.25))
        for _ in 0..<6 where !row.isHittable {
            lower.press(forDuration: 0.05, thenDragTo: upper)
        }
        lower.press(forDuration: 0.05, thenDragTo: upper)
        XCTAssertTrue(row.isHittable, "isi bisa di-scroll sampai baris terakhir")
    }

    func dragHandleDown() {
        let handle = application.buttons["sheet.handle"].coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        handle.press(forDuration: 0.1, thenDragTo: handle.withOffset(CGVector(dx: 0, dy: 300)))
    }

    /// Sama dengan `StartingPointUITests`: geseran cepat dari tepi kiri sampai hampir ke kanan.
    func swipeFromLeadingEdge() {
        let edge = application.coordinate(withNormalizedOffset: CGVector(dx: 0.005, dy: 0.5))
        edge.press(
            forDuration: 0.05,
            thenDragTo: application.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)),
            withVelocity: .fast,
            thenHoldForDuration: 0
        )
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
