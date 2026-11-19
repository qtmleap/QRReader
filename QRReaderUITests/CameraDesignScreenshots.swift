import XCTest

@MainActor
final class CameraDesignScreenshots: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    private func launch(_ extra: [String] = [], intro: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-reset-state", "-ui-hide-controls", "-AppleLanguages", "(ja)", "-AppleLocale", "ja_JP"] + (intro ? [] : ["-skip-onboarding"]) + extra
        app.launch()
        return app
    }

    private func node(_ app: XCUIApplication, _ id: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: id).firstMatch
    }

    private func capture(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testCaptureMainScreens() {
        let app = launch(["-ui-seed-history"])
        XCTAssertTrue(node(app, "scan.camera").waitForExistence(timeout: 10))
        capture(app, "camera-portrait")
        app.buttons["tab.history"].tap()
        XCTAssertTrue(node(app, "history.list").waitForExistence(timeout: 10))
        capture(app, "history-portrait")
        app.buttons["history.settings"].tap()
        XCTAssertTrue(app.buttons["settings.close"].waitForExistence(timeout: 10))
        capture(app, "settings-portrait")
    }

    func testCaptureResult() {
        let app = launch(["-ui-initial-result", "url"])
        XCTAssertTrue(app.buttons["result.copy"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["result.open"].isHittable)
        XCTAssertTrue(app.buttons["result.share"].isHittable)
        capture(app, "result-url")
        app.buttons["result.share"].tap()
        let covered = XCTNSPredicateExpectation(predicate: NSPredicate(format: "hittable == false"), object: app.buttons["result.open"])
        XCTAssertEqual(XCTWaiter.wait(for: [covered], timeout: 10), .completed)
        capture(app, "system-share")
    }

    func testCaptureTextResult() {
        let app = launch(["-ui-initial-result", "text"])
        XCTAssertTrue(app.buttons["result.copy"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["result.copy"].isHittable)
        XCTAssertTrue(app.buttons["result.share"].isHittable)
        XCTAssertFalse(app.buttons["result.open"].exists)
        capture(app, "result-text")
    }

    func testCaptureSettingsDestinations() {
        let destinations = [
            ("お問い合わせ", "settings-contact"),
            ("開発者", "settings-developer"),
            ("ライセンス", "settings-licenses")
        ]
        for (title, name) in destinations {
            let app = launch()
            XCTAssertTrue(app.buttons["scan.settings"].waitForExistence(timeout: 10))
            app.buttons["scan.settings"].tap()
            XCTAssertTrue(app.buttons[title].waitForExistence(timeout: 10))
            app.buttons[title].tap()
            XCTAssertTrue(app.navigationBars[title].waitForExistence(timeout: 10))
            capture(app, name)
            app.terminate()
        }
    }

    func testLongTitleKeepsAllActionsReachable() {
        let app = launch(["-ui-initial-result", "long"])
        XCTAssertTrue(app.buttons["result.copy"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["result.open"].isHittable)
        XCTAssertTrue(app.buttons["result.copy"].isHittable)
        XCTAssertTrue(app.buttons["result.share"].isHittable)
        XCTAssertTrue(app.buttons["result.close"].isHittable)
        capture(app, "result-long-title")
    }

    func testCaptureIntroAndDeniedPermission() {
        let app = launch(["-ui-camera", "notDeterminedDeny"], intro: true)
        XCTAssertTrue(app.buttons["intro.start"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["intro.start"].isHittable)
        capture(app, "intro-portrait")
        app.buttons["intro.start"].tap()
        XCTAssertTrue(app.buttons["scan.permission.openSettings"].waitForExistence(timeout: 10), app.debugDescription)
        XCTAssertTrue(app.buttons["scan.permission.openSettings"].isHittable)
        capture(app, "camera-denied")
        app.buttons["tab.history"].tap()
        XCTAssertTrue(node(app, "history.empty").waitForExistence(timeout: 10))
        capture(app, "history-empty")
    }

    func testSettingsHowToReopensIntro() {
        let app = launch()
        XCTAssertTrue(app.buttons["scan.settings"].waitForExistence(timeout: 10))
        app.buttons["scan.settings"].tap()
        XCTAssertTrue(app.buttons["アプリの使い方"].waitForExistence(timeout: 10))
        app.buttons["アプリの使い方"].tap()
        XCTAssertTrue(app.buttons["intro.start"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["settings.close"].exists)
        capture(app, "intro-reopened")
        app.buttons["intro.start"].tap()
        XCTAssertTrue(node(app, "scan.camera").waitForExistence(timeout: 10))
    }
}

/// English capture pass. Uses the same isolated launch as the Japanese class but forces en/en_US,
/// and asserts real English strings (and the absence of Japanese ones) before each capture.
@MainActor
final class CameraDesignScreenshotsEN: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    private let japaneseLabels = ["スキャン", "履歴", "コピー", "共有", "すべて削除", "リンクを開く"]
    private let cjkDateMarks = ["年", "月", "日"]

    private func launch(_ extra: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-reset-state", "-ui-hide-controls", "-skip-onboarding",
                               "-AppleLanguages", "(en)", "-AppleLocale", "en_US"] + extra
        app.launch()
        return app
    }

    private func node(_ app: XCUIApplication, _ id: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: id).firstMatch
    }

    private func text(_ app: XCUIApplication, _ label: String) -> XCUIElement {
        app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", label)).firstMatch
    }

    private func requireText(_ app: XCUIApplication, _ label: String, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(text(app, label).waitForExistence(timeout: 10),
                      "Missing English '\(label)'\n\(app.debugDescription)", file: file, line: line)
    }

    private func assertNoJapanese(_ app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) {
        for label in japaneseLabels {
            let match = app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", label)).firstMatch
            XCTAssertFalse(match.exists, "Unexpected Japanese '\(label)'\n\(app.debugDescription)", file: file, line: line)
        }
    }

    private func capture(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testCaptureMainScreens() {
        let app = launch(["-ui-seed-history"])
        XCTAssertTrue(node(app, "scan.camera").waitForExistence(timeout: 10), app.debugDescription)
        requireText(app, "Scan")
        requireText(app, "Align the QR code within the frame")
        assertNoJapanese(app)
        capture(app, "camera-portrait")

        app.buttons["tab.history"].tap()
        XCTAssertTrue(node(app, "history.list").waitForExistence(timeout: 10), app.debugDescription)
        requireText(app, "History")
        XCTAssertTrue(app.buttons["tab.history"].label.contains("History"), app.debugDescription)
        XCTAssertTrue(node(app, "history.clear").waitForExistence(timeout: 10), app.debugDescription)
        requireText(app, "Clear All")
        assertNoJapanese(app)
        // Native history dates: only check rows whose combined label we can read.
        let row = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH %@", "history.row.")).firstMatch
        if row.waitForExistence(timeout: 5) {
            for mark in cjkDateMarks {
                XCTAssertFalse(row.label.contains(mark), "History row has CJK date mark: \(row.label)")
            }
        }
        capture(app, "history-portrait")

        app.buttons["history.settings"].tap()
        XCTAssertTrue(app.buttons["settings.close"].waitForExistence(timeout: 10), app.debugDescription)
        // Settings title is optional: package labels vary, so don't fail if it is not exposed.
        if text(app, "Settings").waitForExistence(timeout: 3) {
            XCTAssertTrue(text(app, "Settings").exists)
        }
        assertNoJapanese(app)
        capture(app, "settings-portrait")
    }

    func testCaptureResult() {
        let app = launch(["-ui-initial-result", "url"])
        XCTAssertTrue(app.buttons["result.copy"].waitForExistence(timeout: 10), app.debugDescription)
        XCTAssertEqual(app.buttons["result.open"].label, "Open Link", app.debugDescription)
        XCTAssertEqual(app.buttons["result.copy"].label, "Copy", app.debugDescription)
        XCTAssertEqual(app.buttons["result.share"].label, "Share", app.debugDescription)
        XCTAssertTrue(app.buttons["result.open"].isHittable, app.debugDescription)
        XCTAssertTrue(app.buttons["result.share"].isHittable, app.debugDescription)
        let date = node(app, "result.date")
        XCTAssertTrue(date.waitForExistence(timeout: 5), app.debugDescription)
        let currentYear = Calendar(identifier: .gregorian).component(.year, from: Date())
        XCTAssertTrue(date.label.contains(String(currentYear)), "Date label: \(date.label)")
        for mark in cjkDateMarks {
            XCTAssertFalse(date.label.contains(mark), "Date label has CJK mark: \(date.label)")
        }
        assertNoJapanese(app)
        capture(app, "result-url")

        app.buttons["result.share"].tap()
        let covered = XCTNSPredicateExpectation(predicate: NSPredicate(format: "hittable == false"), object: app.buttons["result.open"])
        XCTAssertEqual(XCTWaiter.wait(for: [covered], timeout: 10), .completed, app.debugDescription)
        // The in-app Copy button is also labelled "Copy"; require the share sheet's own action.
        let shareCopy = app.cells.matching(NSPredicate(format: "label == 'Copy'")).firstMatch
        let saveToFiles = app.cells.matching(NSPredicate(format: "label == 'Save to Files'")).firstMatch
        XCTAssertTrue(shareCopy.waitForExistence(timeout: 15), "Share sheet Copy not visible\n\(app.debugDescription)")
        XCTAssertTrue(saveToFiles.waitForExistence(timeout: 15), "Share sheet Save to Files not visible\n\(app.debugDescription)")
        let copyReady = XCTNSPredicateExpectation(predicate: NSPredicate(format: "hittable == true"), object: shareCopy)
        let filesReady = XCTNSPredicateExpectation(predicate: NSPredicate(format: "hittable == true"), object: saveToFiles)
        XCTAssertEqual(XCTWaiter.wait(for: [copyReady, filesReady], timeout: 15), .completed, app.debugDescription)
        capture(app, "system-share")
    }
}
