#if os(macOS)
import AppKit
import SwiftUI

/// Render native SwiftUI/AppKit content at a fixed bitmap scale, independent of
/// the attached display. The size is in points; backingScale defaults to 2.
/// Use the returned bitmap with assertSnapshot(image:) or another image strategy.
@MainActor
public func snapshotImage(view: some View, size: CGSize, backingScale: CGFloat = 2) throws -> NSImage {
    let pixelWidth = size.width * backingScale
    let pixelHeight = size.height * backingScale
    guard backingScale.isFinite, backingScale > 0,
          pixelWidth.isFinite, pixelHeight.isFinite,
          pixelWidth >= 1, pixelHeight >= 1,
          pixelWidth < CGFloat(Int.max), pixelHeight < CGFloat(Int.max) else {
        throw NSError(domain: "SwiftUISnapshotTesting", code: 1,
                      userInfo: [NSLocalizedDescriptionKey: "Snapshot size and backing scale must produce positive, finite bitmap dimensions."])
    }
    let bounds = NSRect(origin: .zero, size: size)
    let host = NSHostingView(rootView: view.frame(width: size.width, height: size.height))
    host.frame = bounds
    host.appearance = NSAppearance(named: .aqua)
    host.wantsLayer = true
    host.layer?.contentsScale = backingScale
    let window = SnapshotWindow(size: size, scale: backingScale)
    window.isReleasedWhenClosed = false
    window.setFrameOrigin(NSPoint(x: -10_000, y: -10_000))
    window.appearance = host.appearance
    window.colorSpace = .sRGB
    window.contentView = host
    defer { window.contentView = nil; window.close() }
    window.layoutIfNeeded()
    host.layoutSubtreeIfNeeded()
    // Allow native controls to finish their initial layout, without waiting for
    // application tasks or changing the caller's async readiness policy.
    RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.05))
    host.layoutSubtreeIfNeeded()
    host.displayIfNeeded()
    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: Int(pixelWidth), pixelsHigh: Int(pixelHeight),
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .calibratedRGB, bytesPerRow: 0, bitsPerPixel: 32) else {
        throw NSError(domain: "SwiftUISnapshotTesting", code: 2,
                      userInfo: [NSLocalizedDescriptionKey: "Could not allocate the snapshot bitmap."])
    }
    bitmap.size = size
    host.cacheDisplay(in: bounds, to: bitmap)
    let image = NSImage(size: size)
    image.addRepresentation(bitmap)
    return image
}

@MainActor private final class SnapshotWindow: NSWindow {
    private let scale: CGFloat
    override var backingScaleFactor: CGFloat { scale }

    init(size: CGSize, scale: CGFloat) {
        self.scale = scale
        super.init(contentRect: NSRect(origin: .zero, size: size), styleMask: [.borderless],
                   backing: .buffered, defer: false)
    }
}
#endif
