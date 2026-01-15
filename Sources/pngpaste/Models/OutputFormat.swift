import AppKit

enum OutputFormat: String, CaseIterable, Sendable, Equatable {
    case png
    case gif
    case jpeg
    case tiff

    private static let jpegCompressionQuality: Double = 0.9

    /// The corresponding `NSBitmapImageRep.FileType` for this output format.
    ///
    /// Used when encoding image data through AppKit's bitmap representation APIs.
    var bitmapType: NSBitmapImageRep.FileType {
        switch self {
        case .png: .png
        case .gif: .gif
        case .jpeg: .jpeg
        case .tiff: .tiff
        }
    }

    /// A human-readable display name for this format.
    ///
    /// Returns the format name in uppercase (e.g., "PNG", "JPEG").
    var displayName: String {
        rawValue.uppercased()
    }

    /// The encoding properties used when creating bitmap representations.
    ///
    /// For JPEG format, includes a compression factor of 0.9 for balanced quality and file size.
    /// Other formats use default encoding properties.
    var encodingProperties: [NSBitmapImageRep.PropertyKey: Any] {
        switch self {
        case .jpeg:
            [.compressionFactor: Self.jpegCompressionQuality]
        case .png, .gif, .tiff:
            [:]
        }
    }

    /// Creates an output format from a file extension string.
    ///
    /// Performs case-insensitive matching and supports common extension variations
    /// (e.g., both "jpg" and "jpeg" map to `.jpeg`). Unrecognized extensions default to `.png`.
    ///
    /// - Parameter ext: The file extension string (without the leading dot).
    init(fromExtension ext: String) {
        switch ext.lowercased() {
        case "gif":
            self = .gif
        case "jpg", "jpeg":
            self = .jpeg
        case "tif", "tiff":
            self = .tiff
        default:
            self = .png
        }
    }

    /// Creates an output format by extracting and parsing the extension from a filename.
    ///
    /// Extracts the path extension from the provided filename and delegates to
    /// `init(fromExtension:)` for format determination.
    ///
    /// - Parameter filename: The filename or file path to extract the extension from.
    init(fromFilename filename: String) {
        let ext = URL(fileURLWithPath: filename).pathExtension
        self.init(fromExtension: ext)
    }
}
