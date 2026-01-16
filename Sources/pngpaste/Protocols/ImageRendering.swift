import AppKit

/// A protocol that defines the interface for rendering images to various output formats.
@MainActor
protocol ImageRendering: Sendable {
  /// Renders an image to the specified output format.
  ///
  /// Converts the provided image to the target format, handling both bitmap and PDF source types
  /// with appropriate rendering strategies. PDF images are rasterized at 2x scale factor for
  /// improved quality.
  ///
  /// - Parameters:
  ///   - image: The source `NSImage` to render.
  ///   - imageType: The classification of the source image (`.bitmap` or `.pdf`), which
  ///     determines the rendering strategy.
  ///   - format: The desired output format (PNG, GIF, JPEG, or TIFF).
  /// - Returns: A `Data` object containing the rendered image in the specified format.
  /// - Throws: `PngPasteError.conversionFailed` if the image cannot be converted to the
  ///   requested format.
  func render(
    _ image: NSImage,
    imageType: ImageType,
    as format: OutputFormat
  ) throws(PngPasteError) -> Data
}
