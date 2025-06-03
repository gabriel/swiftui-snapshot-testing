#if canImport(AppKit)
    import AppKit
    import SnapshotTesting
    import SwiftUI

    public extension Snapshotting where Value: SwiftUI.View, Format == NSImage {
        /// A snapshot strategy for comparing SwiftUI Views based on pixel equality using iOS 16 `ImageRenderer`.
        ///
        /// `ImageRenderer` output only includes views that SwiftUI renders, such as text, images, shapes,
        /// and composite views of these types. It does not render views provided by native platform
        /// frameworks (AppKit and UIKit) such as web views, media players, and some controls. For these
        /// views, `ImageRenderer` displays a placeholder image, similar to the behavior of
        /// `drawingGroup(opaque:colorMode:)`.
        @MainActor
        static var imageRender: Snapshotting {
            .imageRender()
        }

        /// A snapshot strategy for comparing SwiftUI Views based on pixel equality using iOS 16 `ImageRenderer`.
        ///
        /// `ImageRenderer` output only includes views that SwiftUI renders, such as text, images, shapes,
        /// and composite views of these types. It does not render views provided by native platform
        /// frameworks (AppKit and UIKit) such as web views, media players, and some controls. For these
        /// views, `ImageRenderer` displays a placeholder image, similar to the behavior of
        /// `drawingGroup(opaque:colorMode:)`.
        ///
        /// - Parameters:
        ///   - precision: The percentage of pixels that must match.
        ///   - perceptualPrecision: The percentage a pixel must match the source pixel to be considered a match. [98-99% mimics the precision of the human eye.](http://zschuessler.github.io/DeltaE/learn/#toc-defining-delta-e)
        @MainActor
        static func imageRender(
            precision: Float = 1,
            perceptualPrecision: Float = 1
        )
            -> Snapshotting
        {
            SimplySnapshotting.image(precision: precision, perceptualPrecision: perceptualPrecision).asyncPullback { view in
                .init { callback in
                    let renderer = ImageRenderer(content: view)
                    renderer.scale = 4.0 // Large to avoid pixelation?
                    callback(renderer.nsImage ?? NSImage())
                }
            }
        }
    }
#endif
