import Foundation
import SwiftUI
import SwiftUISnapshotTesting
import Testing

@Test @MainActor
func testTextViewSnapshot() throws {
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

#if os(macOS)
    @Test @MainActor
    func testScrollView() throws {
        let view = ScrollView {}
        assertSnapshot(view: view)
    }
#endif

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
func testNavigationStackSnapshot() throws {
    let view = NavigationView()
        .frame(width: 600, height: 1000)
    assertSnapshot(view: view)
}

@Test @MainActor
func testNavigationStackRender() throws {
    let view = NavigationView()
    assertRender(view: view)
}

@Test @MainActor
func testNavigationSplitViewSnapshot() throws {
    let view = SplitView()
        .frame(width: 1000, height: 1000)
    assertSnapshot(view: view)
}

// Render is not supported on UIKit views
// @Test @MainActor
// func testNavigationSplitViewRender() throws {
//     let view = SplitView()
//         .frame(width: 1000, height: 1000)
//     assertRender(view: view)
// }

struct SplitView: View {
    var body: some View {
        NavigationSplitView {
            Text("Sidebar")
        } content: {
            ScrollView {
                Spacer()
                Text("Content")
                Spacer()
            }
        } detail: {
            VStack {
                Text("Detail")
            }
        }
    }
}
