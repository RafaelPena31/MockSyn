import XCTest

final class MockSynToolingTests: XCTestCase {
    func testOptionalToolingScriptsExposeHelpCommands() throws {
        let expectedHelp = [
            ("tools/mocksyn-inspect.sh", ["MockSyn Inspector", "support-matrix", "macro-expansion", "benchmarks", "docc", "doctor", "version"]),
            ("tools/export-macro-expansion.sh", ["Export MockSyn Macro Expansion", "swift build", "dump-macro-expansions"]),
            ("tools/benchmark.sh", ["MockSyn Benchmark", "swift test", "MockSynPerformance", "MOCKSYN_RUN_BENCHMARKS"]),
        ]

        for (relativePath, expectedFragments) in expectedHelp {
            let output = try runTool(relativePath, "--help")

            for fragment in expectedFragments {
                XCTAssertTrue(
                    output.contains(fragment),
                    "\(relativePath) help output should contain '\(fragment)'"
                )
            }
        }
    }

    func testInspectorDoctorAndVersionCommands() throws {
        let version = try runTool("tools/mocksyn-inspect.sh", "version")
        XCTAssertTrue(version.contains("MockSyn version 0.31.0"))

        let doctor = try runTool("tools/mocksyn-inspect.sh", "doctor")
        XCTAssertTrue(doctor.contains("MockSyn Inspector Doctor"))
        XCTAssertTrue(doctor.contains("OK Package.swift"))
        XCTAssertTrue(doctor.contains("OK DocC catalog"))
        XCTAssertTrue(doctor.contains("OK benchmark tool"))
        XCTAssertTrue(doctor.contains("OK latest version 0.31.0"))
    }

    func testInspectorDocCCommandCanValidateCatalog() throws {
        let output = try runTool("tools/mocksyn-inspect.sh", "docc", "--validate")

        XCTAssertTrue(output.contains("DocC validation passed"))
    }

    func testBlockTwelveDocumentationFilesExist() throws {
        let expectedDocuments = [
            "docs/features/tooling.md": ["Export de macro expansion", "CLI de inspecao", "DocC", "Benchmarks"],
            "docs/migration/mockable.md": ["Mockable", "@Mockable", "@Mocking"],
            "docs/migration/cuckoo.md": ["Cuckoo", "GeneratedMocks.swift", "@Mocking"],
            "docs/migration/swiftymocky.md": ["SwiftyMocky", "Mock.generated.swift", "@Mocking"],
            "Sources/MockSyn/MockSyn.docc/MockSyn.md": ["# MockSyn", "Macros", "Runtime", "Diagnostics"],
            "Tests/MockSynPerformanceTests/MockSynPerformanceTests.swift": ["MockSynPerformanceTests", "measure", "MOCKSYN_RUN_BENCHMARKS"],
        ]

        for (relativePath, expectedFragments) in expectedDocuments {
            let contents = try String(contentsOfFile: repositoryRoot.appendingPathComponent(relativePath).path)

            for fragment in expectedFragments {
                XCTAssertTrue(
                    contents.contains(fragment),
                    "\(relativePath) should contain '\(fragment)'"
                )
            }
        }
    }

    private func runTool(_ relativePath: String, _ arguments: String...) throws -> String {
        let process = Process()
        process.executableURL = repositoryRoot.appendingPathComponent(relativePath)
        process.arguments = arguments

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        try process.run()
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(decoding: data, as: UTF8.self)
        XCTAssertEqual(process.terminationStatus, 0, output)
        return output
    }

    private var repositoryRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }
}
