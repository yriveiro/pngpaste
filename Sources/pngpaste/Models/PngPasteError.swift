import Foundation

enum PngPasteError: Error, CustomStringConvertible, Sendable, Equatable {
    case noImageOnClipboard
    case unsupportedImageFormat
    case conversionFailed(format: String)
    case writeFailure(path: String, reason: String)
    case stdoutWriteFailure(reason: String)

    var description: String {
        switch self {
        case .noImageOnClipboard:
            "no image data found on the clipboard"
        case .unsupportedImageFormat:
            "clipboard contains unsupported image format"
        case let .conversionFailed(format):
            "failed to convert image to \(format)"
        case let .writeFailure(path, reason):
            "failed to write to '\(path)': \(reason)"
        case let .stdoutWriteFailure(reason):
            "failed to write to stdout: \(reason)"
        }
    }
}
