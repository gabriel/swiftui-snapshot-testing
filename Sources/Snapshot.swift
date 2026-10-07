import Foundation
import SnapshotTesting
import SwiftUI
#if os(macOS)
    import AppKit
#endif

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
            record: recording.map { $0 ? SnapshotTestingConfiguration.Record.all : .missing },
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
        backingScale: CGFloat = 2,
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

        assertSnapshot(
            image: try snapshotImage(view: view, size: CGSize(width: device.width, height: device.height),
                                     backingScale: backingScale),
            named: name,
            record: recording,
            timeout: timeout,
            fileID: fileID,
            file: file,
            testName: testName,
            line: line,
            column: column
        )
    }

    /// Compare an existing bitmap without hosting or resampling it.
    @MainActor
    public func assertSnapshot(
        image: @autoclosure () throws -> NSImage,
        named name: String? = nil,
        record recording: Bool? = nil,
        timeout: TimeInterval = 5,
        fileID: StaticString = #fileID,
        file: StaticString = #filePath,
        testName: String = #function,
        line: UInt = #line,
        column: UInt = #column
    ) {
        SnapshotTesting.assertSnapshot(
            of: try image(), as: .image, named: name,
            record: recording.map { $0 ? SnapshotTestingConfiguration.Record.all : .missing },
            timeout: timeout, fileID: fileID, file: file,
            testName: "\(testName).\(platformLabel)", line: line, column: column)
    }
#endif
