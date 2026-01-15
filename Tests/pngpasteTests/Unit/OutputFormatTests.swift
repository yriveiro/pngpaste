import AppKit
@testable import pngpaste
import Testing

@Suite("OutputFormat Tests")
struct OutputFormatTests {
    // MARK: - Init from Extension

    @Test("Init from extension .png")
    func initFromExtension_png() {
        let format = OutputFormat(fromExtension: "png")
        #expect(format == .png)
    }

    @Test("Init from extension .PNG (uppercase)")
    func initFromExtension_pngUppercase() {
        let format = OutputFormat(fromExtension: "PNG")
        #expect(format == .png)
    }

    @Test("Init from extension .jpg")
    func initFromExtension_jpg() {
        let format = OutputFormat(fromExtension: "jpg")
        #expect(format == .jpeg)
    }

    @Test("Init from extension .jpeg")
    func initFromExtension_jpeg() {
        let format = OutputFormat(fromExtension: "jpeg")
        #expect(format == .jpeg)
    }

    @Test("Init from extension .gif")
    func initFromExtension_gif() {
        let format = OutputFormat(fromExtension: "gif")
        #expect(format == .gif)
    }

    @Test("Init from extension .tif")
    func initFromExtension_tif() {
        let format = OutputFormat(fromExtension: "tif")
        #expect(format == .tiff)
    }

    @Test("Init from extension .tiff")
    func initFromExtension_tiff() {
        let format = OutputFormat(fromExtension: "tiff")
        #expect(format == .tiff)
    }

    @Test("Init from unknown extension defaults to PNG")
    func initFromExtension_unknownDefaultsToPng() {
        let format = OutputFormat(fromExtension: "xyz")
        #expect(format == .png)
    }

    @Test("Init from empty extension defaults to PNG")
    func initFromExtension_emptyDefaultsToPng() {
        let format = OutputFormat(fromExtension: "")
        #expect(format == .png)
    }

    // MARK: - Init from Filename

    @Test("Init from filename with path")
    func initFromFilename() {
        let format = OutputFormat(fromFilename: "/path/to/image.jpeg")
        #expect(format == .jpeg)
    }

    @Test("Init from filename without extension defaults to PNG")
    func initFromFilename_noExtensionDefaultsToPng() {
        let format = OutputFormat(fromFilename: "/path/to/image")
        #expect(format == .png)
    }

    // MARK: - Bitmap Type

    @Test("Bitmap type for PNG")
    func bitmapType_png() {
        #expect(OutputFormat.png.bitmapType == .png)
    }

    @Test("Bitmap type for GIF")
    func bitmapType_gif() {
        #expect(OutputFormat.gif.bitmapType == .gif)
    }

    @Test("Bitmap type for JPEG")
    func bitmapType_jpeg() {
        #expect(OutputFormat.jpeg.bitmapType == .jpeg)
    }

    @Test("Bitmap type for TIFF")
    func bitmapType_tiff() {
        #expect(OutputFormat.tiff.bitmapType == .tiff)
    }

    // MARK: - Encoding Properties

    @Test("JPEG encoding properties include compression")
    func encodingProperties_jpegHasCompression() {
        let props = OutputFormat.jpeg.encodingProperties
        #expect(props[.compressionFactor] as? Double == 0.9)
    }

    @Test("PNG encoding properties are empty")
    func encodingProperties_pngIsEmpty() {
        #expect(OutputFormat.png.encodingProperties.isEmpty)
    }

    @Test("GIF encoding properties are empty")
    func encodingProperties_gifIsEmpty() {
        #expect(OutputFormat.gif.encodingProperties.isEmpty)
    }

    @Test("TIFF encoding properties are empty")
    func encodingProperties_tiffIsEmpty() {
        #expect(OutputFormat.tiff.encodingProperties.isEmpty)
    }

    // MARK: - Display Name

    @Test("Display names are correct")
    func displayName() {
        #expect(OutputFormat.png.displayName == "PNG")
        #expect(OutputFormat.jpeg.displayName == "JPEG")
        #expect(OutputFormat.gif.displayName == "GIF")
        #expect(OutputFormat.tiff.displayName == "TIFF")
    }

    // MARK: - CaseIterable

    @Test("CaseIterable contains all formats")
    func caseIterableContainsAllFormats() {
        let allCases = OutputFormat.allCases
        #expect(allCases.count == 4)
        #expect(allCases.contains(.png))
        #expect(allCases.contains(.gif))
        #expect(allCases.contains(.jpeg))
        #expect(allCases.contains(.tiff))
    }
}
