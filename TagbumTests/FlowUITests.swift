import XCTest

final class FlowUITests: XCTestCase {
    func testCreateAndRenameSubject() {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
        app.buttons["newAlbum"].tap()
        let field = app.textFields["albumName"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap(); field.typeText("Physics")
        app.buttons["saveAlbum"].tap()
        let album = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Physics")).firstMatch
        XCTAssertTrue(album.waitForExistence(timeout: 5))
        album.tap()
        XCTAssertTrue(app.buttons["scanDocument"].waitForExistence(timeout: 5))
        app.buttons["科目のメニュー"].tap()
        app.buttons["科目名を編集"].tap()
        let edit = app.textFields["albumName"]
        XCTAssertTrue(edit.waitForExistence(timeout: 5))
        edit.tap(); edit.typeText(" II")
        app.buttons["saveAlbum"].tap()
        XCTAssertTrue(app.navigationBars["Physics II"].waitForExistence(timeout: 5))
    }

    func testViewerSwipeAndSwitchSubject() {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--seed"]
        app.launch()
        let album = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "物理学概論、資料3枚")).firstMatch
        XCTAssertTrue(album.waitForExistence(timeout: 20))
        album.tap()
        let page = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "1ページ目")).firstMatch
        XCTAssertTrue(page.waitForExistence(timeout: 5))
        page.tap()
        XCTAssertTrue(app.staticTexts["1 / 3"].waitForExistence(timeout: 5))
        app.swipeLeft()
        XCTAssertTrue(app.staticTexts["2 / 3"].waitForExistence(timeout: 5))
        app.buttons["数学"].tap()
        XCTAssertTrue(app.staticTexts["1 / 3"].waitForExistence(timeout: 5))
        app.buttons["表示中の資料を削除"].tap()
        app.alerts.buttons["削除"].tap()
        XCTAssertTrue(app.staticTexts["1 / 2"].waitForExistence(timeout: 5))
        app.buttons["資料を閉じる"].tap()
        XCTAssertTrue(app.buttons["scanDocument"].waitForExistence(timeout: 5))
    }
}
