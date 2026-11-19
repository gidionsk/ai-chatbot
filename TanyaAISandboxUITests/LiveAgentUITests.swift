//
//  LiveAgentUITests.swift
//  TanyaAISandboxUITests
//
//  Created by Wendra on 10/11/26.
//

import XCTest

/// `--live-agent`: bot menyerahkan ke agen, kartu antre dengan tombol batal, chip sesi dimulai, agen mengetik dan
/// menjawab, lalu chip sesi berakhir dengan kartunya. Kirim ke agen tidak mengubah tombol menjadi stop. Tombol
/// lampiran hanya selama agen melayani.
final class LiveAgentUITests: XCTestCase {
    private let application = XCUIApplication()

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    func testHandoverQueuesJoinsAnswersAndEnds() {
        launchAndAskForAnAgent()
        XCTAssertTrue(element("chat.agent.notice").waitForExistence(timeout: 5))
        capture("live-agent-queued")
        XCTAssertFalse(application.buttons["composer.attachment"].exists, "belum ada agen")
        XCTAssertTrue(element("chat.agent.typing").waitForExistence(timeout: 8))
        capture("live-agent-typing")
        XCTAssertTrue(element("chat.agent.message").waitForExistence(timeout: 5))
        waitUntilGone(element("chat.agent.typing"))
        XCTAssertFalse(application.buttons["chat.agent.leaveQueue"].exists, "kartu antre hilang saat agen bergabung")
        XCTAssertFalse(element("chat.agent.notice").exists)
        XCTAssertTrue(application.staticTexts["Session with Tanya OCBC Customer Assistant started"].exists)
        assertAttachmentLinesUpWithSend()
        capture("live-agent-active")
        send("Cek status kartu saya")
        XCTAssertEqual(application.buttons["composer.send"].label, "Send message", "agen tidak memakai stop")
        let ended = element("chat.agent.notice")
        XCTAssertTrue(ended.waitForExistence(timeout: 10))
        XCTAssertTrue(ended.label.contains("Customer Assistant Mode Ended"))
        XCTAssertTrue(application.staticTexts["Session with Tanya OCBC Customer Assistant ended"].exists)
        capture("live-agent-ended")
        XCTAssertFalse(application.buttons["composer.attachment"].exists, "agen sudah selesai")
    }

    /// Sheet lampiran yang masih terbuka ikut tertutup saat agen mengakhiri sesi, jadi Galeri tidak bisa diketuk lagi.
    func testAttachmentSheetClosesWhenTheAgentEndsTheSession() {
        launchAndAskForAnAgent()
        XCTAssertTrue(element("chat.agent.message").waitForExistence(timeout: 15))
        send("Cek status kartu saya")
        let attachment = application.buttons["composer.attachment"]
        XCTAssertTrue(attachment.waitForExistence(timeout: 5))
        attachment.tap()
        let sheet = element("sheet")
        XCTAssertTrue(sheet.waitForExistence(timeout: 3))
        XCTAssertTrue(sheet.staticTexts["Gallery"].exists)
        // Agen menutup sesi beberapa detik setelah menjawab (`--live-agent`); sheet tidak ditutup oleh test.
        let gone = expectation(for: NSPredicate(format: "exists == false"), evaluatedWith: sheet)
        wait(for: [gone], timeout: 12)
        XCTAssertTrue(element("chat.agent.notice").waitForExistence(timeout: 5))
        XCTAssertFalse(application.staticTexts["Gallery"].exists)
        XCTAssertFalse(attachment.exists, "agen sudah selesai")
    }

    func testLeavingTheQueueShowsTheCanceledCard() {
        launchAndAskForAnAgent()
        let leave = application.buttons["chat.agent.leaveQueue"]
        XCTAssertTrue(leave.waitForExistence(timeout: 5))
        // Daftar ikut ke bawah saat kartu antre muncul, jadi tombol batal tidak terpotong area composer.
        // Padding luar composer sama di semua sisi, jadi garis pemisah ada sejauh padding kirinya di atas kartu.
        let composer = application.otherElements["composer"].frame
        let listBottom = composer.minY - composer.minX - 1
        let isRevealed = NSPredicate { _, _ in leave.frame.maxY <= listBottom }
        wait(for: [expectation(for: isRevealed, evaluatedWith: nil)], timeout: 3)
        leave.tap()
        waitUntilGone(leave)
        let canceled = element("chat.agent.notice")
        XCTAssertTrue(canceled.waitForExistence(timeout: 5))
        XCTAssertTrue(canceled.label.contains("Agent Request Canceled"))
        capture("live-agent-canceled")
        // Agen yang dijadwalkan tidak pernah bergabung.
        XCTAssertFalse(element("chat.agent.message").waitForExistence(timeout: 5))
    }
}

// MARK: - Helpers

private extension LiveAgentUITests {
    func launchAndAskForAnAgent() {
        application.launchArguments = ["--language", "en", "--live-agent"]
        application.launch()
        let open = application.buttons["sandbox.open"]
        XCTAssertTrue(open.waitForExistence(timeout: 10))
        open.tap()
        send("Saya mau live agent")
    }

    func send(_ text: String) {
        let input = application.textViews["composer.input"]
        XCTAssertTrue(input.waitForExistence(timeout: 10))
        input.tap()
        input.typeText(text)
        application.buttons["composer.send"].tap()
    }

    /// Di dalam kartu composer sebelah kiri field, seukuran dan sejajar dengan tombol kirim. Diketuk = bottom sheet
    /// Galeri dan File (tanpa kamera), lalu ditutup lagi lewat latar gelap.
    func assertAttachmentLinesUpWithSend() {
        let attachment = application.buttons["composer.attachment"]
        XCTAssertTrue(attachment.waitForExistence(timeout: 5))
        let send = application.buttons["composer.send"].frame
        XCTAssertEqual(attachment.frame.midY, send.midY, accuracy: 0.5)
        XCTAssertEqual(attachment.frame.size, send.size)
        XCTAssertGreaterThan(attachment.frame.minX, application.otherElements["composer"].frame.minX)
        XCTAssertLessThan(attachment.frame.maxX, application.textViews["composer.input"].frame.minX)
        attachment.tap()
        let sheet = element("sheet")
        XCTAssertTrue(sheet.waitForExistence(timeout: 3))
        XCTAssertTrue(sheet.staticTexts["Gallery"].exists)
        XCTAssertTrue(sheet.staticTexts["PDF, HEIC, JPG, or PNG"].exists)
        capture("live-agent-attachment-sources")
        // Swipe-back dari tepi kiri ditahan host selama sheet terbuka: halaman chat tetap tampil.
        let leftEdge = application.coordinate(withNormalizedOffset: CGVector(dx: 0.01, dy: 0.5))
        leftEdge.press(
            forDuration: 0.1, thenDragTo: application.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)))
        XCTAssertTrue(application.buttons["composer.attachment"].exists, "masih di halaman chat")
        application.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.1)).tap()
        waitUntilGone(sheet)
    }

    func element(_ identifier: String) -> XCUIElement {
        application.descendants(matching: .any)[identifier].firstMatch
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
