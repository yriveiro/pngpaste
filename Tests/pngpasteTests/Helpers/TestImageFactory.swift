import AppKit

enum TestImageFactory {
  static func createBitmapImage(width: Int = 100, height: Int = 100, color: NSColor = .red)
    -> NSImage
  {
    let image = NSImage(size: NSSize(width: width, height: height))
    image.lockFocus()
    color.setFill()
    NSRect(x: 0, y: 0, width: width, height: height).fill()
    image.unlockFocus()
    return image
  }

  static func createPDFImage(width: Int = 100, height: Int = 100) -> NSImage {
    let pdfData = NSMutableData()
    var rect = CGRect(x: 0, y: 0, width: width, height: height)

    guard let consumer = CGDataConsumer(data: pdfData as CFMutableData),
      let context = CGContext(consumer: consumer, mediaBox: &rect, nil)
    else {
      fatalError("Failed to create PDF context")
    }

    context.beginPDFPage(nil)
    context.setFillColor(NSColor.blue.cgColor)
    context.fill(rect)
    context.endPDFPage()
    context.closePDF()

    return NSImage(data: pdfData as Data)!
  }

  static func createInvalidImage() -> NSImage {
    NSImage(size: .zero)
  }
}
