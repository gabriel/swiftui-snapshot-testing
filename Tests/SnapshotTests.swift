import Foundation
import SwiftUI
import SwiftUISnapshotTesting
import Testing

@Test @MainActor
func testTextViewSnapshot() throws {
    let view = Text("Hello, world!")
    assertSnapshot(view: view, device: .size(300, 200))
}

@Test @MainActor
func testTextViewRender() throws {
    let view = Text("Hello, world!")
    assertRender(view: view, device: .size(300, 200))
}

@Test @MainActor
func testSomeLongView() throws {
    let view = VStack {
        ForEach(0 ..< 100) { index in
            Text("Item \(index)")
        }
    }
    assertSnapshot(view: view, device: .iOS(width: 300, height: 2000))
}

@Test @MainActor
func testScrollView() throws {
    let view = ScrollView {}
    assertSnapshot(view: view, device: .macOS(width: 800, height: 600))
}

struct NavigationTestView: View {
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
    let view = NavigationTestView()
    assertSnapshot(view: view, device: .iOS(width: 400, height: 1000))
    assertSnapshot(view: view, device: .macOS(width: 1200, height: 800))
}

@Test @MainActor
func testNavigationStackRender() throws {
    let view = NavigationTestView()
    assertRender(view: view, device: .macOS(width: 1200, height: 800))
}

@Test @MainActor
func testNavigationSplitViewSnapshot() throws {
    let view = SplitTestView()
    assertSnapshot(view: view, device: .iOS(width: 400, height: 1000))
    assertSnapshot(view: view, device: .macOS(width: 1200, height: 800))
}

struct SplitTestView: View {
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

// Run multiple text render tests to ensure the renderer is stable
@Test @MainActor
func testTextRender1() throws {
    let view =
        Text("Iceland wayfarers fam, austin taxidermy pok pok bruh viral try-hard")
            .font(.largeTitle)
            .foregroundColor(.blue)
            .background(.red)
    assertRender(view: view, device: .any)
}

@Test @MainActor
func testTextRender2() throws {
    let view =
        Text("Iceland wayfarers fam, austin taxidermy pok pok bruh viral try-hard")
            .font(.largeTitle)
            .foregroundColor(.blue)
            .background(.red)
    assertRender(view: view, device: .any)
}

@Test @MainActor
func testTextRender3() throws {
    let view =
        Text("Iceland wayfarers fam, austin taxidermy pok pok bruh viral try-hard")
            .font(.largeTitle)
            .foregroundColor(.blue)
            .background(.red)
    assertRender(view: view, device: .any)
}
