import CoreGraphics
import Foundation
import SnapshotTesting
import SwiftUISnapshotTesting
import XCTest
#if canImport(AppKit)
    import AppKit
#elseif canImport(UIKit)
    import UIKit
#endif

final class RegionalImageComparisonTests: XCTestCase {
    private func buffer(width: Int = 6, height: Int = 4, stride: Int? = nil,
                        changes: [(Int, Int, Int, UInt8)] = [], padding: UInt8 = 0) throws -> SnapshotPixelBuffer
    {
        let stride = stride ?? width * 4
        var data = Data(repeating: padding, count: stride * height)
        for y in 0 ..< height {
            for x in 0 ..< width {
                for channel in 0 ..< 4 {
                    data[y * stride + x * 4 + channel] = channel == 3 ? 254 : 100
                }
            }
        }
        for (x, y, channel, value) in changes {
            data[y * stride + x * 4 + channel] = value
        }
        return try SnapshotPixelBuffer(width: width, height: height, bytesPerRow: stride, data: data)
    }

    private func region(_ rects: [SnapshotPixelRect], delta: UInt8 = 2, count: Int = 2,
                        alpha: UInt8 = 255) -> SnapshotToleranceRegion
    {
        .init(rectangles: rects, maximumRGBDelta: delta, maximumChangedPixels: count,
              maximumReferenceAlpha: alpha)
    }

    func testExactComparisonAndDimensions() throws {
        let reference = try buffer()
        XCTAssertTrue(try reference.matches(reference))
        XCTAssertFalse(try buffer(changes: [(5, 3, 0, 101)]).matches(reference))
        XCTAssertFalse(try buffer(width: 5).matches(reference))
        XCTAssertFalse(try buffer(height: 3).matches(reference))
    }

    func testRectangleEdgesAndExactGaps() throws {
        let reference = try buffer()
        let regions = [region([.init(x: 1, y: 1, width: 2, height: 2),
                               .init(x: 4, y: 1, width: 1, height: 2)])]
        for (x, y) in [(1, 1), (2, 2), (4, 1), (4, 2)] {
            XCTAssertTrue(try buffer(changes: [(x, y, 0, 102)]).matches(reference, tolerating: regions))
        }
        for (x, y) in [(0, 1), (3, 1), (5, 1), (1, 0), (1, 3), (5, 3)] {
            XCTAssertFalse(try buffer(changes: [(x, y, 0, 101)]).matches(reference, tolerating: regions))
        }
    }

    func testDeltaAndExactAlpha() throws {
        let reference = try buffer()
        let regions = [region([.init(x: 0, y: 0, width: 6, height: 4)])]
        for channel in 0 ..< 3 {
            for value: UInt8 in [98, 102] {
                XCTAssertTrue(try buffer(changes: [(2, 2, channel, value)]).matches(reference, tolerating: regions))
            }
            for value: UInt8 in [97, 103] {
                XCTAssertFalse(try buffer(changes: [(2, 2, channel, value)]).matches(reference, tolerating: regions))
            }
        }
        XCTAssertFalse(try buffer(changes: [(2, 2, 3, 253)]).matches(reference, tolerating: regions))
        let zero = [region([.init(x: 0, y: 0, width: 6, height: 4)], delta: 0)]
        XCTAssertFalse(try buffer(changes: [(2, 2, 0, 101)]).matches(reference, tolerating: zero))
    }

    func testChannelDeltaAcrossEntireByteRange() throws {
        let reference = try SnapshotPixelBuffer(width: 1, height: 1, data: Data([0, 255, 0, 255]))
        let actual = try SnapshotPixelBuffer(width: 1, height: 1, data: Data([255, 0, 255, 255]))
        let rect = SnapshotPixelRect(x: 0, y: 0, width: 1, height: 1)
        XCTAssertTrue(try actual.matches(reference, tolerating: [region([rect], delta: 255, count: 1)]))
        XCTAssertFalse(try actual.matches(reference, tolerating: [region([rect], delta: 254, count: 1)]))
        XCTAssertFalse(try actual.matches(reference, tolerating: [region([rect], delta: 255, alpha: 254)]))
    }

    func testCountsSpanRowsAndDisjointRectangles() throws {
        let reference = try buffer()
        let rects = [SnapshotPixelRect(x: 0, y: 0, width: 2, height: 2),
                     SnapshotPixelRect(x: 4, y: 2, width: 2, height: 2)]
        let changes: [(Int, Int, Int, UInt8)] = [(0, 0, 0, 101), (0, 0, 1, 102), (0, 0, 2, 98), (5, 3, 0, 101)]
        XCTAssertTrue(try buffer(changes: changes).matches(reference, tolerating: [region(rects)]))
        XCTAssertFalse(try buffer(changes: changes + [(1, 1, 0, 101)])
            .matches(reference, tolerating: [region(rects)]))
        XCTAssertFalse(try buffer(changes: [(0, 0, 0, 101)])
            .matches(reference, tolerating: [region(rects, count: 0)]))
    }

