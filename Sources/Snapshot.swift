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
    // On macOS assertSnapshot isn't supported, so we use assertRender instead (alias)
    @MainActor
    public func assertSnapshot(
        view: some View,
        fileID: StaticString = #fileID,
        file: StaticString = #filePath,
        testName: String = #function,
        line: UInt = #line,
        column: UInt = #column
    ) {
        assertRender(
            view: view,
            fileID: fileID,
            file: file,
            testName: testName,
            line: line,
            column: column
        )
    }
#endif
