import AppKit
import ArgumentParser

/// The main command-line interface for pngpaste, a tool for pasting clipboard images to files.
///
/// Similar to how `pbpaste` works for text, pngpaste extracts images from the macOS clipboard
/// and saves them to files or outputs them to stdout. Supports multiple input formats (PNG, PDF,
/// GIF, TIF, JPEG, HEIC) and output formats (PNG, GIF, JPEG, TIFF).
@main
struct PngPaste: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "pngpaste",
        abstract: "Paste PNG into files, much like pbpaste does for text.",
        discussion: """
        Supported input formats: PNG, PDF, GIF, TIF, JPEG, HEIC
        Supported output formats: PNG, GIF, JPEG, TIFF
        Output format is determined by the file extension, defaulting to PNG.
        """,
        version: "1.0.0"
    )

    @Flag(name: .short, help: "Output to stdout as base64 encoded PNG")
    var base64 = false

    @Argument(help: "Output file path (use '-' for binary stdout)")
    var outputPath: String?

    /// Executes the pngpaste command.
    ///
    /// Determines the output mode and format from command-line arguments, then performs
    /// the paste operation. Displays help if no valid output mode can be determined.
    ///
    /// - Throws: `CleanExit.helpRequest` if no output mode is specified, or `ExitCode.failure`
    ///   if the paste operation fails.
    mutating func run() async throws {
        guard let mode = determineOutputMode() else {
            throw CleanExit.helpRequest()
        }

        let format = determineOutputFormat(for: mode)

        do {
            try await performPaste(mode: mode, format: format)
        } catch {
            fputs("pngpaste: \(error.description)\n", stderr)
            throw ExitCode.failure
        }
    }

    /// Performs the core paste operation: reading, rendering, and writing the image.
    ///
    /// Orchestrates the clipboard-to-output pipeline using dependency-injected services
    /// for testability.
    ///
    /// - Parameters:
    ///   - mode: The output destination mode.
    ///   - format: The target image format.
    ///   - clipboardService: The service used to read images from the clipboard.
    ///   - renderService: The service used to render images to the target format.
    ///   - outputService: The service used to write the rendered data.
    /// - Throws: `PngPasteError` if any step in the pipeline fails.
    @MainActor
    private func performPaste(
        mode: OutputMode,
        format: OutputFormat,
        clipboardService: some ClipboardReading = ClipboardService(),
        renderService: some ImageRendering = ImageRenderService(),
        outputService: some OutputWriting = OutputService()
    ) async throws(PngPasteError) {
        let image = try clipboardService.readImage()
        let imageType = try clipboardService.imageType(for: image)
        let data = try renderService.render(image, imageType: imageType, as: format)

        try outputService.write(data, to: mode)
    }

    /// Determines the output mode based on command-line arguments.
    ///
    /// Evaluates the `base64` flag and `outputPath` argument to determine whether output
    /// should be written to a file, stdout as binary, or stdout as base64-encoded data.
    ///
    /// - Returns: The determined `OutputMode`, or `nil` if no valid output destination
    ///   was specified (indicating help should be displayed).
    private func determineOutputMode() -> OutputMode? {
        if base64 {
            return .base64
        }

        guard let path = outputPath else {
            return nil
        }

        return path == "-" ? .stdout : .file(path: path)
    }

    /// Determines the output format based on the output mode.
    ///
    /// For file output, extracts the format from the file extension. For stdout and base64
    /// modes, defaults to PNG format.
    ///
    /// - Parameter mode: The output mode to determine the format for.
    /// - Returns: The appropriate `OutputFormat` for the given mode.
    private func determineOutputFormat(for mode: OutputMode) -> OutputFormat {
        switch mode {
        case let .file(path):
            OutputFormat(fromFilename: path)
        case .stdout, .base64:
            .png
        }
    }
}
