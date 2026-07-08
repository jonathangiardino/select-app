import XCTest
@testable import SelectApp

final class LauncherLayoutTests: XCTestCase {
    func testMiddleRowUsesUniformCorners() {
        let corners = LauncherLayout.selectionCorners(index: 1, count: 5, selectedIndex: 1)
        XCTAssertEqual(corners.topLeading, LauncherMetrics.rowCornerRadius)
        XCTAssertEqual(corners.bottomLeading, LauncherMetrics.rowCornerRadius)
    }

    func testFirstRowWhenSelectedUsesUniformCorners() {
        let corners = LauncherLayout.selectionCorners(index: 0, count: 5, selectedIndex: 0)
        XCTAssertEqual(corners.topLeading, LauncherMetrics.rowCornerRadius)
        XCTAssertEqual(corners.bottomLeading, LauncherMetrics.rowCornerRadius)
    }

    func testLastRowWhenSelectedUsesContainerBottomCorners() {
        let corners = LauncherLayout.selectionCorners(index: 4, count: 5, selectedIndex: 4)
        XCTAssertEqual(corners.topLeading, LauncherMetrics.rowCornerRadius)
        XCTAssertEqual(corners.bottomLeading, LauncherMetrics.innerCornerRadius)
        XCTAssertEqual(corners.bottomTrailing, LauncherMetrics.innerCornerRadius)
    }

    func testLastRowWhenNotSelectedUsesUniformCorners() {
        let corners = LauncherLayout.selectionCorners(index: 4, count: 5, selectedIndex: 2)
        XCTAssertEqual(corners.bottomLeading, LauncherMetrics.rowCornerRadius)
    }

    func testSingleRowWhenSelectedUsesContainerBottom() {
        let corners = LauncherLayout.selectionCorners(index: 0, count: 1, selectedIndex: 0)
        XCTAssertEqual(corners.bottomLeading, LauncherMetrics.innerCornerRadius)
    }

    func testContentWidthAccountsForPanelInset() {
        XCTAssertEqual(
            LauncherMetrics.contentWidth,
            LauncherMetrics.width - LauncherMetrics.panelInset * 2
        )
    }
}
