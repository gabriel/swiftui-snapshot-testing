import CoreGraphics
import Foundation

/// An integer rectangle in bitmap pixels, with an exclusive right and bottom edge.
public struct SnapshotPixelRect: Sendable {
    public let x: Int
    public let y: Int
    public let width: Int
    public let height: Int

    public init(x: Int, y: Int, width: Int, height: Int) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }
}

/// A tolerance shared by one or more pixel rectangles. Pixels elsewhere must match exactly.
public struct SnapshotToleranceRegion: Sendable {
    public let rectangles: [SnapshotPixelRect]
    public let maximumRGBDelta: UInt8
    public let maximumChangedPixels: Int
    public let maximumReferenceAlpha: UInt8

    /// Alpha always matches exactly. The alpha ceiling applies only to changed pixels.
    /// Overlapping rectangles within this region form a union and count each pixel once.
    public init(
        rectangles: [SnapshotPixelRect],
        maximumRGBDelta: UInt8,
        maximumChangedPixels: Int,
        maximumReferenceAlpha: UInt8 = 255
    ) {
        self.rectangles = rectangles
        self.maximumRGBDelta = maximumRGBDelta
        self.maximumChangedPixels = maximumChangedPixels
        self.maximumReferenceAlpha = maximumReferenceAlpha
    }
}

public enum SnapshotPixelComparisonError: Error, Equatable, Sendable {
    case invalidPixelBuffer
    case invalidRegion(Int)
    case overlappingRegions(Int, Int)
    case imageConversionFailed
}

/// RGBA8 pixels. Both buffers must use the same color space and alpha representation.
/// Row padding is excluded from comparison; different row strides are supported.
public struct SnapshotPixelBuffer: Sendable {
    public let width: Int
    public let height: Int
    public let bytesPerRow: Int
    public let data: Data

    public init(width: Int, height: Int, bytesPerRow: Int? = nil, data: Data) throws {
        let layout = try Self.layout(width: width, height: height, bytesPerRow: bytesPerRow)
        guard data.count == layout.count else { throw SnapshotPixelComparisonError.invalidPixelBuffer }
        self.width = width
        self.height = height
        self.bytesPerRow = layout.stride
        self.data = data
    }

