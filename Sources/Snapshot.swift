import Foundation
import SnapshotTesting
import SwiftUI

#if os(iOS)
    @MainActor
    public func assertSnapshot(
        view: some View,
        device: SnapshotDevice,
        named name: String? = nil,
        record recording: Bool? = nil,
        timeout: TimeInterval = 5,
        fileID: StaticString = #fileID,
        file: StaticString = #filePath,
        testName: String = #function,
        line: UInt = #line,
        column: UInt = #column
    ) {
        switch device {
        case .iOS, .any, .size: ()
        case .macOS:
            // Noop
            return
        }

        assertSnapshot(
            of: view.frame(width: device.width, height: device.height),
            as: .image,
            named: name,
            record: recording,
            timeout: timeout,
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
        device: SnapshotDevice,
        named name: String? = nil,
        record recording: Bool? = nil,
        timeout: TimeInterval = 5,
        fileID: StaticString = #fileID,
        file: StaticString = #filePath,
        testName: String = #function,
        line: UInt = #line,
        column: UInt = #column
    ) {
        switch device {
        case .macOS, .any, .size: ()
        case .iOS:
            // Noop
            return
        }

        let hostingVC = NSHostingController(rootView: view.frame(width: device.width, height: device.height))
        hostingVC.view.frame = CGRect(x: 0, y: 0, width: device.width, height: device.height)
        hostingVC.view.layoutSubtreeIfNeeded()
        assertSnapshot(
            of: hostingVC,
            as: .image,
            named: name,
            record: recording,
            timeout: timeout,
            fileID: fileID,
            file: file,
            testName: "\(testName).\(platformLabel)",
            line: line,
            column: column
        )
    }
#endif
