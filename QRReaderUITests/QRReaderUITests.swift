//
//  QRReaderUITests.swift
//  QRReaderUITests
//
//  Created by devonly on 2025/07/07.
//
//  Every test launches with the DEBUG-only `-ui-testing` configuration (isolated UserDefaults suite and a mock
//  camera). Flags are documented in QRReader/Configuration/UITestSupport.swift:
//    -ui-testing -reset-state -skip-onboarding -ui-seed-history -ui-camera <state>
//  Fixture buttons: ui.fixture.url / text / long / burst. `scan.status` has value "ready" or "paused".
//

import XCTest

final class QRReaderUITests: XCTestCase {
    private let timeout: TimeInterval = 10

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func launch(_ extra: [String] = [], onboarding: Bool = false, language: String = "en") -> XCUIApplication {
        let app = XCUIApplication()
        var arguments = ["-ui-testing", "-reset-state", "-AppleLanguages", "(\(language))", "-AppleLocale", language == "ja" ? "ja_JP" : "en_US"]
        if !onboarding {
            arguments.append("-skip-onboarding")
        }
        app.launchArguments = arguments + extra
        app.launch()
        return app
    }

    private func element(_ app: XCUIApplication, _ identifier: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    private func historyRows(_ app: XCUIApplication) -> XCUIElementQuery {
        app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH 'history.row.'"))
    }

    private func waitForGone(_ element: XCUIElement) {
        let gone = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: element)
        XCTAssertEqual(XCTWaiter().wait(for: [gone], timeout: timeout), .completed)
    }

    private func waitForStatus(_ app: XCUIApplication, _ value: String) {
        let status = element(app, "scan.status")
        XCTAssertTrue(status.waitForExistence(timeout: timeout))
        let matches = XCTNSPredicateExpectation(predicate: NSPredicate(format: "value == %@", value), object: status)
        XCTAssertEqual(XCTWaiter().wait(for: [matches], timeout: timeout), .completed)
    }

    // MARK: - Scan gating

    @MainActor
    func testScanResultCloseAndRescanGating() throws {
        let app = launch()
        waitForStatus(app, "ready")

        // Two callbacks arrive in the same turn; only the first may be accepted.
        app.buttons["ui.fixture.burst"].tap()
        let payload = element(app, "result.payload")
        XCTAssertTrue(payload.waitForExistence(timeout: timeout))
        XCTAssertEqual(payload.label, "https://example.com/qrreader/burst-first")
        XCTAssertTrue(element(app, "result.type").label == "URL")
        XCTAssertTrue(app.buttons["result.open"].exists)

        // Closing resumes scanning, and a different code is accepted again.
        app.buttons["result.close"].tap()
        waitForGone(payload)
        waitForStatus(app, "ready")
        app.buttons["ui.fixture.text"].tap()
        XCTAssertTrue(payload.waitForExistence(timeout: timeout))
        XCTAssertTrue(payload.label.hasPrefix("QRReader fixture text"))
        XCTAssertFalse(app.buttons["result.open"].exists, "plain text has no open action")
        app.buttons["result.close"].tap()
        waitForGone(payload)

        // Exactly the two accepted scans were saved, newest first.
        app.buttons["tab.history"].tap()
        XCTAssertTrue(element(app, "history.list").waitForExistence(timeout: timeout))
        XCTAssertEqual(historyRows(app).count, 2)
    }

    @MainActor
    func testScanResumesAfterSettingsClose() throws {
        let app = launch()
        waitForStatus(app, "ready")
        app.buttons["scan.settings"].tap()
        XCTAssertTrue(app.buttons["settings.close"].waitForExistence(timeout: timeout))
        app.buttons["settings.close"].tap()
        waitForGone(app.buttons["settings.close"])
        waitForStatus(app, "ready")
    }

    // MARK: - Result actions

