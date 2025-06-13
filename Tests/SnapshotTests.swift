import Foundation
import SwiftUI
import SwiftUISnapshotTesting
import Testing

@Test @MainActor
func testTextView() throws {
    let view = Text("Hello, world!")
        .frame(width: 300, height: 200)
    assertSnapshot(view: view)
}

@Test @MainActor
func testTextViewRender() throws {
    let view = Text("Hello, world!")
    assertRender(view: view)
}

@Test @MainActor
func testSomeLongView() throws {
    let view = VStack {
        ForEach(0 ..< 100) { index in
            Text("Item \(index)")
        }
    }
    .frame(width: 300, height: 2000)
    assertSnapshot(view: view)
}

@Test @MainActor
func testScrollView() throws {
    let view = ScrollView {}
    assertSnapshot(view: view)
}

struct NavigationView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text("Hello, world!")
            }
        }
    }
}

@Test @MainActor
func testNavigationStack() throws {
    let view = NavigationView()
        .frame(width: 600, height: 1000)
    assertSnapshot(view: view)
}

@Test @MainActor
func testNavigationStackRender() throws {
    let view = NavigationView()
    assertRender(view: view)
}
