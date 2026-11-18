import XCTest
@testable import TrackMyCursor

final class IdleHideTests: XCTestCase {
    func testIdleHide() {
        let model = CursorModel.shared
        let delegate = AppDelegate()
        let savedTime = model.borderDisappearTime
        let savedVisible = model.isBorderVisible
        model.borderDisappearTime = 1
        model.isBorderVisible = true
        delegate.lastMoveTime = Date().addingTimeInterval(-2)
        delegate.updateIdleVisibility(now: Date())
        XCTAssertFalse(model.isBorderVisible)
        model.borderDisappearTime = savedTime
        model.isBorderVisible = savedVisible
    }

    func testNoIdleHideWhenDisabled() {
        let model = CursorModel.shared
        let delegate = AppDelegate()
        let savedTime = model.borderDisappearTime
        let savedVisible = model.isBorderVisible
        model.borderDisappearTime = 0
        model.isBorderVisible = false
        delegate.lastMoveTime = Date().addingTimeInterval(-10)
        delegate.updateIdleVisibility(now: Date())
        XCTAssertTrue(model.isBorderVisible)
        model.borderDisappearTime = savedTime
        model.isBorderVisible = savedVisible
    }
}