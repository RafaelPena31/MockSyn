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
    func testPluginProvidesBlockOneMacros() {
        #if canImport(MockSynMacros)
        let plugin = MockSynPlugin()

        XCTAssertEqual(plugin.providingMacros.count, 3)
        XCTAssertTrue(plugin.providingMacros.contains { $0 == MockingMacro.self })
        XCTAssertTrue(plugin.providingMacros.contains { $0 == StubbingMacro.self })
        XCTAssertTrue(plugin.providingMacros.contains { $0 == SpyingMacro.self })
        #endif
    }

    func testMockingGeneratesInternalStrictMockByDefault() {
        assertExpansion(
            """
            @Mocking
            protocol UserService {
            }
            """,
            expandedSource: """
              protocol UserService {
              }

              #if MOCKSYN_ENABLE
              internal final class UserServiceMock: UserService {
                internal let __mockSyn: MockSynRuntime

                internal init(mode: MockSynMode = .strict) {
                  self.__mockSyn = MockSynRuntime(kind: .mock, mode: mode)
                }
              }
              #endif
              """
        )
    }

    func testMockingGeneratesPackageAccessWhenDeclarationAllowsIt() {
        assertExpansion(
            """
            @Mocking(access: .package)
            package protocol UserService {
            }
            """,
            expandedSource: """
              package protocol UserService {
              }

              #if MOCKSYN_ENABLE
              package final class UserServiceMock: UserService {
                package let __mockSyn: MockSynRuntime

                package init(mode: MockSynMode = .strict) {
                  self.__mockSyn = MockSynRuntime(kind: .mock, mode: mode)
                }
              }
              #endif
              """
        )
    }

    func testMockingGeneratesFileprivateAccessWhenDeclarationAllowsIt() {
        assertExpansion(
            """
            @Mocking(access: .fileprivate)
            fileprivate protocol UserService {
            }
            """,
            expandedSource: """
              fileprivate protocol UserService {
              }

              #if MOCKSYN_ENABLE
              fileprivate final class UserServiceMock: UserService {
                fileprivate let __mockSyn: MockSynRuntime

                fileprivate init(mode: MockSynMode = .strict) {
                  self.__mockSyn = MockSynRuntime(kind: .mock, mode: mode)
                }
              }
              #endif
              """
        )
    }

    func testMockingGeneratesPrivateAccessWhenDeclarationAllowsIt() {
        assertExpansion(
            """
            @Mocking(access: .private)
            private protocol UserService {
            }
            """,
            expandedSource: """
              private protocol UserService {
              }

              #if MOCKSYN_ENABLE
              private final class UserServiceMock: UserService {
                private let __mockSyn: MockSynRuntime

                private init(mode: MockSynMode = .strict) {
                  self.__mockSyn = MockSynRuntime(kind: .mock, mode: mode)
                }
              }
              #endif
              """
        )
    }

    func testStubbingGeneratesInternalRelaxedStubByDefault() {
        assertExpansion(
            """
            @Stubbing
            protocol AnalyticsService {
            }
            """,
            expandedSource: """
              protocol AnalyticsService {
              }

              #if MOCKSYN_ENABLE
              internal final class AnalyticsServiceStub: AnalyticsService {
                internal let __mockSyn: MockSynRuntime

                internal init(mode: MockSynMode = .relaxed) {
                  self.__mockSyn = MockSynRuntime(kind: .stub, mode: mode)
                }
              }
              #endif
              """
        )
    }

    func testSpyingGeneratesInternalStrictSpyWithWrappedImplementation() {
        assertExpansion(
            """
            @Spying
            protocol CacheStore {
            }
            """,
            expandedSource: """
              protocol CacheStore {
              }

              #if MOCKSYN_ENABLE
              internal final class CacheStoreSpy: CacheStore {
                internal let __mockSyn: MockSynRuntime
                internal let __mockSynWrapped: any CacheStore

                internal init(wrapping __mockSynWrapped: any CacheStore, mode: MockSynMode = .strict) {
                  self.__mockSyn = MockSynRuntime(kind: .spy, mode: mode)
                  self.__mockSynWrapped = __mockSynWrapped
                }
              }
              #endif
              """
        )
    }

    func testMockingUsesCustomNameAccessAndMode() {
        assertExpansion(
            """
            @Mocking(name: "MockUserService", access: .public, mode: .relaxed)
            public protocol UserService {
            }
            """,
            expandedSource: """
              public protocol UserService {
              }

              #if MOCKSYN_ENABLE
              public final class MockUserService: UserService {
                public let __mockSyn: MockSynRuntime

                public init(mode: MockSynMode = .relaxed) {
                  self.__mockSyn = MockSynRuntime(kind: .mock, mode: mode)
                }
              }
              #endif
              """
        )
    }

    func testMacroOnUnsupportedDeclarationEmitsDiagnostic() {
        assertExpansion(
            """
            @Mocking
            enum UserService {
            }
            """,
            expandedSource: """
              enum UserService {
              }
              """,
            diagnostics: [
                DiagnosticSpec(
                    message: "@Mocking can only be applied to protocols or supported classes",
                    line: 1,
                    column: 1,
                    severity: .error
                )
            ]
        )
    }

    func testStubbingOnUnsupportedDeclarationEmitsMacroSpecificDiagnostic() {
        assertExpansion(
            """
            @Stubbing
            enum AnalyticsService {
            }
            """,
            expandedSource: """
              enum AnalyticsService {
              }
              """,
            diagnostics: [
                DiagnosticSpec(
                    message: "@Stubbing can only be applied to protocols or supported classes",
                    line: 1,
                    column: 1,
                    severity: .error
                )
            ]
        )
    }

    func testSpyingOnUnsupportedDeclarationEmitsMacroSpecificDiagnostic() {
        assertExpansion(
            """
            @Spying
            enum CacheStore {
            }
            """,
            expandedSource: """
              enum CacheStore {
              }
              """,
            diagnostics: [
                DiagnosticSpec(
                    message: "@Spying can only be applied to protocols or supported classes",
                    line: 1,
                    column: 1,
                    severity: .error
                )
            ]
        )
    }

    func testMacroOnFinalClassEmitsDiagnostic() {
        assertExpansion(
            """
            @Mocking
            final class UserService {
            }
            """,
            expandedSource: """
              final class UserService {
              }
              """,
            diagnostics: [
                DiagnosticSpec(
                    message: "MockSyn cannot mock a pure Swift final class directly. Extract a protocol and apply @Mocking to the protocol.",
                    line: 1,
                    column: 1,
                    severity: .error
                )
            ]
        )
    }

    func testPublicAccessOnInternalProtocolEmitsDiagnostic() {
        assertExpansion(
            """
            @Mocking(access: .public)
            protocol UserService {
            }
            """,
            expandedSource: """
              protocol UserService {
              }
              """,
            diagnostics: [
                DiagnosticSpec(
                    message: "MockSyn cannot generate a public double for an internal declaration",
                    line: 1,
                    column: 1,
                    severity: .error
                )
            ]
        )
    }

    func testInvalidAccessOptionEmitsDiagnostic() {
        assertExpansion(
            """
            @Mocking(access: .open)
            public protocol UserService {
            }
            """,
            expandedSource: """
              public protocol UserService {
              }
              """,
            diagnostics: [
                DiagnosticSpec(
                    message: "MockSyn access must be one of: internal, public, package, fileprivate, private",
                    line: 1,
                    column: 1,
                    severity: .error
                )
            ]
        )
    }

    func testInvalidAccessLiteralEmitsDiagnostic() {
        assertExpansion(
            """
            @Mocking(access: "public")
            public protocol UserService {
            }
            """,
            expandedSource: """
              public protocol UserService {
              }
              """,
            diagnostics: [
                DiagnosticSpec(
                    message: "MockSyn access must be one of: internal, public, package, fileprivate, private",
                    line: 1,
                    column: 1,
                    severity: .error
                )
            ]
        )
    }

    func testInvalidCustomNameEmitsDiagnostic() {
        assertExpansion(
            """
            @Mocking(name: "UserServiceDouble")
            protocol UserService {
            }
            """,
            expandedSource: """
              protocol UserService {
              }
              """,
            diagnostics: [
                DiagnosticSpec(
                    message: "MockSyn generated name for @Mocking must start with Mock or end with Mock",
                    line: 1,
                    column: 1,
                    severity: .error
                )
            ]
        )
    }

    private func assertExpansion(
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
