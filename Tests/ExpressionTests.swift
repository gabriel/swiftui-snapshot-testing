import Foundation
import SwiftUI
import SwiftUISnapshotTesting
import Testing

struct MyView: View {
    @State var model: MyViewModel

    var body: some View {
        if model.loaded {
            Text("Loaded")
        } else {
            Text("Loading")
                .task {
                    try? await model.load()
                }
        }
    }
}

@MainActor
class MyViewModel: ObservableObject {
    @Published var loaded = false

    func load() async throws {
        try await Task.sleep(for: .milliseconds(100))
        loaded = true
    }
}

@Test
func testAsyncTask() async throws {
    let model = await MyViewModel()
    let view = MyView(model: model)

    // Loading
    await assertRender(view: view)

    try #require(await expression { model.loaded })

    // Loaded
    await assertRender(view: view)
}
