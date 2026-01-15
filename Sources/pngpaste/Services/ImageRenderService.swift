import AppKit

/// A service that renders images to various output formats.
///
/// Handles both bitmap and PDF source images, using appropriate rendering strategies
/// for each type. PDF images are rasterized at 2x scale factor for improved quality.
@MainActor
struct ImageRenderService: ImageRendering {
    private let pdfScaleFactor: CGFloat = 2.0

    /// Renders an image to the specified output format.
    ///
    /// Routes the image to the appropriate rendering method based on the source image type.
    /// Bitmap images are converted directly, while PDF images are first rasterized.
    ///
    /// - Parameters:
    ///   - image: The source `NSImage` to render.
    ///   - imageType: The classification of the source image, determining the rendering strategy.
    ///   - format: The target output format.
    /// - Returns: A `Data` object containing the rendered image bytes.
    /// - Throws: `PngPasteError.conversionFailed` if the rendering process fails.
    func render(
        _ image: NSImage,
        imageType: ImageType,
        as format: OutputFormat
    ) throws(PngPasteError) -> Data {
        let data: Data? = switch imageType {
        case .bitmap:
            renderBitmap(image, as: format)
        case .pdf:
            renderPDF(image, as: format)
        }

        guard let data else {
            throw .conversionFailed(format: format.displayName)
        }

        return data
    }

    /// Renders a bitmap image to the specified output format.
    ///
    /// First attempts direct representation conversion for efficiency. If that fails,
    /// falls back to creating a bitmap representation from the image's TIFF data.
    ///
    /// - Parameters:
    ///   - image: The bitmap `NSImage` to render.
    ///   - format: The target output format.
    /// - Returns: A `Data` object containing the rendered image, or `nil` if rendering fails.
    private func renderBitmap(_ image: NSImage, as format: OutputFormat) -> Data? {
        if let data = NSBitmapImageRep.representationOfImageReps(
            in: image.representations,
            using: format.bitmapType,
            properties: format.encodingProperties
        ), !data.isEmpty {
            return data
        }

        guard let tiffData = image.tiffRepresentation,
              let bitmapRep = NSBitmapImageRep(data: tiffData)
        else {
            return nil
        }

        return bitmapRep.representation(using: format.bitmapType, properties: format.encodingProperties)
    }

    /// Renders a PDF image to the specified output format by rasterizing it.
    ///
    /// Creates a bitmap representation at 2x the PDF's native resolution, draws the PDF
    /// content onto a white background, and encodes the result in the target format.
    ///
    /// - Parameters:
    ///   - image: The PDF `NSImage` to render.
    ///   - format: The target output format.
    /// - Returns: A `Data` object containing the rasterized image, or `nil` if rendering fails.
    private func renderPDF(_ image: NSImage, as format: OutputFormat) -> Data? {
        guard let pdfRep = image.representations.compactMap({ $0 as? NSPDFImageRep }).first else {
            return nil
        }

        let scaledWidth = Int(pdfRep.bounds.width * pdfScaleFactor)
        let scaledHeight = Int(pdfRep.bounds.height * pdfScaleFactor)

        guard scaledWidth > 0, scaledHeight > 0 else {
            return nil
        }

        guard let bitmapRep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: scaledWidth,
            pixelsHigh: scaledHeight,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ) else {
            return nil
        }

        NSGraphicsContext.saveGraphicsState()
        defer { NSGraphicsContext.restoreGraphicsState() }

        guard let context = NSGraphicsContext(bitmapImageRep: bitmapRep) else {
            return nil
        }

        NSGraphicsContext.current = context

        NSColor.white.setFill()
        NSRect(x: 0, y: 0, width: scaledWidth, height: scaledHeight).fill()

        let drawRect = NSRect(x: 0, y: 0, width: scaledWidth, height: scaledHeight)
        pdfRep.draw(in: drawRect)

        return bitmapRep.representation(using: format.bitmapType, properties: format.encodingProperties)
    }
}