    @MainActor
    func testCopyShowsFeedback() throws {
        let app = launch()
        app.buttons["ui.fixture.text"].tap()
        let copy = app.buttons["result.copy"]
        XCTAssertTrue(copy.waitForExistence(timeout: timeout))
        XCTAssertFalse(element(app, "result.copyFeedback").exists)
        copy.tap()
        XCTAssertTrue(element(app, "result.copyFeedback").waitForExistence(timeout: timeout))
    }

    @MainActor
    func testLongPayloadKeepsActionsAvailable() throws {
        let app = launch()
        app.buttons["ui.fixture.long"].tap()
        let payload = element(app, "result.payload")
        XCTAssertTrue(payload.waitForExistence(timeout: timeout))
        XCTAssertGreaterThan(payload.label.count, 1000)
        XCTAssertTrue(payload.label.hasSuffix("key120=value120"))

        for identifier in ["result.open", "result.copy", "result.share", "result.close"] {
            let button = app.buttons[identifier]
            XCTAssertTrue(button.exists, identifier)
            XCTAssertTrue(button.isHittable, "\(identifier) must stay reachable with a long payload")
        }
        // Opening is explicit: nothing left the app by itself.
        XCTAssertEqual(app.state, .runningForeground)
    }

    // MARK: - History

    @MainActor
    func testHistoryPresentationAndClearCancelThenConfirm() throws {
        let app = launch(["-ui-seed-history"])
        app.buttons["tab.history"].tap()
        XCTAssertTrue(element(app, "history.list").waitForExistence(timeout: timeout))
        XCTAssertEqual(historyRows(app).count, 3)
        XCTAssertTrue(historyRows(app).element(boundBy: 0).label.contains("qleap.jp"), "newest first")

        // A history row opens the same result sheet, and closing returns to history.
        historyRows(app).element(boundBy: 0).tap()
        XCTAssertTrue(element(app, "result.payload").waitForExistence(timeout: timeout))
        XCTAssertEqual(element(app, "result.title").label, "qleap.jp")
        app.buttons["result.close"].tap()
        waitForGone(element(app, "result.payload"))
        XCTAssertTrue(element(app, "history.list").exists)

        // Cancel keeps everything.
        app.buttons["history.clear"].tap()
        XCTAssertTrue(app.alerts.firstMatch.waitForExistence(timeout: timeout))
        app.alerts.buttons["Cancel"].tap()
        waitForGone(app.alerts.firstMatch)
        XCTAssertEqual(historyRows(app).count, 3)

        // Confirm empties history and shows the empty state.
        app.buttons["history.clear"].tap()
        XCTAssertTrue(app.alerts.firstMatch.waitForExistence(timeout: timeout))
        app.alerts.buttons["Clear"].tap()
        XCTAssertTrue(element(app, "history.empty").waitForExistence(timeout: timeout))
        XCTAssertEqual(historyRows(app).count, 0)
    }

    @MainActor
    func testSwipeDeleteRemovesOnlyConfirmedRow() throws {
        let app = launch(["-ui-seed-history"])
        app.buttons["tab.history"].tap()
        XCTAssertTrue(element(app, "history.list").waitForExistence(timeout: timeout))
        historyRows(app).element(boundBy: 0).swipeLeft()
        app.buttons["Delete"].firstMatch.tap()
        XCTAssertTrue(app.alerts.firstMatch.waitForExistence(timeout: timeout))
        app.alerts.buttons["Delete"].tap()
        waitForGone(app.alerts.firstMatch)
        XCTAssertEqual(historyRows(app).count, 2)
        XCTAssertFalse(historyRows(app).element(boundBy: 0).label.contains("qleap.jp"))
    }

    // MARK: - Settings

