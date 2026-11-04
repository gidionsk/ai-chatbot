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

    /// Bubble pertanyaan langsung menggantikan sambutan dan tombol langsung stop. Selama stop nasabah boleh
    /// mengetik pertanyaan berikutnya, tetapi harus menekan stop dulu untuk mengirimnya.
    func testShortcutShowsTheQuestionAndStopAtOnceThenStopUnlocksSend() {
        launch(locale: "en", extra: ["--hold-reply"])
        let shortcut = application.buttons["welcome.shortcut.0"]
        XCTAssertTrue(shortcut.waitForExistence(timeout: 10))
        let send = application.buttons["composer.send"]
        XCTAssertEqual(send.label, "Send message")
        shortcut.tap()
        XCTAssertTrue(application.descendants(matching: .any)["chat.question"].waitForExistence(timeout: 2))
        XCTAssertFalse(application.otherElements["chat.welcome"].exists)
        XCTAssertEqual(send.label, "Stop response")
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

    /// Gateway menolak kirim: bubble tetap tampil abu-abu dengan hint, tanpa retry, dan kirim terbuka lagi.
    func testRejectedSendLeavesAFailedBubble() {
        launch(locale: "en", extra: ["--reject-send"])
        let input = application.textViews["composer.input"]
        XCTAssertTrue(input.waitForExistence(timeout: 10))
        input.tap()
        input.typeText("Buy USD")
        let send = application.buttons["composer.send"]
        send.tap()
        let failed = application.descendants(matching: .any)["chat.question.failed"]
        XCTAssertTrue(failed.waitForExistence(timeout: 5))
        XCTAssertTrue(failed.label.contains("Buy USD"))
        XCTAssertTrue(failed.label.contains("This message failed to send"))
        XCTAssertEqual(input.value as? String, "")
        waitForLabel("Send message", of: send)
        capture("chat-failed-question")
    }

    /// History tidak kosong: loading awal selesai tanpa sambutan; chip tanggal di atas pesan pertama tiap hari.
    func testHistoryHidesTheWelcomeAndShowsADateChipPerDay() {
        launch(locale: "id", extra: ["--with-history"])
        XCTAssertTrue(application.textViews["composer.input"].waitForExistence(timeout: 10))
        waitUntilGone(application.descendants(matching: .any)["chat.loading"])
        XCTAssertFalse(application.buttons["welcome.shortcut.0"].exists)
        let chips = application.staticTexts.matching(identifier: "chat.date")
        XCTAssertTrue(chips.firstMatch.waitForExistence(timeout: 5))
        XCTAssertEqual(chips.allElementsBoundByIndex.map(\.label), ["14 Okt 2026", "15 Okt 2026"])
        XCTAssertEqual(application.descendants(matching: .any).matching(identifier: "chat.answer").count, 2)
        capture("chat-history-without-welcome")
    }

    /// Saran lanjutan di bawah jawaban terakhir; diketuk = terkirim sebagai pertanyaan dan saran hilang.
    func testFollowUpBecomesAQuestion() {
        launch(locale: "id", extra: ["--with-history"])
        let followUp = application.buttons["chat.followUp.0"]
        XCTAssertTrue(followUp.waitForExistence(timeout: 10))
        XCTAssertTrue(application.buttons["chat.followUp.1"].exists)
        capture("chat-follow-ups")
        followUp.tap()
        waitUntilGone(followUp)
        let question = application.staticTexts["Bandingkan dengan pasar"]
        XCTAssertTrue(question.waitForExistence(timeout: 5))
    }

    /// Jawaban bot Markdown: link tidak dibuka sendiri, tetapi diteruskan ke host (sandbox menampilkan URL-nya).
    func testAnswerLinkIsHandedToTheHost() {
        launch(locale: "id", extra: ["--with-history"])
        let link = application.links["halaman kurs"]
        XCTAssertTrue(link.waitForExistence(timeout: 10))
        capture("chat-markdown-answers")
        link.tap()
        let alert = application.alerts["Link diteruskan ke host"]
        XCTAssertTrue(alert.waitForExistence(timeout: 5))
        XCTAssertTrue(alert.staticTexts["https://www.ocbc.id/id/kurs"].exists)
        alert.buttons["Tutup"].tap()
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

    /// Salinan pertanyaan dari stream menggantikan bubble lokal tanpa berkedip, lalu `turn_end` membuka kirim lagi.
    /// Chip tanggal hari ini tampil sekali, dari waktu kirim lalu dari `created_at` salinan stream.
    func testTurnEndFromTheStreamUnlocksSend() {
        launch(locale: "en")
        let shortcut = application.buttons["welcome.shortcut.0"]
        XCTAssertTrue(shortcut.waitForExistence(timeout: 10))
        shortcut.tap()
        let send = application.buttons["composer.send"]
        waitForLabel("Stop response", of: send)
        waitUntilGone(application.otherElements["chat.welcome"])
        waitForLabel("Send message", of: send)
        XCTAssertEqual(application.descendants(matching: .any).matching(identifier: "chat.question").count, 1)
        XCTAssertEqual(application.staticTexts.matching(identifier: "chat.date").count, 1)
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
