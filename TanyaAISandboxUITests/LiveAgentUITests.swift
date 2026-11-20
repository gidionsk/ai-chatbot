//
//  LiveAgentUITests.swift
//  TanyaAISandboxUITests
//
//  Created by Wendra on 10/11/26.
//

import XCTest

/// `--live-agent`: bot menyerahkan ke agen, kartu antre dengan tombol batal di dalam kartu, sapaan otomatis mengubah
/// kartu menjadi "Connected" dengan indikator mencari agen, agen mengetik dan menjawab, lalu kartu sesi berakhir. Tidak
/// ada chip abu. Kirim ke agen tidak mengubah tombol menjadi stop. Tombol lampiran hanya selama agen melayani.
final class LiveAgentUITests: XCTestCase {
    private let application = XCUIApplication()

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    func testHandoverQueuesJoinsAnswersAndEnds() {
        launchAndAskForAnAgent()
        XCTAssertTrue(notice("Switching to Live Chat with Human").waitForExistence(timeout: 5))
        let leave = application.buttons["chat.agent.leaveQueue"]
        XCTAssertTrue(leave.exists)
        XCTAssertTrue(notice("Switching to Live Chat with Human").frame.contains(leave.frame), "batal di dalam kartu")
        capture("live-agent-queued")
        XCTAssertFalse(application.buttons["composer.attachment"].exists, "belum ada agen")
        XCTAssertTrue(element("chat.agent.searching").waitForExistence(timeout: 5))
        XCTAssertTrue(notice("Connected to Customer Assistant").exists, "sapaan otomatis mengubah kartu antre")
        XCTAssertFalse(application.buttons["chat.agent.leaveQueue"].exists, "batal hanya sebelum sapaan otomatis")
        capture("live-agent-searching")
        XCTAssertTrue(element("chat.agent.typing").waitForExistence(timeout: 8))
        XCTAssertFalse(element("chat.agent.searching").exists, "indikator mengetik didahulukan")
        capture("live-agent-typing")
        waitUntilGone(element("chat.agent.typing"))
        XCTAssertFalse(element("chat.agent.searching").exists, "agen sudah bergabung")
        XCTAssertTrue(notice("Connected to Customer Assistant").exists, "kartu terhubung tetap sebagai riwayat")
        XCTAssertFalse(application.staticTexts["Session with Tanya OCBC Customer Assistant started"].exists)
        XCTAssertTrue(element("chat.agent.session").exists, "bar sesi agen selama dilayani")
        assertAttachmentLinesUpWithSend()
        capture("live-agent-active")
        send("Cek status kartu saya")
        XCTAssertEqual(application.buttons["composer.send"].label, "Send message", "agen tidak memakai stop")
        XCTAssertTrue(notice("Customer Assistant Mode Ended").waitForExistence(timeout: 10))
        XCTAssertFalse(application.staticTexts["Session with Tanya OCBC Customer Assistant ended"].exists)
        capture("live-agent-ended")
        XCTAssertFalse(application.buttons["composer.attachment"].exists, "agen sudah selesai")
        XCTAssertFalse(element("chat.agent.session").exists, "bar hilang setelah sesi berakhir")
    }

    /// End Session di bar bawah header memanggil `leave-agent`: sesi berakhir tanpa menunggu agen menutupnya.
    func testEndSessionLeavesTheAgent() {
        launchAndAskForAnAgent()
        let banner = element("chat.agent.session")
        XCTAssertTrue(banner.waitForExistence(timeout: 15))
        let title = application.staticTexts["Tanya AI"].firstMatch
        XCTAssertGreaterThanOrEqual(banner.frame.minY, title.frame.maxY, "di bawah header")
        capture("live-agent-session-banner")
        banner.buttons["End Session"].tap()
        XCTAssertTrue(notice("Customer Assistant Mode Ended").waitForExistence(timeout: 5))
        XCTAssertFalse(banner.exists)
        XCTAssertFalse(application.buttons["composer.attachment"].exists, "agen sudah selesai")
    }

    /// Sheet lampiran yang masih terbuka ikut tertutup saat agen mengakhiri sesi, jadi Galeri tidak bisa diketuk lagi.
    func testAttachmentSheetClosesWhenTheAgentEndsTheSession() {
        launchAndAskForAnAgent()
        // Sapaan otomatis sudah datang selama antre; penutupan sesi baru dijadwalkan untuk pesan saat agen bergabung,
        // yaitu saat tombol lampiran muncul.
        let attachment = application.buttons["composer.attachment"]
        XCTAssertTrue(attachment.waitForExistence(timeout: 15))
        send("Cek status kartu saya")
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
        XCTAssertTrue(notice("Agent Request Canceled").waitForExistence(timeout: 5))
        capture("live-agent-canceled")
        // Sapaan otomatis dan agen yang dijadwalkan tidak pernah datang.
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

    /// Kartu live agent dengan judul tertentu; kartu lain (mis. "Connected") bisa tampil bersamaan. Teks kartu satu
    /// elemen di dalam kartu, jadi tombol batal tetap elemen sendiri.
    func notice(_ title: String) -> XCUIElement {
        application.descendants(matching: .any).matching(identifier: "chat.agent.notice")
            .containing(NSPredicate(format: "label CONTAINS %@", title)).firstMatch
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
