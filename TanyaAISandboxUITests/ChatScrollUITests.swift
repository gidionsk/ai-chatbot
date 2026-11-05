//
//  ChatScrollUITests.swift
//  TanyaAISandboxUITests
//
//  Created by Wendra on 5/11/26.
//

import XCTest

/// Posisi scroll daftar pesan: buka di pesan terbaru, pertanyaan baru parkir di atas, dan pesan lain mengikuti.
final class ChatScrollUITests: XCTestCase {
    private let application = XCUIApplication()
    private let lastAnswer = "Jawaban terakhir history"
    private let lateMessage = "Pesan baru tanpa pertanyaan"

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    func testOpensAtTheLatestMessage() {
        launch(extra: ["--long-history"])
        let answer = text(lastAnswer)
        XCTAssertTrue(answer.waitForExistence(timeout: 10))
        XCTAssertTrue(isOnScreen(answer))
        XCTAssertTrue(header.exists)
    }

    func testNewQuestionParksBelowTheHeaderWithAPreviewOfThePreviousAnswer() {
        launch(extra: ["--long-history", "--hold-reply"])
        XCTAssertTrue(text(lastAnswer).waitForExistence(timeout: 10))
        send("Pertanyaan baru")
        assertParked("Pertanyaan baru")
        XCTAssertGreaterThan(text(lastAnswer).frame.maxY, headerBottom)
    }

    func testShortConversationStillParksTheQuestion() {
        launch(extra: ["--with-history", "--hold-reply"])
        XCTAssertTrue(application.buttons["composer.send"].waitForExistence(timeout: 10))
        send("Pertanyaan baru")
        assertParked("Pertanyaan baru")
    }

    /// Jawaban yang lebih panjang dari sisa layar tetap terbaca dari awal: pertanyaannya tidak ikut tergeser.
    func testAnswerArrivesBelowTheParkedQuestion() {
        launch(extra: ["--long-history"])
        XCTAssertTrue(text(lastAnswer).waitForExistence(timeout: 10))
        send("Pertanyaan baru")
        assertParked("Pertanyaan baru")
        XCTAssertTrue(waitForSendButton(label: "Send message"))
        XCTAssertTrue(text("Jawaban contoh").exists)
        assertParked("Pertanyaan baru")
    }

    /// Tanpa keyboard posisinya sudah di bawah; pertanyaan tetap parkir, bukan mengikuti ke ujung daftar.
    func testFollowUpParksTheQuestionWithoutAKeyboard() {
        launch(extra: ["--with-history", "--hold-reply"])
        let followUp = application.buttons["chat.followUp.0"]
        XCTAssertTrue(followUp.waitForExistence(timeout: 10))
        let question = followUp.label
        followUp.tap()
        assertParked(question)
    }

    func testMessageWithoutQuestionFollowsWhenAtTheBottom() {
        launch(extra: ["--long-history", "--late-message"])
        XCTAssertTrue(text(lastAnswer).waitForExistence(timeout: 10))
        let late = text(lateMessage)
        XCTAssertTrue(late.waitForExistence(timeout: 10))
        settle()
        XCTAssertTrue(isOnScreen(late))
    }

    func testMessageWithoutQuestionLeavesAReaderWhereTheyAre() {
        launch(extra: ["--long-history", "--late-message"])
        XCTAssertTrue(text(lastAnswer).waitForExistence(timeout: 10))
        application.scrollViews.firstMatch.swipeDown()
        settle()
        XCTAssertFalse(isOnScreen(text(lastAnswer)))
        RunLoop.current.run(until: Date().addingTimeInterval(4))
        XCTAssertFalse(isOnScreen(text(lastAnswer)))
        XCTAssertFalse(isOnScreen(text(lateMessage)))
    }

    private var header: XCUIElement {
        application.descendants(matching: .any)["header.scrolled"]
    }

    private var headerBottom: CGFloat { header.frame.maxY }

    /// Tinggi gradient di bawah header sama dengan padding bawah header, 16 yang di-scale.
    private var solidHeaderBottom: CGFloat {
        headerBottom - 16 * application.windows.firstMatch.frame.width / 375
    }

    private func launch(extra: [String]) {
        application.launchArguments = ["--language", "en"] + extra
        application.launch()
        let open = application.buttons["sandbox.open"]
        XCTAssertTrue(open.waitForExistence(timeout: 10))
        open.tap()
    }

    private func text(_ value: String) -> XCUIElement {
        application.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", value)).firstMatch
    }

    private func send(_ message: String) {
        let input = application.textViews["composer.input"]
        XCTAssertTrue(input.waitForExistence(timeout: 5))
        input.tap()
        input.typeText(message)
        application.buttons["composer.send"].tap()
    }

    private func waitForSendButton(label: String) -> Bool {
        let matched = expectation(
            for: NSPredicate(format: "label == %@", label), evaluatedWith: application.buttons["composer.send"]
        )
        return XCTWaiter.wait(for: [matched], timeout: 8) == .completed
    }

    /// Keyboard ikut memengaruhi layar, jadi jarak dihitung dari bawah header, bukan dari tepi layar.
    private func assertParked(_ question: String) {
        settle()
        let bubble = text(question)
        XCTAssertTrue(bubble.exists)
        capture("chat-question-parked")
        let preview = 48 * application.windows.firstMatch.frame.width / 375
        // Frame header menyertakan gradient di bawahnya; jarak dihitung dari tinggi solid headernya.
        XCTAssertEqual(bubble.frame.minY - solidHeaderBottom, preview, accuracy: 4)
    }

    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: application.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func isOnScreen(_ element: XCUIElement) -> Bool {
        guard element.exists else { return false }
        let frame = element.frame
        let composerTop = application.buttons["composer.send"].frame.minY
        return frame.minY >= headerBottom && frame.maxY <= composerTop
    }

    private func settle() {
        RunLoop.current.run(until: Date().addingTimeInterval(1))
    }
}
