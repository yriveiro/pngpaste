@testable import pngpaste
import Testing

@Suite("OutputMode Tests")
struct OutputModeTests {
    @Test("File mode equality with same path")
    func fileEqualityWithSamePath() {
        let mode1 = OutputMode.file(path: "/tmp/test.png")
        let mode2 = OutputMode.file(path: "/tmp/test.png")
        #expect(mode1 == mode2)
    }

    @Test("File mode inequality with different paths")
    func fileInequalityWithDifferentPaths() {
        let mode1 = OutputMode.file(path: "/tmp/a.png")
        let mode2 = OutputMode.file(path: "/tmp/b.png")
        #expect(mode1 != mode2)
    }

    @Test("Stdout mode equality")
    func stdoutEquality() {
        #expect(OutputMode.stdout == OutputMode.stdout)
    }

    @Test("Base64 mode equality")
    func base64Equality() {
        #expect(OutputMode.base64 == OutputMode.base64)
    }

    @Test("Stdout not equal to base64")
    func stdoutNotEqualBase64() {
        #expect(OutputMode.stdout != OutputMode.base64)
    }

    @Test("File not equal to stdout")
    func fileNotEqualStdout() {
        #expect(OutputMode.file(path: "/tmp/x") != OutputMode.stdout)
    }

    @Test("File not equal to base64")
    func fileNotEqualBase64() {
        #expect(OutputMode.file(path: "/tmp/x") != OutputMode.base64)
    }
}
