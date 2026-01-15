import AppKit
@testable import pngpaste
import Testing

@Suite("ClipboardService Tests")
struct ClipboardServiceTests {
    let service = ClipboardService()

    @Test("imageType returns bitmap for bitmap image")
    func imageTypeReturnsBitmapForBitmapImage() throws {
        let image = TestImageFactory.createBitmapImage()
        let type = try service.imageType(for: image)
        #expect(type == .bitmap)
    }

    @Test("imageType returns PDF for PDF image")
    func imageTypeReturnsPdfForPDFImage() throws {
        let image = TestImageFactory.createPDFImage()
        let type = try service.imageType(for: image)
        #expect(type == .pdf)
    }

    @Test("imageType throws for zero-size image")
    func imageTypeThrowsForZeroSizeImage() {
        let image = TestImageFactory.createInvalidImage()
        #expect(throws: PngPasteError.unsupportedImageFormat) {
            try service.imageType(for: image)
        }
    }

    @Test("ImageType enum has bitmap case")
    func imageTypeEnumHasBitmapCase() {
        let type = ImageType.bitmap
        #expect(type == .bitmap)
    }

    @Test("ImageType enum has PDF case")
    func imageTypeEnumHasPdfCase() {
        let type = ImageType.pdf
        #expect(type == .pdf)
    }

    @Test("ImageType conforms to Sendable")
    func imageTypeConformsToSendable() {
        let type: Sendable = ImageType.bitmap
        #expect(type is ImageType)
    }
}