    func testUnionCountsEachPixelOnceAndGroupsHaveIndependentLimits() throws {
        let reference = try buffer()
        let first = region([.init(x: 0, y: 0, width: 3, height: 2),
                            .init(x: 1, y: 0, width: 3, height: 2)], count: 1)
        let second = region([.init(x: 4, y: 0, width: 2, height: 2)], delta: 1, count: 1)
        XCTAssertTrue(try buffer(changes: [(1, 0, 0, 102), (5, 0, 0, 101)])
            .matches(reference, tolerating: [second, first]))
        XCTAssertFalse(try buffer(changes: [(1, 0, 0, 102), (5, 0, 0, 102)])
            .matches(reference, tolerating: [first, second]))
    }

    func testAlphaCeilingOnlyRestrictsChangedPixels() throws {
        let reference = try buffer()
        let rect = SnapshotPixelRect(x: 0, y: 0, width: 6, height: 4)
        XCTAssertTrue(try reference.matches(reference, tolerating: [region([rect], alpha: 0)]))
        XCTAssertTrue(try buffer(changes: [(0, 0, 0, 101)]).matches(reference,
                                                                    tolerating: [region([rect], alpha: 254)]))
        XCTAssertFalse(try buffer(changes: [(0, 0, 0, 101)]).matches(reference,
                                                                     tolerating: [region([rect], alpha: 253)]))
    }

    func testPaddingDifferentStridesAndDataSlices() throws {
        let reference = try buffer(stride: 25, padding: 12)
        XCTAssertTrue(try buffer(stride: 25, padding: 23).matches(reference))
        XCTAssertTrue(try buffer(stride: 27, padding: 34).matches(reference))
        let regions = [region([.init(x: 5, y: 3, width: 1, height: 1)])]
        XCTAssertTrue(try buffer(stride: 27, changes: [(5, 3, 0, 102)]).matches(reference, tolerating: regions))
        var prefixed = Data([99, 99, 99])
        prefixed.append(reference.data)
        let sliced = try SnapshotPixelBuffer(width: 6, height: 4, bytesPerRow: 25, data: prefixed[3...])
        XCTAssertTrue(try sliced.matches(reference))
    }

    func testInvalidBuffersRejectOverflowAndIncompleteData() {
        for (width, height, stride) in [(0, 1, 0), (-1, 1, 4), (Int.max, 1, 4),
                                        (1, Int.max, 4), (2, 1, 7), (1, 1, -4), (1, 0, 4)]
        {
            XCTAssertThrowsError(try SnapshotPixelBuffer(width: width, height: height,
                                                         bytesPerRow: stride, data: Data()))
        }
        XCTAssertThrowsError(try SnapshotPixelBuffer(width: 1, height: 1, data: Data(count: 3)))
        XCTAssertThrowsError(try SnapshotPixelBuffer(width: 1, height: 1, data: Data(count: 5)))
    }

    func testInvalidRegionsFailEvenOnIdenticalImages() throws {
        let reference = try buffer()
        for rect in [SnapshotPixelRect(x: -1, y: 0, width: 1, height: 1),
                     .init(x: 0, y: 0, width: 0, height: 1), .init(x: 0, y: 0, width: 1, height: 0),
                     .init(x: 5, y: 3, width: 2, height: 1), .init(x: 5, y: 3, width: 1, height: 2),
                     .init(x: Int.max, y: 0, width: Int.max, height: 1)]
        {
            XCTAssertThrowsError(try reference.matches(reference, tolerating: [region([rect])])) {
                XCTAssertEqual($0 as? SnapshotPixelComparisonError, .invalidRegion(0))
            }
        }
        XCTAssertThrowsError(try reference.matches(reference, tolerating: [region([])]))
        XCTAssertThrowsError(try reference.matches(reference,
                                                   tolerating: [region([.init(x: 0, y: 0, width: 1, height: 1)], count: -1)]))
        let overlap = region([.init(x: 0, y: 0, width: 2, height: 2)])
        XCTAssertThrowsError(try reference.matches(reference, tolerating: [overlap, overlap])) {
            XCTAssertEqual($0 as? SnapshotPixelComparisonError, .overlappingRegions(0, 1))
        }
    }

