//
//  FormToggleUITests.swift
//  TanyaAISandboxUITests
//
//  Created by Wendra on 12/11/26.
//

import XCTest

final class FormToggleUITests: XCTestCase {
    private let application = XCUIApplication()

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    func testBindingUpdatesFromTheRowAndFromTheParent() {
        launch()
        assertState(isOn: false)
        let field = application.switches["sandbox.formToggle"]
        // Ketuk sisi label, bukan hanya thumb.
        field.coordinate(withNormalizedOffset: CGVector(dx: 0.05, dy: 0.5)).tap()
        assertState(isOn: true)
        field.tap()
        assertState(isOn: false)
        application.buttons["sandbox.formToggle.change"].tap()
        assertState(isOn: true)
    }

    func testLocalAndParentDisabledKeepTheValueAndAllowExternalUpdates() {
        launch()
        let field = application.switches["sandbox.formToggle"]
        for identifier in ["sandbox.formToggle.enabled", "sandbox.formToggle.parent"] {
            let control = application.switches[identifier]
            control.tap()
            XCTAssertFalse(field.isEnabled)
            field.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            assertState(isOn: false)
            application.buttons["sandbox.formToggle.change"].tap()
            assertState(isOn: true)
            XCTAssertFalse(field.isEnabled)
            field.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            assertState(isOn: true)
            control.tap()
            XCTAssertTrue(field.isEnabled)
            field.tap()
            assertState(isOn: false)
        }
    }

    func testCallerSuppliesLocalizedLabels() {
        for (locale, title) in [
            ("en", "Show balance information"),
            ("id", "Tampilkan informasi saldo"),
            ("zh-Hans", "显示余额信息")
        ] {
            launch(locale: locale)
            let field = application.switches["sandbox.formToggle"]
            XCTAssertEqual(field.label, title)
            XCTAssertTrue(field.isEnabled)
            application.terminate()
        }
    }
}

// MARK: - Helpers

private extension FormToggleUITests {
    func launch(locale: String = "en") {
        application.launchArguments = ["--language", locale, "--form-toggle-demo"]
        application.launch()
        XCTAssertTrue(application.switches["sandbox.formToggle"].waitForExistence(timeout: 10))
    }

    func assertState(isOn: Bool, file: StaticString = #filePath, line: UInt = #line) {
        let field = application.switches["sandbox.formToggle"]
        let state = expectation(
            for: NSPredicate(format: "value == %@", isOn ? "1" : "0"),
            evaluatedWith: field
        )
        wait(for: [state], timeout: 5)
        XCTAssertEqual(
            application.staticTexts["sandbox.formToggle.value"].label,
            isOn ? "On" : "Off",
            file: file,
            line: line
        )
    }
}
