import AppKit

/// A service that reads image data from the macOS system pasteboard.
///
/// Supports reading images in PNG, TIFF, HEIC, JPEG, GIF, and PDF formats from
/// the general pasteboard, with automatic format detection.
struct ClipboardService: ClipboardReading {
  private static let supportedTypes: [NSPasteboard.PasteboardType] = [
    .png,
    .tiff,
    NSPasteboard.PasteboardType("public.heic"),
    NSPasteboard.PasteboardType("public.jpeg"),
    NSPasteboard.PasteboardType("com.compuserve.gif"),
    .pdf,
  ]

  /// Reads and returns an image from the system pasteboard.
  ///
  /// Attempts to read image data from the general pasteboard using a prioritized list of
  /// supported pasteboard types. Falls back to generic image type detection if direct
  /// type matching fails.
  ///
  /// - Returns: An `NSImage` instance containing the clipboard image data.
  /// - Throws: `PngPasteError.noImageOnClipboard` if no valid image is available on the clipboard.
  func readImage() throws(PngPasteError) -> NSImage {
    let pasteboard = NSPasteboard.general

    if let availableType = pasteboard.availableType(from: Self.supportedTypes),
      let data = pasteboard.data(forType: availableType),
      let image = NSImage(data: data),
      isValidImage(image)
    {
      return image
    }

    if pasteboard.canReadItem(withDataConformingToTypes: NSImage.imageTypes),
      let image = NSImage(pasteboard: pasteboard),
      isValidImage(image)
    {
      return image
    }

    throw .noImageOnClipboard
  }

  /// Determines the image type classification for the given image.
  ///
  /// Inspects the image's representations to determine whether it should be treated
  /// as a bitmap or PDF image. PDF images require special rasterization during rendering.
  ///
  /// - Parameter image: The `NSImage` to analyze.
  /// - Returns: `.pdf` if the image contains a PDF representation, `.bitmap` otherwise.
  /// - Throws: `PngPasteError.unsupportedImageFormat` if the image is invalid or its format
  ///   cannot be determined.
  func imageType(for image: NSImage) throws(PngPasteError) -> ImageType {
    guard isValidImage(image) else {
      throw .unsupportedImageFormat
    }

    if image.representations.contains(where: { $0 is NSPDFImageRep }) {
      return .pdf
    }

    if image.representations.contains(where: { $0 is NSBitmapImageRep }) {
      return .bitmap
    }

    if image.tiffRepresentation != nil {
      return .bitmap
    }

    throw .unsupportedImageFormat
  }

  private func isValidImage(_ image: NSImage) -> Bool {
    image.size.width > 0 && image.size.height > 0 && !image.representations.isEmpty
  }
}
