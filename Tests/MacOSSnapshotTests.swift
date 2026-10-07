#if os(macOS)
import AppKit
import SwiftUI
import SwiftUISnapshotTesting
import Testing

@MainActor
@Suite(.snapshots(record: .never))
struct MacOSSnapshotTests {
    @Test(arguments: [CGFloat(1), CGFloat(2)])
    func nativeContentUsesRequestedScale(scale: CGFloat) throws {
        let observation = WindowObservation()
        let image = try snapshotImage(view: NativeProbe(observation: observation),
                                      size: CGSize(width: 40, height: 30), backingScale: scale)
        let pixels = try #require(image.cgImage(forProposedRect: nil, context: nil, hints: nil))
        #expect(pixels.width == Int(40 * scale))
        #expect(pixels.height == Int(30 * scale))
        #expect(observation.scale == scale)
        let color = try #require(NSBitmapImageRep(cgImage: pixels)
            .colorAt(x: pixels.width / 2, y: pixels.height / 2)?.usingColorSpace(.deviceRGB))
        #expect(color.redComponent > 0.99 && color.greenComponent > 0.99 && color.blueComponent > 0.99)
        #expect(color.alphaComponent == 1)
    }

    @Test(arguments: [CGFloat(0), -1, .nan, .infinity])
    func rejectsInvalidScale(scale: CGFloat) {
        #expect(throws: (any Error).self) {
            try snapshotImage(view: Color.red, size: CGSize(width: 40, height: 30), backingScale: scale)
        }
    }

    @Test
    func comparesExistingBitmapWithoutResampling() throws {
        let bitmap = try #require(NSBitmapImageRep(
            bitmapDataPlanes: nil, pixelsWide: 12, pixelsHigh: 12,
            bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
            colorSpaceName: .deviceRGB, bytesPerRow: 48, bitsPerPixel: 32))
        bitmap.size = CGSize(width: 4, height: 4)
        let bytes = try #require(bitmap.bitmapData)
        for y in 0..<12 {
            for x in 0..<12 {
                let offset = y * bitmap.bytesPerRow + x * 4
                for channel in 0..<3 { bytes[offset + channel] = (x + y) % 2 == 0 ? 0 : 255 }
                bytes[offset + 3] = 255
            }
        }
        let image = NSImage(size: bitmap.size)
        image.addRepresentation(bitmap)
        // A second host would resample this 3x bitmap at the display's 1x/2x scale.
        assertSnapshot(image: image, record: false)
    }
}

@MainActor private final class WindowObservation {
    var scale: CGFloat?
}

@MainActor private struct NativeProbe: NSViewRepresentable {
    let observation: WindowObservation
    func makeNSView(context: Context) -> ProbeView { ProbeView(observation: observation) }
    func updateNSView(_ view: ProbeView, context: Context) {}
}

@MainActor private final class ProbeView: NSView {
    let observation: WindowObservation
    init(observation: WindowObservation) {
        self.observation = observation
        super.init(frame: .zero)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) is unsupported") }
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if let window { observation.scale = window.backingScaleFactor }
    }
    override func draw(_ dirtyRect: NSRect) {
        NSColor.white.setFill()
        NSBezierPath(rect: bounds).fill()
    }
}
#endif
