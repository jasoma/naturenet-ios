//
//  NatureNetUITests.swift
//  NatureNetUITests
//
//  Created by Jason Maher on 2/5/16.
//  Copyright © 2016 Jinyue Xia. All rights reserved.
//

import XCTest
import Nimble

/// Ensure 'Hardware -> Keyboard -> Connect Hardware Keyboard' is unchecked in the iPhone simulator.
///
/// TODO: Tests are ordered but currently require the simulated app to be in the 'signed out' state before
///       starting or the tests will fail. Need a way to clear the logged in state programatically.
class UserSignInSignOut: XCTestCase {

    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
        XCUIDevice.sharedDevice().orientation = .Portrait
    }

    func test_1_UserSignIn() {
        let signInButton = app.buttons["Sign In"]
        signInButton.tap()

        let tablesQuery = app.tables
        let usernameField = tablesQuery.cells.textFields["Enter username"]
        usernameField.tap()
        usernameField.typeText("nn_testuser")

        let passwordField = tablesQuery.cells.secureTextFields["Enter password"]
        passwordField.tap()
        passwordField.typeText("1234")

        signInButton.tap()

        expect(self.app.staticTexts["Welcome, nn_testuser"].exists).toEventually(beTrue(), timeout: 4)
    }

    func test_2_UserSignOut() {
        app.collectionViews.images["nnProfile"].tap()
        app.tables.staticTexts["Sign out"].tap()
        app.sheets["Before you sign out, do you have any suggestions to make NatureNet better?"].collectionViews.buttons["Sign me out"].tap()
    }
}
