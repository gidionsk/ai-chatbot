//
//  WelcomeUITests.swift
//  TanyaAISandboxUITests
//
//  Created by Wendra on 27/10/26.
//

import XCTest

final class WelcomeUITests: XCTestCase {
    private let application = XCUIApplication()

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    func testWelcomeShowsBackendGreetingAndShortcutsInOrder() {
        launch(locale: "id")
        XCTAssertTrue(application.staticTexts["Hi, Lara Croft!"].waitForExistence(timeout: 10))
        XCTAssertTrue(application.staticTexts["Mulai dari sini:"].exists)
        let shortcuts = (0..<3).map { application.buttons["welcome.shortcut.\($0)"] }
        XCTAssertTrue(shortcuts.allSatisfy(\.exists))
        XCTAssertTrue(shortcuts[0].label.contains("Cek Portfolio"))
        XCTAssertTrue(shortcuts[2].label.contains("Ajukan Surat Referensi"))
        XCTAssertLessThan(shortcuts[0].frame.maxY, shortcuts[1].frame.minY)
        XCTAssertLessThan(shortcuts[1].frame.maxY, shortcuts[2].frame.minY)
        XCTAssertFalse(application.buttons["header.scrolled"].exists)
        capture("welcome-id")
    }

    /// Titik bergerak sampai pertanyaan datang dari stream (sambutan hilang), lalu stop. Selama stop nasabah
    /// boleh mengetik pertanyaan berikutnya, tetapi harus menekan stop dulu untuk mengirimnya.
    func testShortcutShowsLoadingUntilTheQuestionThenStopUnlocksSend() {
        launch(locale: "en", extra: ["--hold-reply"])
        let shortcut = application.buttons["welcome.shortcut.0"]
        XCTAssertTrue(shortcut.waitForExistence(timeout: 10))
        let send = application.buttons["composer.send"]
        XCTAssertEqual(send.label, "Send message")
        shortcut.tap()
        waitForLabel("Stop response", of: send)
        waitUntilGone(application.otherElements["chat.welcome"])
        XCTAssertTrue(send.isEnabled)
        let input = application.textViews["composer.input"]
        input.tap()
        input.typeText("Next question")
        XCTAssertEqual(input.value as? String, "Next question")
        capture("composer-stop")
        send.tap()
        waitForLabel("Send message", of: send)
        XCTAssertTrue(send.isEnabled, "setelah stop, draft yang sudah diketik bisa dikirim")
        XCTAssertEqual(input.value as? String, "Next question")
    }

    /// History tidak kosong: loading awal selesai tanpa sambutan (daftar pesan menyusul di PR tampilan pesan).
    func testHistoryHidesTheWelcome() {
        launch(locale: "id", extra: ["--with-history"])
        XCTAssertTrue(application.textViews["composer.input"].waitForExistence(timeout: 10))
        waitUntilGone(application.descendants(matching: .any)["chat.loading"])
        XCTAssertFalse(application.buttons["welcome.shortcut.0"].exists)
        capture("chat-history-without-welcome")
    }

    /// Ikon gagal diunduh: kartu tetap tampil dengan ikon fallback FE dan tetap bisa diketuk.
    func testBrokenIconsKeepShortcutsTappable() {
        launch(locale: "id", extra: ["--broken-icons", "--hold-reply"])
        let shortcut = application.buttons["welcome.shortcut.1"]
        XCTAssertTrue(shortcut.waitForExistence(timeout: 10))
        XCTAssertTrue(shortcut.label.contains("Beli Valas"))
        capture("welcome-broken-icons")
        shortcut.tap()
        waitForLabel("Hentikan jawaban", of: application.buttons["composer.send"])
    }

    /// Ikon belum selesai diunduh: kotak ikon menampilkan spinner, kartu sudah bisa diketuk.
    func testLoadingIconsKeepShortcutsTappable() {
        launch(locale: "id", extra: ["--slow-icons", "--hold-reply"])
        let shortcut = application.buttons["welcome.shortcut.0"]
        XCTAssertTrue(shortcut.waitForExistence(timeout: 10))
        XCTAssertTrue(application.activityIndicators.firstMatch.waitForExistence(timeout: 5))
        capture("welcome-loading-icons")
        shortcut.tap()
        waitForLabel("Hentikan jawaban", of: application.buttons["composer.send"])
    }

    /// Pertanyaan datang dari stream (sambutan hilang), lalu jawaban bot dan `turn_end` membuka kirim lagi.
    func testTurnEndFromTheStreamUnlocksSend() {
        launch(locale: "en")
        let shortcut = application.buttons["welcome.shortcut.0"]
        XCTAssertTrue(shortcut.waitForExistence(timeout: 10))
        shortcut.tap()
        let send = application.buttons["composer.send"]
        waitForLabel("Stop response", of: send)
        waitUntilGone(application.otherElements["chat.welcome"])
        waitForLabel("Send message", of: send)
    }

    private func launch(locale: String, extra: [String] = []) {
        application.launchArguments = ["--language", locale] + extra
        application.launch()
        let open = application.buttons["sandbox.open"]
        XCTAssertTrue(open.waitForExistence(timeout: 10))
        open.tap()
    }

    private func waitForLabel(_ label: String, of element: XCUIElement) {
        let matched = expectation(for: NSPredicate(format: "label == %@", label), evaluatedWith: element)
        wait(for: [matched], timeout: 5)
    }

    private func waitUntilGone(_ element: XCUIElement) {
        let gone = expectation(for: NSPredicate(format: "exists == false"), evaluatedWith: element)
        wait(for: [gone], timeout: 5)
    }

    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: application.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
