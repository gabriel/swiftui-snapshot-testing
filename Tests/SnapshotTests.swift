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
        .frame(width: 300, height: 200)
    assertSnapshot(view: view)
}

@Test @MainActor
func testSomeViewRender() throws {
    let view = SomeView()
    assertRender(view: view)
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
