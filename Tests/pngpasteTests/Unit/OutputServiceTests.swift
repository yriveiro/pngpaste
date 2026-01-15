import Foundation
@testable import pngpaste
import Testing

@Suite("OutputService Tests")
struct OutputServiceTests {
    let service = OutputService()

    @Test("Write to file creates file with correct content")
    func writeToFileCreatesFileWithCorrectContent() throws {
        let tempPath = NSTemporaryDirectory() + "test-\(UUID()).png"
        let testData = Data([0x89, 0x50, 0x4E, 0x47]) // PNG header

        try service.write(testData, to: .file(path: tempPath))

        let writtenData = try Data(contentsOf: URL(fileURLWithPath: tempPath))
        #expect(writtenData == testData)

        try? FileManager.default.removeItem(atPath: tempPath)
    }

    @Test("Write to file overwrites existing file")
    func writeToFileOverwritesExistingFile() throws {
        let tempPath = NSTemporaryDirectory() + "test-\(UUID()).png"
        let initialData = Data([0x00, 0x01, 0x02])
        let newData = Data([0x89, 0x50, 0x4E, 0x47])

        // Write initial data
        try initialData.write(to: URL(fileURLWithPath: tempPath))

        // Overwrite with new data
        try service.write(newData, to: .file(path: tempPath))

        let writtenData = try Data(contentsOf: URL(fileURLWithPath: tempPath))
        #expect(writtenData == newData)

        try? FileManager.default.removeItem(atPath: tempPath)
    }

    @Test("Write to invalid path throws writeFailure")
    func writeToInvalidPathThrowsWriteFailure() {
        let invalidPath = "/nonexistent/directory/file.png"
        let testData = Data([0x00])

        #expect {
            try service.write(testData, to: .file(path: invalidPath))
        } throws: { error in
            guard let pngError = error as? PngPasteError,
                  case let .writeFailure(path, _) = pngError
            else {
                return false
            }
            return path == invalidPath
        }
    }

    @Test("Write empty data to file succeeds")
    func writeEmptyDataToFileSucceeds() throws {
        let tempPath = NSTemporaryDirectory() + "test-\(UUID()).png"
        let emptyData = Data()

        try service.write(emptyData, to: .file(path: tempPath))

        let writtenData = try Data(contentsOf: URL(fileURLWithPath: tempPath))
        #expect(writtenData.isEmpty)

        try? FileManager.default.removeItem(atPath: tempPath)
    }

    @Test("Mock service captures written data")
    func mockServiceCapturesWrittenData() throws {
        let mockService = MockOutputService()
        let testData = Data([0x89, 0x50, 0x4E, 0x47])

        try mockService.write(testData, to: .file(path: "/tmp/test.png"))

        #expect(mockService.writtenData == testData)
        #expect(mockService.writtenMode == .file(path: "/tmp/test.png"))
    }

    @Test("Mock service can throw errors")
    func mockServiceCanThrowErrors() {
        let mockService = MockOutputService()
        mockService.errorToThrow = .writeFailure(path: "/tmp/x", reason: "mock error")

        #expect(throws: PngPasteError.self) {
            try mockService.write(Data(), to: .file(path: "/tmp/x"))
        }
    }
}
