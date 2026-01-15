import Foundation

/// A protocol that defines the interface for writing data to various output destinations.
protocol OutputWriting: Sendable {
    /// Writes data to the specified output destination.
    ///
    /// Supports writing to files, standard output (binary), or standard output as base64-encoded data,
    /// depending on the output mode specified.
    ///
    /// - Parameters:
    ///   - data: The `Data` to write.
    ///   - mode: The output destination mode (`.file`, `.stdout`, or `.base64`).
    /// - Throws: `PngPasteError.writeFailure` if writing to a file fails, or
    ///   `PngPasteError.stdoutWriteFailure` if writing to stdout fails.
    func write(_ data: Data, to mode: OutputMode) throws(PngPasteError)
}