    /// Independent scalar oracle: visit every pixel and count rectangle membership directly.
    func testDeterministicCasesAgreeWithScalarOracle() throws {
        let reference = try buffer()
        let regions = [region([.init(x: 0, y: 0, width: 3, height: 2),
                               .init(x: 1, y: 1, width: 3, height: 2)], count: 3),
                       region([.init(x: 4, y: 0, width: 2, height: 4)], delta: 1, count: 2)]
        var random: UInt64 = 42
        var accepted = 0
        var rejected = 0
        for _ in 0 ..< 400 {
            var changes: [(Int, Int, Int, UInt8)] = []
            random = random &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
            for _ in 0 ..< Int(random % 6) {
                random = random &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
                changes.append((Int(random >> 32) % 6, Int(random >> 24) % 4,
                                Int(random >> 16) % 4, Int(random >> 16) % 4 == 3 ? 254 : UInt8(98 + (random >> 8) % 5)))
            }
            let actual = try buffer(stride: 27, changes: changes)
            var counts = [0, 0]
            var expected = true
            for y in 0 ..< 4 {
                for x in 0 ..< 6 {
                    let a = Array(actual.data[(y * 27 + x * 4) ..< (y * 27 + x * 4 + 4)])
                    let b = Array(reference.data[(y * 24 + x * 4) ..< (y * 24 + x * 4 + 4)])
                    if a == b {
                        continue
                    }
                    guard let index = regions.firstIndex(where: { region in
                        region.rectangles.contains { x >= $0.x && x < $0.x + $0.width && y >= $0.y && y < $0.y + $0.height }
                    }) else { expected = false
                        continue
                    }
                    let region = regions[index]
                    counts[index] += 1
                    if a[3] != b[3] || b[3] > region.maximumReferenceAlpha
                        || zip(a.prefix(3), b.prefix(3)).contains(where: { abs(Int($0) - Int($1)) > Int(region.maximumRGBDelta) })
                        || counts[index] > region.maximumChangedPixels
                    {
                        expected = false
                    }
                }
            }
            XCTAssertEqual(try actual.matches(reference, tolerating: regions), expected)
            if expected {
                accepted += 1
            } else {
                rejected += 1
            }
        }
        XCTAssertGreaterThan(accepted, 20)
        XCTAssertGreaterThan(rejected, 20)
    }

    func testNativeImageDiffingPreservesPNGAndFailureAttachments() throws {
        func image(_ changes: [(Int, Int, Int, UInt8)] = []) throws -> CGImage {
            let pixels = try buffer(changes: changes)
            return try XCTUnwrap(try CGImage(width: 6, height: 4, bitsPerComponent: 8, bitsPerPixel: 32,
                                             bytesPerRow: 24, space: XCTUnwrap(CGColorSpace(name: CGColorSpace.sRGB)),
                                             bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
                                             provider: CGDataProvider(data: pixels.data as CFData)!, decode: nil,
                                             shouldInterpolate: false, intent: .defaultIntent))
        }
        #if canImport(AppKit)
            func native(_ cgImage: CGImage) -> NSImage {
                NSImage(cgImage: cgImage, size: .init(width: 6, height: 4))
            }
            let strategy = Snapshotting<NSImage, NSImage>.regionalImage(tolerating: [region([.init(x: 1, y: 1, width: 1, height: 1)])])
        #elseif canImport(UIKit)
            func native(_ cgImage: CGImage) -> UIImage {
                UIImage(cgImage: cgImage, scale: 2, orientation: .up)
            }
            let strategy = Snapshotting<UIImage, UIImage>.regionalImage(tolerating: [region([.init(x: 1, y: 1, width: 1, height: 1)])])
        #endif
        let reference = try native(image())
        XCTAssertEqual(strategy.pathExtension, "png")
        XCTAssertNil(try strategy.diffing.diffV2(reference, native(image([(1, 1, 0, 101)]))))
        let failure = try XCTUnwrap(try strategy.diffing.diffV2(reference, native(image([(5, 3, 0, 101)]))))
        XCTAssertTrue(failure.0.contains("regional tolerances"))
        XCTAssertEqual(failure.1.count, 3)
        XCTAssertNil(strategy.diffing.diffV2(reference, strategy.diffing.fromData(strategy.diffing.toData(reference))))
        #if canImport(AppKit)
            let invalid = Diffing<NSImage>.regionalImage(tolerating: [region([])])
        #else
            let invalid = Diffing<UIImage>.regionalImage(tolerating: [region([])])
        #endif
        XCTAssertTrue(try XCTUnwrap(invalid.diffV2(reference, reference)).0.contains("Invalid regional"))
    }
}
