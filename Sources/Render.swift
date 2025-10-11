import Foundation
import SnapshotTesting
import SwiftUI

@MainActor
public func assertRender(
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
    #if os(iOS)
        switch device {
        case .iOS, .any, .size: ()
        case .macOS:
            // Noop
            return
        }
    #elseif os(macOS)
        switch device {
        case .macOS, .any, .size: ()
        case .iOS:
            // Noop
            return
        }
    #endif

    assertSnapshot(
        of: view.frame(width: device.width, height: device.height),
        as: .imageRender(precision: 1.0, perceptualPrecision: 0.99), // ImageRenderer is not precise enough
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
