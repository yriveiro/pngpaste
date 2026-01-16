import AppKit

@testable import pngpaste

struct MockClipboardService: ClipboardReading {
  var imageToReturn: NSImage?
  var imageTypeToReturn: ImageType = .bitmap
  var errorToThrow: PngPasteError?

  func readImage() throws(PngPasteError) -> NSImage {
    if let error = errorToThrow { throw error }
    guard let image = imageToReturn else { throw .noImageOnClipboard }
    return image
  }

  func imageType(for image: NSImage) throws(PngPasteError) -> ImageType {
    if let error = errorToThrow { throw error }
    return imageTypeToReturn
  }
}
