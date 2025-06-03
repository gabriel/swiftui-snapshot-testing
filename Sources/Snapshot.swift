import Foundation
import SnapshotTesting
import SwiftUI
import Testing
#if os(iOS)
    import UIKit
#endif

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
        as: .imageRender,
        fileID: fileID,
        file: file,
        testName: "\(testName).\(platformLabel)",
        line: line,
        column: column
    )
}

@MainActor
var platformLabel: String {
    #if os(macOS)
        return "macOS"
    #elseif os(iOS)
        let device = UIDevice.current
        let modelIdentifier = device.modelIdentifier.replacingOccurrences(of: ",", with: "_")
        let osVersion = device.systemVersion.replacingOccurrences(of: ".", with: "_")
        return "iOS-\(modelIdentifier)-\(osVersion)"
    #else
        return "Unknown"
    #endif
}

#if os(iOS)
    extension UIDevice {
        var modelIdentifier: String {
            #if targetEnvironment(simulator)
                /// Get simulator name from environment
                let simulatorName = ProcessInfo.processInfo.environment["SIMULATOR_DEVICE_NAME"] ?? "Simulator"
                return simulatorName.replacingOccurrences(of: " ", with: "_")
            #else
                var systemInfo = utsname()
                uname(&systemInfo)
                let mirror = Mirror(reflecting: systemInfo.machine)

                return mirror.children.reduce("") { identifier, element in
                    guard let value = element.value as? Int8, value != 0 else { return identifier }
                    return identifier + String(UnicodeScalar(UInt8(value)))
                }
            #endif
        }
    }
#endif
