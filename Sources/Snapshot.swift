import Foundation
import SnapshotTesting
import SwiftUI

#if os(iOS)
    @MainActor
    public func assertSnapshot(
        view: some View,
        fileID: StaticString = #fileID,
        file: StaticString = #filePath,
        testName: String = #function,
        line: UInt = #line,
        column: UInt = #column
    ) {
        assertSnapshot(
            of: view,
            as: .image,
            fileID: fileID,
            file: file,
            testName: "\(testName).\(platformLabel)",
            line: line,
            column: column
        )
    }
#else
    @MainActor
    public func assertSnapshot(
        view: some View,
        fileID: StaticString = #fileID,
        file: StaticString = #filePath,
        testName: String = #function,
        line: UInt = #line,
        column: UInt = #column
    ) {
        let hostingVC = NSHostingController(rootView: view)
        hostingVC.view.frame = CGRect(x: 0, y: 0, width: 1024, height: 768)
        hostingVC.view.layoutSubtreeIfNeeded()
        assertSnapshot(
            of: hostingVC,
            as: .image,
            fileID: fileID,
            file: file,
            testName: "\(testName).\(platformLabel)",
            line: line,
            column: column
        )
    }
#endif
