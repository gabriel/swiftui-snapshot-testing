import Foundation
import SnapshotTesting
import SwiftUI

@MainActor
public func assertRender(
    view: some View,
    device: SnapshotDevice,
    fileID: StaticString = #fileID,
    file: StaticString = #filePath,
    testName: String = #function,
    line: UInt = #line,
    column: UInt = #column
) {
    #if os(iOS)
        switch device {
        case .iOS: ()
        case .any: ()
        default:
            // Noop
            return
        }
    #elseif os(macOS)
        switch device {
        case .macOS: ()
        case .any: ()
        default:
            // Noop
            return
        }
    #endif

    assertSnapshot(
        of: view.frame(width: device.width, height: device.height),
        as: .imageRender,
        fileID: fileID,
        file: file,
        testName: "\(testName).\(platformLabel)",
        line: line,
        column: column
    )
}
