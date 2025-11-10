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

        let size = CGSize(width: device.width, height: device.height)
        let hostingView = NSHostingView(rootView: view.frame(width: size.width, height: size.height))
        hostingView.setFrameSize(size)
        // Force light appearance to avoid dark mode issues
        if let lightAppearance = NSAppearance(named: .aqua) {
            hostingView.appearance = lightAppearance
        }
        hostingView.layoutSubtreeIfNeeded()
        assertSnapshot(
            of: hostingView,
            as: .image(size: size),
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
