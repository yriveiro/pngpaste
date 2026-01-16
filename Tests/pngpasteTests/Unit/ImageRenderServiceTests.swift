import AppKit
import Testing

@testable import pngpaste

@Suite("ImageRenderService Tests")
@MainActor
struct ImageRenderServiceTests {
  let service = ImageRenderService()

  @Test("Render bitmap to PNG produces valid data")
  func renderBitmapToPngProducesValidData() throws {
    let image = TestImageFactory.createBitmapImage()
    let data = try service.render(image, imageType: .bitmap, as: .png)
    #expect(!data.isEmpty)
  }

  @Test("Render bitmap to JPEG produces valid data")
  func renderBitmapToJpegProducesValidData() throws {
    let image = TestImageFactory.createBitmapImage()
    let data = try service.render(image, imageType: .bitmap, as: .jpeg)
    #expect(!data.isEmpty)
  }

  @Test("Render bitmap to GIF produces valid data")
  func renderBitmapToGifProducesValidData() throws {
    let image = TestImageFactory.createBitmapImage()
    let data = try service.render(image, imageType: .bitmap, as: .gif)
    #expect(!data.isEmpty)
  }

  @Test("Render bitmap to TIFF produces valid data")
  func renderBitmapToTiffProducesValidData() throws {
    let image = TestImageFactory.createBitmapImage()
    let data = try service.render(image, imageType: .bitmap, as: .tiff)
    #expect(!data.isEmpty)
  }

  @Test("Render PDF to PNG produces valid data")
  func renderPdfToPngProducesValidData() throws {
    let image = TestImageFactory.createPDFImage()
    let data = try service.render(image, imageType: .pdf, as: .png)
    #expect(!data.isEmpty)
  }

  @Test("Render PDF to JPEG produces valid data")
  func renderPdfToJpegProducesValidData() throws {
    let image = TestImageFactory.createPDFImage()
    let data = try service.render(image, imageType: .pdf, as: .jpeg)
    #expect(!data.isEmpty)
  }

  @Test("Render bitmap to all formats", arguments: OutputFormat.allCases)
  func renderBitmapToAllFormats(format: OutputFormat) throws {
    let image = TestImageFactory.createBitmapImage()
    let data = try service.render(image, imageType: .bitmap, as: format)
    #expect(!data.isEmpty, "Data should not be empty for format: \(format.displayName)")
  }

  @Test("Render PDF to all formats", arguments: OutputFormat.allCases)
  func renderPdfToAllFormats(format: OutputFormat) throws {
    let image = TestImageFactory.createPDFImage()
    let data = try service.render(image, imageType: .pdf, as: format)
    #expect(!data.isEmpty, "Data should not be empty for format: \(format.displayName)")
  }

  @Test("Rendered PNG has valid header")
  func renderedPngHasValidHeader() throws {
    let image = TestImageFactory.createBitmapImage()
    let data = try service.render(image, imageType: .bitmap, as: .png)

    // PNG magic bytes: 89 50 4E 47
    let header = [UInt8](data.prefix(4))
    #expect(header == [0x89, 0x50, 0x4E, 0x47])
  }

  @Test("Rendered JPEG has valid header")
  func renderedJpegHasValidHeader() throws {
    let image = TestImageFactory.createBitmapImage()
    let data = try service.render(image, imageType: .bitmap, as: .jpeg)

    // JPEG magic bytes: FF D8 FF
    let header = [UInt8](data.prefix(3))
    #expect(header == [0xFF, 0xD8, 0xFF])
  }

  @Test("Rendered GIF has valid header")
  func renderedGifHasValidHeader() throws {
    let image = TestImageFactory.createBitmapImage()
    let data = try service.render(image, imageType: .bitmap, as: .gif)

    // GIF magic bytes: 47 49 46 38 (GIF8)
    let header = [UInt8](data.prefix(4))
    #expect(header == [0x47, 0x49, 0x46, 0x38])
  }
}
