import Foundation
import SwiftUI

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
    import UIKit

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

public enum SnapshotDevice {
    case iOS(width: CGFloat, height: CGFloat)
    case macOS(width: CGFloat, height: CGFloat)
    case size(_ width: CGFloat, _ height: CGFloat)
    case any

    var width: CGFloat {
        switch self {
        case let .iOS(width, _): return width
        case let .macOS(width, _): return width
        case let .size(width, _): return width
        case .any:
            #if os(iOS)
                return 390
            #elseif os(macOS)
                return 1200
            #endif
        }
    }

    var height: CGFloat {
        switch self {
        case let .iOS(_, height): return height
        case let .macOS(_, height): return height
        case let .size(_, height): return height
        case .any:
            #if os(iOS)
                return 844
            #elseif os(macOS)
                return 1000
            #endif
        }
    }
}
