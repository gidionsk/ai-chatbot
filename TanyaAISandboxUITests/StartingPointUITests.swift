//
//  StartingPointUITests.swift
//  TanyaAISandboxUITests
//
//  Created by Wendra on 15/10/26.
//

import XCTest

final class StartingPointUITests: XCTestCase {
    private let application = XCUIApplication()

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    func testThreeLanguagesShowLocalizedEmptyComposer() {
        for (locale, label) in [("en", "Send message"), ("id", "Kirim pesan"), ("zh-Hans", "发送消息")] {
            launch(locale: locale)
            let input = application.textViews["composer.input"]
            let send = application.buttons["composer.send"]
            XCTAssertTrue(input.waitForExistence(timeout: 10))
            XCTAssertFalse(send.isEnabled)
            XCTAssertEqual(send.label, label)
            XCTAssertFalse(input.label.isEmpty)
            XCTAssertLessThanOrEqual(input.frame.maxX, send.frame.minX + 1)
            XCTAssertEqual(input.frame.midY, send.frame.midY, accuracy: 1)
            capture("starter-" + locale)
            application.terminate()
        }
    }

    func testFourLineLimitLongWordAndAcceptedSend() {
        launch(locale: "en")
        let input = application.textViews["composer.input"]
        XCTAssertTrue(input.waitForExistence(timeout: 10))
        input.tap()
        input.typeText("First")
        let firstHeight = input.frame.height
        let initialWidth = input.frame.width
        let send = application.buttons["composer.send"]
        let initialButtonCenter = send.frame.midY
        XCTAssertEqual(input.frame.midY, initialButtonCenter, accuracy: 1)
        capture("starter-one-line-keyboard")
        input.typeText("\nSecond\nThird\nFourth")
        let fourthHeight = input.frame.height
        XCTAssertGreaterThan(fourthHeight, firstHeight)
        XCTAssertEqual(send.frame.midY, initialButtonCenter, accuracy: 1)
        XCTAssertGreaterThan(send.frame.midY, input.frame.midY)
        input.typeText("\nFifth\n" + String(repeating: "m", count: 128))
        XCTAssertEqual(input.frame.height, fourthHeight, accuracy: 1)
        XCTAssertEqual(input.frame.width, initialWidth, accuracy: 1)
        XCTAssertEqual(send.frame.midY, initialButtonCenter, accuracy: 1)
        XCTAssertTrue(send.isHittable)
        XCTAssertLessThanOrEqual(input.frame.maxX, send.frame.minX + 1)
        XCTAssertLessThanOrEqual(send.frame.maxY, application.keyboards.firstMatch.frame.minY + 1)
        assertVisualInsets(isMultiline: true)
        capture("starter-four-lines-keyboard")
        send.tap()
        XCTAssertEqual(input.value as? String, "")
        // Titik bergerak → stop → jawaban selesai; draft kosong membuat kirim tetap nonaktif.
        let answered = expectation(for: NSPredicate(format: "label == %@", "Send message"), evaluatedWith: send)
        wait(for: [answered], timeout: 5)
        XCTAssertFalse(send.isEnabled)
        XCTAssertEqual(input.frame.midY, send.frame.midY, accuracy: 1)
    }

    func testVisualInsetsAndButtonEdges() {
        launch(locale: "en")
        let input = application.textViews["composer.input"]
        XCTAssertTrue(input.waitForExistence(timeout: 10))
        assertVisualInsets(isMultiline: false)
        input.tap()
        let send = application.buttons["composer.send"]
        for (horizontal, vertical) in [(0.05, 0.5), (0.95, 0.5), (0.5, 0.05), (0.5, 0.95)] {
            // Draft dikunci selama titik bergerak; tunggu jawaban sebelumnya selesai (`turn_end`) baru mengetik.
            let idle = expectation(for: NSPredicate(format: "label == %@", "Send message"), evaluatedWith: send)
            wait(for: [idle], timeout: 5)
            input.typeText("Tap edge")
            XCTAssertTrue(send.isEnabled)
            send.coordinate(withNormalizedOffset: CGVector(dx: horizontal, dy: vertical)).tap()
            XCTAssertEqual(input.value as? String, "")
            XCTAssertNotEqual(send.label, "Send message", "tap di tepi tombol harus mengirim")
        }
    }

    func testWhitespaceCannotBeSubmitted() {
        launch(locale: "id")
        let input = application.textViews["composer.input"]
        XCTAssertTrue(input.waitForExistence(timeout: 10))
        input.tap()
        input.typeText("   \n  ")
        XCTAssertFalse(application.buttons["composer.send"].isEnabled)
    }

