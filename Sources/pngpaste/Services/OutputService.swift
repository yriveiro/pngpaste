import Foundation

/// A service that writes image data to various output destinations.
///
/// Supports writing to files, standard output as binary data, or standard output
/// as base64-encoded data.
struct OutputService: OutputWriting {
  /// Writes data to the specified output destination.
  ///
  /// Routes the data to the appropriate write method based on the output mode.
  ///
  /// - Parameters:
  ///   - data: The `Data` to write.
  ///   - mode: The output destination (`.file`, `.stdout`, or `.base64`).
  /// - Throws: `PngPasteError.writeFailure` for file write errors, or
  ///   `PngPasteError.stdoutWriteFailure` for stdout write errors.
  func write(_ data: Data, to mode: OutputMode) throws(PngPasteError) {
    switch mode {
    case .file(let path):
      try writeToFile(data, path: path)
    case .stdout:
      try writeToStdout(data)
    case .base64:
      try writeBase64ToStdout(data)
    }
  }

  /// Writes data to a file at the specified path.
  ///
  /// Uses atomic writing to ensure data integrity and prevent partial writes.
  /// The path is normalized to resolve any relative components (e.g., `..`, `.`).
  ///
  /// - Parameters:
  ///   - data: The `Data` to write.
  ///   - path: The file system path where data should be written.
  /// - Throws: `PngPasteError.writeFailure` if the file cannot be written, including
  ///   the path and underlying error description.
  private func writeToFile(_ data: Data, path: String) throws(PngPasteError) {
    let url = URL(fileURLWithPath: path).standardized

    do {
      try data.write(to: url, options: .atomic)
    } catch {
      let reason = (error as NSError).localizedDescription
      throw .writeFailure(path: path, reason: reason)
    }
  }

  /// Writes binary data directly to standard output.
  ///
  /// - Parameter data: The `Data` to write to stdout.
  /// - Throws: `PngPasteError.stdoutWriteFailure` if writing to stdout fails.
  private func writeToStdout(_ data: Data) throws(PngPasteError) {
    let stdout = FileHandle.standardOutput

    do {
      try stdout.write(contentsOf: data)
    } catch {
      throw .stdoutWriteFailure(reason: error.localizedDescription)
    }
  }

  /// Writes data to standard output as a base64-encoded string.
  ///
  /// Encodes the data to base64 format before writing to stdout, suitable for
  /// embedding in text-based contexts or piping to other tools.
  ///
  /// - Parameter data: The `Data` to encode and write.
  /// - Throws: `PngPasteError.stdoutWriteFailure` if writing to stdout fails.
  private func writeBase64ToStdout(_ data: Data) throws(PngPasteError) {
    let base64Data = data.base64EncodedData()
    try writeToStdout(base64Data)
  }
}