    @MainActor
    func testSettingsOpensFromBothTabs() throws {
        let app = launch()
        app.buttons["scan.settings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: timeout))
        app.buttons["settings.close"].tap()
        waitForGone(app.buttons["settings.close"])

        app.buttons["tab.history"].tap()
        app.buttons["history.settings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: timeout))
        app.buttons["settings.close"].tap()
        waitForGone(app.buttons["settings.close"])
    }

    // MARK: - First launch

    @MainActor
    func testCameraEducationButtonsUseNeutralLanguage() throws {
        for (language, title, explanation) in [
            ("en", "Continue", "Camera access is needed to scan QR codes."),
            ("ja", "続ける", "QRコードの読み取りにはカメラを使用します。")
        ] {
            let app = launch(["-ui-camera", "notDetermined"], onboarding: true, language: language)
            let intro = app.buttons["intro.start"]
            XCTAssertTrue(intro.waitForExistence(timeout: timeout))
            let introCapture = XCTAttachment(screenshot: app.screenshot())
            introCapture.name = "permission-intro-\(language)"
            introCapture.lifetime = .keepAlways
            add(introCapture)
            XCTAssertEqual(intro.label, title)
            intro.tap()
            XCTAssertTrue(element(app, "scan.camera").waitForExistence(timeout: timeout))

            let scanner = launch(["-ui-camera", "notDetermined"], language: language)
            let request = scanner.buttons["scan.permission.request"]
            XCTAssertTrue(request.waitForExistence(timeout: timeout))
            let panelCapture = XCTAttachment(screenshot: scanner.screenshot())
            panelCapture.name = "permission-panel-\(language)"
            panelCapture.lifetime = .keepAlways
            add(panelCapture)
            XCTAssertEqual(request.label, title)
            XCTAssertTrue(scanner.staticTexts[explanation].exists)
            request.tap()
            XCTAssertTrue(element(scanner, "scan.camera").waitForExistence(timeout: timeout))
            scanner.terminate()
        }
    }

    @MainActor
    func testOnePageIntroCompletesAndPersists() throws {
        let app = launch(["-ui-camera", "notDetermined"], onboarding: true)
        XCTAssertTrue(element(app, "intro.root").waitForExistence(timeout: timeout))
        XCTAssertFalse(element(app, "scan.camera").exists, "scanner must not mount behind the intro")
        app.buttons["intro.start"].tap()
        waitForGone(element(app, "intro.root"))
        XCTAssertTrue(element(app, "scan.camera").waitForExistence(timeout: timeout))

        // Completion is persisted: relaunch without resetting state.
        app.terminate()
        let relaunched = XCUIApplication()
        relaunched.launchArguments = ["-ui-testing", "-ui-camera", "authorized", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        relaunched.launch()
        XCTAssertTrue(element(relaunched, "scan.camera").waitForExistence(timeout: timeout))
        XCTAssertFalse(element(relaunched, "intro.root").exists)
    }

    @MainActor
    func testDeniedPermissionStillFinishesIntroThenShowsHelp() throws {
        let app = launch(["-ui-camera", "notDeterminedDeny"], onboarding: true)
        XCTAssertTrue(element(app, "intro.root").waitForExistence(timeout: timeout))
        app.buttons["intro.start"].tap()
        waitForGone(element(app, "intro.root"))
        XCTAssertTrue(element(app, "scan.permission.denied").waitForExistence(timeout: timeout))
        XCTAssertTrue(app.buttons["scan.permission.openSettings"].exists)
        XCTAssertFalse(element(app, "scan.camera").exists)

        // Denial leaves unrelated features usable and does not force onboarding on relaunch.
        app.buttons["tab.history"].tap()
        XCTAssertTrue(element(app, "history.empty").waitForExistence(timeout: timeout))
        app.buttons["history.settings"].tap()
        XCTAssertTrue(app.buttons["settings.close"].waitForExistence(timeout: timeout))
        app.terminate()
        app.launchArguments = ["-ui-testing", "-ui-camera", "denied", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
        XCTAssertTrue(element(app, "scan.permission.denied").waitForExistence(timeout: timeout))
        XCTAssertFalse(element(app, "intro.root").exists)
    }
}
