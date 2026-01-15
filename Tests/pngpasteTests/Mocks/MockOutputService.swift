import Foundation
@testable import pngpaste

final class MockOutputService: OutputWriting, @unchecked Sendable {
    var writtenData: Data?
    var writtenMode: OutputMode?
    var errorToThrow: PngPasteError?

    func write(_ data: Data, to mode: OutputMode) throws(PngPasteError) {
        if let error = errorToThrow { throw error }
        writtenData = data
        writtenMode = mode
    }
}
