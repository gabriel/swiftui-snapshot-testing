import CoreGraphics
import SnapshotTesting

private func regionalDiffing<Value>(
    _ standard: Diffing<Value>,
    regions: [SnapshotToleranceRegion],
    cgImage: @escaping (Value) -> CGImage?
) -> Diffing<Value> {
    var diffing = standard
    diffing.diffV2 = { reference, actual in
        guard let referenceImage = cgImage(reference), let actualImage = cgImage(actual) else {
            return ("Regional comparison could not load image pixels.", [])
        }
        do {
            let referencePixels = try SnapshotPixelBuffer(cgImage: referenceImage)
            let actualPixels = try SnapshotPixelBuffer(cgImage: actualImage)
            if try actualPixels.matches(referencePixels, tolerating: regions) {
                return nil
            }
        } catch {
            return ("Invalid regional comparison: \(error)", [])
        }
        // Reuse Point-Free's reference, failure, and difference attachments.
        let failure = standard.diffV2(reference, actual)
        return ("Image exceeds the configured regional tolerances.", failure?.1 ?? [])
    }
    return diffing
}

#if canImport(AppKit)
    import AppKit

    public extension Diffing where Value == NSImage {
        /// Allows bounded RGB differences in bitmap-pixel regions. Alpha and all other pixels stay exact.
        static func regionalImage(tolerating regions: [SnapshotToleranceRegion]) -> Self {
            regionalDiffing(.image, regions: regions) {
                $0.cgImage(forProposedRect: nil, context: nil, hints: nil)
            }
        }
    }

    public extension Snapshotting where Value == NSImage, Format == NSImage {
        static func regionalImage(tolerating regions: [SnapshotToleranceRegion]) -> Self {
            .init(pathExtension: "png", diffing: .regionalImage(tolerating: regions))
        }
    }
#endif

#if canImport(UIKit)
    import UIKit

    public extension Diffing where Value == UIImage {
        /// Regions address the underlying CGImage's bitmap pixels, independent of view points or image scale.
        static func regionalImage(tolerating regions: [SnapshotToleranceRegion]) -> Self {
            regionalDiffing(.image, regions: regions) { $0.cgImage }
        }
    }

    public extension Snapshotting where Value == UIImage, Format == UIImage {
        static func regionalImage(tolerating regions: [SnapshotToleranceRegion]) -> Self {
            .init(pathExtension: "png", diffing: .regionalImage(tolerating: regions))
        }
    }
#endif
