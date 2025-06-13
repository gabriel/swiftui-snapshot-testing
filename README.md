# SwiftUI Snapshot Testing

A Swift package that provides snapshot testing capabilities for SwiftUI views on both iOS and macOS platforms. This package extends the functionality of [swift-snapshot-testing](https://github.com/pointfreeco/swift-snapshot-testing) to make it easier to test cross platform SwiftUI views.

- For pure SwiftUI views use `assertRender(view: view)`.
- For UIKit based SwiftUI views, use `assertSnapshot(view: view)`.
- To wait for view tasks, use `try #require(await expression { model.loaded })`

## Requirements

- iOS 16.0+ / macOS 15.0+
- Swift 6.0+

## Installation

### Swift Package Manager

Add the following to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/gabriel/swiftui-snapshot-testing", from: "0.1.1")
]

.testTarget(
    dependencies: [
        .product(name: "SwiftUISnapshotTesting", package: "swiftui-snapshot-testing"),
    ]
)
```

### Testing SwiftUI Views

```swift
import SwiftUI
import SwiftUISnapshotTesting
import Testing

// To test pure SwiftUI view, use assertRender (which uses ImageRenderer).
@Test @MainActor
func testMyViewRender() throws {
    let view = MyView()
    assertRender(view: view)
}

// To test SwiftUI views that wrap UIKit, you can't use assertRender, so use assertSnapshot.
@Test @MainActor
func testMyViewSnapshot() throws {
    let view = NavigationStack {
        MyView()
    }
    .frame(width: 300, height: 200)
    assertSnapshot(view: view)
}
```

### Testing with Async Tasks

```swift
@Test
func testAsyncTask() async throws {
  let model = await MyViewModel()
  let view = MyView(model: model)

  // Loading
  await assertRender(view: view)
 
  // Wait for model load
  try #require(await expression { model.loaded })

  // Loaded
  await assertRender(view: view)
}
```

## Features

- Support for both iOS and macOS platforms, via `swift test` and `xcodebuild test`.
- Async expectation/wait for View tasks.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Test

```sh
swift test
```

```sh
xcodebuild test -scheme SwiftUISnapshotTesting -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.5'
# Or
swift test --ios # With zsh plugin below
```

## ZSH plugin for `swift test --ios`

```sh
mkdir -p ~/.oh-my-zsh/custom/plugins/swift-ios-test
cp swift-ios-test.plugin.zsh ~/.oh-my-zsh/custom/plugins/swift-ios-test/swift-ios-test.plugin.zsh

# Add swift-ios-test to .zshrc
# plugins=(git swift-ios-test ...)

source ~/.zshrc
```

Then..

```sh
swift test --ios
```
