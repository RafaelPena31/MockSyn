import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

#if canImport(MockSynMacros)
@testable import MockSynMacros

private let testMacros: [String: Macro.Type] = [
    "Mocking": MockingMacro.self,
    "Stubbing": StubbingMacro.self,
    "Spying": SpyingMacro.self,
]
#endif

final class MockSynMacroTests: XCTestCase {
}

extension MockSynMacroTests {
    func assertExpansion(
        _ source: String,
        expandedSource: String,
        diagnostics: [DiagnosticSpec] = [],
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        #if canImport(MockSynMacros)
        assertMacroExpansion(
            source,
            expandedSource: expandedSource,
            diagnostics: diagnostics,
            macros: testMacros,
            indentationWidth: .spaces(2),
            file: file,
            line: line
        )
        #else
        XCTFail("macros are only supported when running tests for the host platform", file: file, line: line)
        #endif
    }
}
