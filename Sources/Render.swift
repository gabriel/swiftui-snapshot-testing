import Foundation
import SnapshotTesting
import SwiftUI

@MainActor
public func assertRender(
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