    /// Normalizes an image to sRGB, premultiplied RGBA8, at its original pixel dimensions.
    public init(cgImage: CGImage) throws {
        let layout = try Self.layout(width: cgImage.width, height: cgImage.height, bytesPerRow: nil)
        var data = Data(count: layout.count)
        let rendered = data.withUnsafeMutableBytes { bytes in
            guard let context = CGContext(
                data: bytes.baseAddress,
                width: cgImage.width,
                height: cgImage.height,
                bitsPerComponent: 8,
                bytesPerRow: layout.stride,
                space: CGColorSpace(name: CGColorSpace.sRGB)!,
                bitmapInfo: CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue
            ) else { return false }
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height))
            return true
        }
        guard rendered else { throw SnapshotPixelComparisonError.imageConversionFailed }
        try self.init(width: cgImage.width, height: cgImage.height, data: data)
    }

    /// Uses bulk comparisons outside permitted regions, and byte loops within changed regions.
    /// Region rectangles are in bitmap pixels. Different regions must not overlap.
    /// Invalid buffer/region configuration throws; a visual difference returns `false`.
    public func matches(_ reference: Self, tolerating regions: [SnapshotToleranceRegion] = []) throws -> Bool {
        try validate(regions)
        guard width == reference.width, height == reference.height else { return false }
        return data.withUnsafeBytes { actualBytes in
            reference.data.withUnsafeBytes { referenceBytes in
                // Nonempty, complete buffers were checked by the initializer. Pointers stay borrowed.
                let actual = actualBytes.bindMemory(to: UInt8.self).baseAddress!
                let expected = referenceBytes.bindMemory(to: UInt8.self).baseAddress!
                if bytesPerRow == reference.bytesPerRow,
                   memcmp(actual, expected, data.count) == 0
                {
                    return true
                }

                var counts = [Int](repeating: 0, count: regions.count)
                let pixelBytes = width * 4
                var y = 0
                while y < height {
                    defer { y += 1 }
                    let actualRow = actual.advanced(by: y * bytesPerRow)
                    let expectedRow = expected.advanced(by: y * reference.bytesPerRow)
                    if memcmp(actualRow, expectedRow, pixelBytes) == 0 {
                        continue
                    }

                    let spans = spans(at: y, regions: regions)
                    var cursor = 0
                    for span in spans {
                        // Every gap, including the final gap, remains an exact comparison.
                        if memcmp(actualRow.advanced(by: cursor * 4), expectedRow.advanced(by: cursor * 4),
                                  (span.start - cursor) * 4) != 0
                        {
                            return false
                        }
                        cursor = span.end
                        if memcmp(actualRow.advanced(by: span.start * 4), expectedRow.advanced(by: span.start * 4),
                                  (span.end - span.start) * 4) == 0
                        {
                            continue
                        }

                        let region = regions[span.region]
                        var x = span.start
                        while x < span.end {
                            defer { x += 1 }
                            let offset = x * 4
                            if actualRow[offset] == expectedRow[offset],
                               actualRow[offset + 1] == expectedRow[offset + 1],
                               actualRow[offset + 2] == expectedRow[offset + 2],
                               actualRow[offset + 3] == expectedRow[offset + 3]
                            {
                                continue
                            }
                            guard actualRow[offset + 3] == expectedRow[offset + 3],
                                  expectedRow[offset + 3] <= region.maximumReferenceAlpha else { return false }
                            var channel = 0
                            while channel < 3 {
                                if abs(Int(actualRow[offset + channel]) - Int(expectedRow[offset + channel]))
                                    > Int(region.maximumRGBDelta)
                                {
                                    return false
                                }
                                channel += 1
                            }
                            counts[span.region] += 1
                            if counts[span.region] > region.maximumChangedPixels {
                                return false
                            }
                        }
                    }
                    if memcmp(actualRow.advanced(by: cursor * 4), expectedRow.advanced(by: cursor * 4),
                              pixelBytes - cursor * 4) != 0
                    {
                        return false
                    }
                }
                return true
            }
        }
    }

    private static func layout(width: Int, height: Int, bytesPerRow: Int?) throws -> (stride: Int, count: Int) {
        let (pixelBytes, widthOverflow) = width.multipliedReportingOverflow(by: 4)
        let stride = bytesPerRow ?? pixelBytes
        let (count, countOverflow) = stride.multipliedReportingOverflow(by: height)
        guard width > 0, height > 0, !widthOverflow, stride >= pixelBytes, !countOverflow else {
            throw SnapshotPixelComparisonError.invalidPixelBuffer
        }
        return (stride, count)
    }

    private func validate(_ regions: [SnapshotToleranceRegion]) throws {
        for (index, region) in regions.enumerated() {
            guard region.maximumChangedPixels >= 0, !region.rectangles.isEmpty else {
                throw SnapshotPixelComparisonError.invalidRegion(index)
            }
            for rect in region.rectangles {
                guard rect.x >= 0, rect.y >= 0, rect.width > 0, rect.height > 0,
                      rect.x <= width, rect.y <= height,
                      rect.width <= width - rect.x, rect.height <= height - rect.y
                else {
                    throw SnapshotPixelComparisonError.invalidRegion(index)
                }
            }
        }
        for first in regions.indices {
            for second in regions.indices where second > first {
                for a in regions[first].rectangles {
                    for b in regions[second].rectangles {
                        if a.x < b.x + b.width, b.x < a.x + a.width,
                           a.y < b.y + b.height, b.y < a.y + a.height
                        {
                            throw SnapshotPixelComparisonError.overlappingRegions(first, second)
                        }
                    }
                }
            }
        }
    }

    private struct Span {
        var start: Int
        var end: Int
        let region: Int
    }

    private func spans(at y: Int, regions: [SnapshotToleranceRegion]) -> [Span] {
        var spans: [Span] = []
        for (index, region) in regions.enumerated() {
            for rect in region.rectangles where y >= rect.y && y < rect.y + rect.height {
                spans.append(Span(start: rect.x, end: rect.x + rect.width, region: index))
            }
        }
        spans.sort { $0.start < $1.start }
        var merged: [Span] = []
        for span in spans {
            if let last = merged.last, last.region == span.region, span.start <= last.end {
                merged[merged.count - 1].end = max(last.end, span.end)
            } else {
                merged.append(span)
            }
        }
        return merged
    }
}
