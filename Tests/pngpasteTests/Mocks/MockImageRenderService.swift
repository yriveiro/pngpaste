import AppKit

@testable import pngpaste

@MainActor
struct MockImageRenderService: ImageRendering {
  var dataToReturn: Data?
  var errorToThrow: PngPasteError?

  func render(
    _ image: NSImage,
    imageType: ImageType,
    as format: OutputFormat
  ) throws(PngPasteError) -> Data {
    if let error = errorToThrow { throw error }
    guard let data = dataToReturn else {
      throw .conversionFailed(format: format.displayName)
    }
    return data
  }
}
