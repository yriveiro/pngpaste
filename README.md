# pngpaste

A macOS command-line tool to paste images from the clipboard to files, similar to how `pbpaste` works for text.

## Features

- Paste clipboard images directly to files
- Multiple input format support: PNG, PDF, GIF, TIFF, JPEG, HEIC
- Multiple output format support: PNG, GIF, JPEG, TIFF
- Output to stdout (binary or base64-encoded)
- Automatic format detection from file extension

## Requirements

- macOS 15.0+
- Swift 6.2+

## Installation

### Quick Install

```bash
curl -LSfs https://raw.githubusercontent.com/yriveiro/pngpaste/main/scripts/install.sh | sh
```

### From Source

```bash
# Clone the repository
git clone https://github.com/yriveiro/pngpaste.git
cd pngpaste

# Build and install
make install
```

By default, the binary is installed to `/usr/local/bin`. To install to a different location:

```bash
make install PREFIX=/your/custom/path
```

### Uninstall

```bash
make uninstall
```

## Usage

```bash
# Save clipboard image to a file (format detected from extension)
pngpaste output.png
pngpaste screenshot.jpg
pngpaste image.gif

# Output to stdout as binary
pngpaste -

# Output to stdout as base64-encoded PNG
pngpaste -b
```

### Options

| Option | Description |
| -------- | ------------- |
| `-b` | Output to stdout as base64-encoded PNG |
| `-h, --help` | Show help information |
| `--version` | Show version number |

### Examples

```bash
# Take a screenshot (Cmd+Shift+4), then save it
pngpaste screenshot.png

# Pipe base64 output to another command
pngpaste -b | base64 -d > decoded.png

# Save as JPEG with automatic format conversion
pngpaste photo.jpg
```

## Development

### Setup

Install development dependencies:

```bash
make setup
```

This installs/updates the following tools via Homebrew (if available):

- **swiftlint** - Swift linter
- **swiftformat** - Swift code formatter
- **shellcheck** - Bash script linter
- **shfmt** - Bash script formatter

If Homebrew is not installed, manual installation links are provided.

### Build

```bash
# Release build
make build

# Debug build
make build-debug
```

### Test

```bash
# Run all tests
make test

# Run unit tests only
make test-unit

# Run integration tests only
make test-integration

# Run tests with coverage report
make test-coverage

# Generate HTML coverage report
make coverage-html
```

### Code Quality

```bash
# Run linter
make lint

# Format code
make format

# Check formatting without changes
make format-check

# Run all checks (lint + format-check + test)
make check
```

### Clean

```bash
make clean
```

## Project Structure

```
pngpaste/
├── Sources/pngpaste/
│   ├── PngPaste.swift           # Main CLI entry point
│   ├── Models/
│   │   ├── ImageType.swift      # Image type classification
│   │   ├── OutputFormat.swift   # Image format definitions
│   │   ├── OutputMode.swift     # Output destination modes
│   │   └── PngPasteError.swift  # Error types
│   ├── Services/
│   │   ├── ClipboardService.swift    # Clipboard reading
│   │   ├── ImageRenderService.swift  # Image format conversion
│   │   └── OutputService.swift       # File/stdout writing
│   └── Protocols/
│       ├── ClipboardReading.swift
│       ├── ImageRendering.swift
│       └── OutputWriting.swift
├── Tests/pngpasteTests/
│   ├── Unit/
│   ├── Integration/
│   ├── Mocks/
│   └── Helpers/
├── Package.swift
├── Makefile
├── scripts/
│   ├── install.sh            # Installation script
│   └── release.sh            # Release automation
└── LICENSE
```

## License

MIT License - see [LICENSE](LICENSE) for details.
