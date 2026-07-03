import XCTest

final class MockSynToolingTests: XCTestCase {
    func testOptionalToolingScriptsExposeHelpCommands() throws {
        let expectedHelp = [
            ("tools/mocksyn-inspect.sh", ["MockSyn Inspector", "support-matrix", "macro-expansion", "benchmarks", "docc"]),
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

    private func runTool(_ relativePath: String, _ argument: String) throws -> String {
        let process = Process()
        process.executableURL = repositoryRoot.appendingPathComponent(relativePath)
        process.arguments = [argument]

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
