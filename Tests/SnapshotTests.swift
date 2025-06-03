import Foundation
import SwiftUI
import SwiftUISnapshotTesting
import Testing

struct SomeView: View {
    var body: some View {
        Text("Hello, world!")
    }
}

@Test @MainActor
func testSomeView() throws {
    let view = SomeView()
    assertSnapshot(view: view)
}
