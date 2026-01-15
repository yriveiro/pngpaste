import AppKit

/// A protocol that defines the interface for reading image data from the system clipboard.
protocol ClipboardReading: Sendable {
    /// Reads and returns an image from the system pasteboard.
    ///
    /// This method attempts to retrieve image data from the general pasteboard, supporting
    /// multiple image formats including PNG, TIFF, HEIC, JPEG, GIF, and PDF.
    ///
    /// - Returns: An `NSImage` instance containing the clipboard image data.
    /// - Throws: `PngPasteError.noImageOnClipboard` if no valid image is available on the clipboard.
    func readImage() throws(PngPasteError) -> NSImage

    /// Determines the image type classification for the given image.
    ///
    /// Analyzes the image representations to classify the image as either a bitmap or PDF type,
    /// which determines the appropriate rendering strategy.
    ///
    /// - Parameter image: The `NSImage` to analyze.
    /// - Returns: An `ImageType` value indicating whether the image is `.bitmap` or `.pdf`.
    /// - Throws: `PngPasteError.unsupportedImageFormat` if the image format cannot be determined
    ///   or is not supported.
    func imageType(for image: NSImage) throws(PngPasteError) -> ImageType
}
