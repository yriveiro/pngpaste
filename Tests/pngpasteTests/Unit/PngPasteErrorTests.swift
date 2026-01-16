import Testing

@testable import pngpaste

@Suite("PngPasteError Tests")
struct PngPasteErrorTests {
  @Test("noImageOnClipboard description")
  func noImageOnClipboardDescription() {
    let error = PngPasteError.noImageOnClipboard
    #expect(error.description == "no image data found on the clipboard")
  }

  @Test("unsupportedImageFormat description")
  func unsupportedImageFormatDescription() {
    let error = PngPasteError.unsupportedImageFormat
    #expect(error.description == "clipboard contains unsupported image format")
  }

  @Test("conversionFailed includes format name")
  func conversionFailedIncludesFormat() {
    let error = PngPasteError.conversionFailed(format: "PNG")
    #expect(error.description.contains("PNG"))
    #expect(error.description.contains("failed to convert"))
  }

  @Test("writeFailure includes path and reason")
  func writeFailureIncludesPathAndReason() {
    let error = PngPasteError.writeFailure(path: "/tmp/test.png", reason: "permission denied")
    #expect(error.description.contains("/tmp/test.png"))
    #expect(error.description.contains("permission denied"))
  }

  @Test("stdoutWriteFailure includes reason")
  func stdoutWriteFailureIncludesReason() {
    let error = PngPasteError.stdoutWriteFailure(reason: "broken pipe")
    #expect(error.description.contains("broken pipe"))
    #expect(error.description.contains("stdout"))
  }

  @Test("Conforms to Error protocol")
  func conformsToErrorProtocol() {
    let error: Error = PngPasteError.noImageOnClipboard
    #expect(error is PngPasteError)
  }

  @Test("Conforms to Sendable")
  func conformsToSendable() {
    let error: Sendable = PngPasteError.noImageOnClipboard
    #expect(error is PngPasteError)
  }
}