    func testEmptyFocusedInputAndCaretAfterClearing() {
        launch(locale: "en")
        let input = application.textViews["composer.input"]
        XCTAssertTrue(input.waitForExistence(timeout: 10))
        input.tap()
        XCTAssertTrue(application.keyboards.firstMatch.waitForExistence(timeout: 5))
        XCTAssertTrue(input.isHittable)
        capture("starter-empty-focused")
        input.typeText("Ag")
        capture("starter-caret-one-line")
        input.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 2))
        XCTAssertEqual(input.value as? String, "")
        XCTAssertEqual(input.frame.midY, application.buttons["composer.send"].frame.midY, accuracy: 1)
        capture("starter-empty-after-clearing")
    }

    func testRejectedSubmissionKeepsDraft() {
        launch(locale: "en", extra: ["--reject-send"])
        let input = application.textViews["composer.input"]
        XCTAssertTrue(input.waitForExistence(timeout: 10))
        input.tap()
        input.typeText("Keep my draft")
        application.buttons["composer.send"].tap()
        XCTAssertEqual(input.value as? String, "Keep my draft")
    }

    func testTextSizeSettingKeepsComposerFontAndLayoutFixed() {
        var referenceSizes: [CGSize]?
        for category in ["UICTContentSizeCategoryL", "UICTContentSizeCategoryAccessibilityXXXL"] {
            launch(locale: "zh-Hans", extra: ["-UIPreferredContentSizeCategoryName", category])
            let input = application.textViews["composer.input"]
            XCTAssertTrue(input.waitForExistence(timeout: 10))
            let send = application.buttons["composer.send"]
            XCTAssertEqual(input.frame.midY, send.frame.midY, accuracy: 1)
            let emptySize = input.frame.size
            input.tap()
            input.typeText("First")
            let singleLineSize = input.frame.size
            let initialButtonCenter = send.frame.midY
            XCTAssertEqual(input.frame.midY, initialButtonCenter, accuracy: 1)
            input.typeText("\nSecond\nThird\nFourth\nFifth")
            XCTAssertEqual(send.frame.midY, initialButtonCenter, accuracy: 1)
            XCTAssertGreaterThan(send.frame.midY, input.frame.midY)
            XCTAssertTrue(send.isHittable)
            XCTAssertLessThanOrEqual(input.frame.maxX, send.frame.minX + 1)
            XCTAssertLessThanOrEqual(send.frame.maxX, application.frame.maxX)
            let sizes = [emptySize, singleLineSize, input.frame.size, application.otherElements["composer"].frame.size]
            if let referenceSizes {
                for (actual, reference) in zip(sizes, referenceSizes) {
                    XCTAssertEqual(actual.width, reference.width, accuracy: 1)
                    XCTAssertEqual(actual.height, reference.height, accuracy: 1)
                }
                assertVisualInsets(isMultiline: true)
                capture("starter-accessibility-zh-Hans")
            } else {
                referenceSizes = sizes
            }
            application.terminate()
        }
    }

    func testBackReturnsToHostAndReopensWithEmptyDraft() {
        launch(locale: "en")
        let input = application.textViews["composer.input"]
        XCTAssertTrue(input.waitForExistence(timeout: 10))
        input.tap()
        input.typeText("Unsaved draft")
        application.buttons["Back"].tap()
        let open = application.buttons["sandbox.open"]
        XCTAssertTrue(open.waitForExistence(timeout: 10))
        XCTAssertTrue(open.isHittable)
        open.tap()
        XCTAssertTrue(input.waitForExistence(timeout: 10))
        XCTAssertEqual(input.value as? String, "")
        XCTAssertFalse(application.buttons["composer.send"].isEnabled)
    }

    func testSwipeFromLeadingEdgeReturnsToHostWithNativeNavigation() {
        launch(locale: "en")
        let input = application.textViews["composer.input"]
        XCTAssertTrue(input.waitForExistence(timeout: 10))
        let edge = application.coordinate(withNormalizedOffset: CGVector(dx: 0.005, dy: 0.5))
        // Geser pendek dibatalkan oleh UINavigationController: tetap di Tanya AI.
        edge.press(
            forDuration: 0.05, thenDragTo: application.coordinate(withNormalizedOffset: CGVector(dx: 0.15, dy: 0.5)),
            withVelocity: .slow, thenHoldForDuration: 0.2
        )
        XCTAssertTrue(input.waitForExistence(timeout: 3))
        edge.press(
            forDuration: 0.05, thenDragTo: application.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)),
            withVelocity: .fast, thenHoldForDuration: 0
        )
        XCTAssertTrue(application.buttons["sandbox.open"].waitForExistence(timeout: 5))
        XCTAssertFalse(input.exists)
    }

    private func launch(locale: String, extra: [String] = []) {
        application.launchArguments = ["--language", locale] + extra
        application.launch()
        let open = application.buttons["sandbox.open"]
        XCTAssertTrue(open.waitForExistence(timeout: 10))
        open.tap()
    }

    private func assertVisualInsets(isMultiline: Bool) {
        let composer = application.otherElements["composer"].frame
        let input = application.textViews["composer.input"].frame
        let send = application.buttons["composer.send"].frame
        let scale = application.frame.width / 375
        let buttonSize = (24 * scale).rounded()
        let padding = (16 * scale).rounded()
        XCTAssertEqual(send.width, buttonSize, accuracy: 1)
        XCTAssertEqual(send.height, buttonSize, accuracy: 1)
        XCTAssertEqual(input.minX - composer.minX, padding, accuracy: 1)
        XCTAssertEqual(composer.maxX - send.maxX, padding, accuracy: 1)
        XCTAssertEqual(composer.maxY - send.maxY, padding, accuracy: 1)
        if isMultiline {
            XCTAssertEqual(input.minY - composer.minY, padding, accuracy: 1)
        } else {
            XCTAssertEqual(send.minY - composer.minY, padding, accuracy: 1)
        }
    }

    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: application.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
