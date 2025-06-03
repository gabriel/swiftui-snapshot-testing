# SwiftUI Snapshot Testing

A Swift package that provides snapshot testing capabilities for SwiftUI views on both iOS and macOS platforms. This package extends the functionality of [swift-snapshot-testing](https://github.com/pointfreeco/swift-snapshot-testing) to make it easier to test SwiftUI views.

## Requirements

- iOS 16.0+ / macOS 15.0+
- Swift 6.0+

## Installation

### Swift Package Manager

Add the following to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/gabriel/swiftui-snapshot-testing", from: "1.0.0")
]
```

### Testing SwiftUI Views

```swift
import SwiftUI
import SwiftUISnapshotTesting
import Testing

@Test @MainActor
func testMyView() throws {
    let view = MyView()
    assertSnapshot(view: view)
}
```

## Features

- Support for both iOS and macOS platforms
- Easy integration with existing snapshot testing workflows
- Automatic handling of SwiftUI view rendering
- Includes model identifier and os version in snapshot file name

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
```
