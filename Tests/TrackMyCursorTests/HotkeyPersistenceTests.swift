import XCTest
@testable import TrackMyCursor

final class HotkeyPersistenceTests: XCTestCase {
    func testHotkeyPersistence() {
        let model = CursorModel.shared
        let savedKeyCode = model.hotkeyKeyCode
        let savedModifiers = model.hotkeyModifiers
        let savedKey = model.hotkeyKey
        model.hotkeyKeyCode = 123
        model.hotkeyModifiers = 456
        model.hotkeyKey = "X"

        XCTAssertEqual(UserDefaults.standard.integer(forKey: "TrackMyCursor.hotkeyKeyCode"), 123)
        XCTAssertEqual(UserDefaults.standard.integer(forKey: "TrackMyCursor.hotkeyModifiers"), 456)
        XCTAssertEqual(UserDefaults.standard.string(forKey: "TrackMyCursor.hotkeyKey"), "X")

        model.hotkeyKeyCode = savedKeyCode
        model.hotkeyModifiers = savedModifiers
        model.hotkeyKey = savedKey
    }
}