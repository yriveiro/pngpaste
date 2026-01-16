import AppKit
import Foundation
import Testing

@testable import pngpaste

@Suite("PngPaste Integration Tests")
@MainActor
struct PngPasteIntegrationTests {
  @Test("Full pipeline: bitmap to file")
  func fullPipelineBitmapToFile() throws {
    let mockClipboard = MockClipboardService(
      imageToReturn: TestImageFactory.createBitmapImage(),
      imageTypeToReturn: .bitmap
    )
    let renderService = ImageRenderService()
    let outputService = OutputService()

    let tempPath = NSTemporaryDirectory() + "integration-\(UUID()).png"

    let image = try mockClipboard.readImage()
    let imageType = try mockClipboard.imageType(for: image)
    let data = try renderService.render(image, imageType: imageType, as: .png)
    try outputService.write(data, to: .file(path: tempPath))

    #expect(FileManager.default.fileExists(atPath: tempPath))

    let writtenData = try Data(contentsOf: URL(fileURLWithPath: tempPath))
    #expect(!writtenData.isEmpty)

    // Verify PNG header
    let header = [UInt8](writtenData.prefix(4))
    #expect(header == [0x89, 0x50, 0x4E, 0x47])

    try? FileManager.default.removeItem(atPath: tempPath)
  }

  @Test("Full pipeline: PDF to JPEG")
  func fullPipelinePdfToJpeg() throws {
    let mockClipboard = MockClipboardService(
      imageToReturn: TestImageFactory.createPDFImage(),
      imageTypeToReturn: .pdf
    )
    let renderService = ImageRenderService()
    let outputService = OutputService()

    let tempPath = NSTemporaryDirectory() + "integration-\(UUID()).jpg"

    let image = try mockClipboard.readImage()
    let imageType = try mockClipboard.imageType(for: image)
    let data = try renderService.render(image, imageType: imageType, as: .jpeg)
    try outputService.write(data, to: .file(path: tempPath))

    #expect(FileManager.default.fileExists(atPath: tempPath))

    let writtenData = try Data(contentsOf: URL(fileURLWithPath: tempPath))
    // Verify JPEG header
    let header = [UInt8](writtenData.prefix(3))
    #expect(header == [0xFF, 0xD8, 0xFF])

    try? FileManager.default.removeItem(atPath: tempPath)
  }

  @Test("Full pipeline: bitmap to base64")
  func fullPipelineBitmapToBase64() throws {
    let mockClipboard = MockClipboardService(
      imageToReturn: TestImageFactory.createBitmapImage(),
      imageTypeToReturn: .bitmap
    )
    let renderService = ImageRenderService()
    let mockOutput = MockOutputService()

    let image = try mockClipboard.readImage()
    let imageType = try mockClipboard.imageType(for: image)
    let data = try renderService.render(image, imageType: imageType, as: .png)

    // Simulate base64 encoding
    let base64Data = data.base64EncodedData()
    try mockOutput.write(base64Data, to: .base64)

    #expect(mockOutput.writtenData != nil)
    #expect(!mockOutput.writtenData!.isEmpty)
    #expect(mockOutput.writtenMode == .base64)
  }

  @Test("Error propagation: no image")
  func errorPropagationNoImage() {
    let mockClipboard = MockClipboardService(errorToThrow: .noImageOnClipboard)

    #expect(throws: PngPasteError.noImageOnClipboard) {
      try mockClipboard.readImage()
    }
  }

  @Test("Error propagation: unsupported format")
  func errorPropagationUnsupportedFormat() {
    let mockClipboard = MockClipboardService(errorToThrow: .unsupportedImageFormat)

    #expect(throws: PngPasteError.unsupportedImageFormat) {
      try mockClipboard.readImage()
    }
  }

  @Test("Error propagation: conversion failed")
  func errorPropagationConversionFailed() throws {
    let mockRender = MockImageRenderService(errorToThrow: .conversionFailed(format: "PNG"))

    #expect(throws: PngPasteError.self) {
      try mockRender.render(
        TestImageFactory.createBitmapImage(),
        imageType: .bitmap,
        as: .png
      )
    }
  }

  @Test("Error propagation: write failure")
  func errorPropagationWriteFailure() {
    let mockOutput = MockOutputService()
    mockOutput.errorToThrow = .writeFailure(path: "/invalid", reason: "test")

    #expect(throws: PngPasteError.self) {
      try mockOutput.write(Data(), to: .file(path: "/invalid"))
    }
  }

  @Test("Multiple formats from same source", arguments: OutputFormat.allCases)
  func multipleFormatsFromSameSource(format: OutputFormat) throws {
    let mockClipboard = MockClipboardService(
      imageToReturn: TestImageFactory.createBitmapImage(),
      imageTypeToReturn: .bitmap
    )
    let renderService = ImageRenderService()

    let image = try mockClipboard.readImage()
    let imageType = try mockClipboard.imageType(for: image)

    let data = try renderService.render(image, imageType: imageType, as: format)
    #expect(!data.isEmpty, "Data should not be empty for format: \(format.displayName)")
  }

  @Test("Large image rendering")
  func largeImageRendering() throws {
    let mockClipboard = MockClipboardService(
      imageToReturn: TestImageFactory.createBitmapImage(width: 2000, height: 2000),
      imageTypeToReturn: .bitmap
    )
    let renderService = ImageRenderService()

    let image = try mockClipboard.readImage()
    let imageType = try mockClipboard.imageType(for: image)
    let data = try renderService.render(image, imageType: imageType, as: .png)

    #expect(!data.isEmpty)
    #expect(data.count > 1000, "Large image should produce substantial data")
  }
}
