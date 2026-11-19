//
//  QRReaderUITestsLaunchTests.swift
//  QRReaderUITests
//
//  Created by devonly on 2025/07/07.
//

import XCTest

final class QRReaderUITestsLaunchTests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// Launches into the isolated, seeded test configuration and attaches a screenshot.
    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-reset-state", "-skip-onboarding", "-ui-seed-history"]
        app.launch()
        XCTAssertTrue(app.descendants(matching: .any).matching(identifier: "scan.camera").firstMatch.waitForExistence(timeout: 10))

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Scan"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
