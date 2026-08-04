import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

extension MockSynMacroTests {
    func testClassOperatorMemberEmitsDiagnostic() {
        assertExpansion(
            """
            @Mocking
            class ComparableService {
                static func == (lhs: ComparableService, rhs: ComparableService) -> Bool {
                    false
                }
            }
            """,
            expandedSource: """
              class ComparableService {
                  static func == (lhs: ComparableService, rhs: ComparableService) -> Bool {
                      false
                  }
              }
              """,
            diagnostics: [
                DiagnosticSpec(
                    message: "MockSyn cannot generate class operator members. Move the operator behind a protocol requirement.",
                    line: 1,
                    column: 1,
                    severity: .error
                )
            ]
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

    func testMockingGlobalFunctionEmitsDiagnostic() {
        assertExpansion(
            """
            @Mocking
            func makeID() -> String {
                "real"
            }
            """,
            expandedSource: """
              func makeID() -> String {
                  "real"
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

    func testMockingClassWithStaticConcreteMethodEmitsDiagnostic() {
        assertExpansion(
            """
            @Mocking
            class IDFactory {
                static func make() -> String {
                    "real"
                }
            }
            """,
            expandedSource: """
              class IDFactory {
                  static func make() -> String {
                      "real"
                  }
              }
              """,
            diagnostics: [
                DiagnosticSpec(
                    message: "MockSyn cannot intercept concrete static class members. Move the static member behind a protocol requirement or use Objective-C interception for Objective-C class methods.",
                    line: 1,
                    column: 1,
                    severity: .error
                )
            ]
        )
    }

    func testStubbingClassWithStaticConcretePropertyEmitsDiagnostic() {
        assertExpansion(
            """
            @Stubbing
            class Configuration {
                static var value: String {
                    "real"
                }
            }
            """,
            expandedSource: """
              class Configuration {
                  static var value: String {
                      "real"
                  }
              }
              """,
            diagnostics: [
                DiagnosticSpec(
                    message: "MockSyn cannot intercept concrete static class members. Move the static member behind a protocol requirement or use Objective-C interception for Objective-C class methods.",
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
                    severity: .error,
                    fixIts: [
                        FixItSpec(message: "Remove 'final'")
                    ]
                )
            ]
        )
    }

    func testStubbingOnFinalClassEmitsDiagnostic() {
        assertExpansion(
            """
            @Stubbing
            final class AnalyticsService {
            }
            """,
            expandedSource: """
              final class AnalyticsService {
              }
              """,
            diagnostics: [
                DiagnosticSpec(
                    message: "MockSyn cannot mock a pure Swift final class directly. Extract a protocol and apply @Mocking to the protocol.",
                    line: 1,
                    column: 1,
                    severity: .error,
                    fixIts: [
                        FixItSpec(message: "Remove 'final'")
                    ]
                )
            ]
        )
    }

    func testSpyingOnFinalClassEmitsDiagnostic() {
        assertExpansion(
            """
            @Spying
            final class CacheStore {
            }
            """,
            expandedSource: """
              final class CacheStore {
              }
              """,
            diagnostics: [
                DiagnosticSpec(
                    message: "MockSyn cannot mock a pure Swift final class directly. Extract a protocol and apply @Mocking to the protocol.",
                    line: 1,
                    column: 1,
                    severity: .error,
                    fixIts: [
                        FixItSpec(message: "Remove 'final'")
                    ]
                )
            ]
        )
    }

    func testMockingClassWithFinalMethodEmitsDiagnostic() {
        assertExpansion(
            """
            @Mocking
            class UserService {
                final func load() -> String {
                    "real"
                }
            }
            """,
            expandedSource: """
              class UserService {
                  final func load() -> String {
                      "real"
                  }
              }
              """,
            diagnostics: [
                DiagnosticSpec(
                    message: "MockSyn cannot mock final class members by subclass generation. Remove 'final' from the member or extract a protocol.",
                    line: 1,
                    column: 1,
                    severity: .error,
                    fixIts: [
                        FixItSpec(message: "Remove 'final'")
                    ]
                )
            ]
        )
    }

    func testStubbingClassWithFinalPropertyEmitsDiagnostic() {
        assertExpansion(
            """
            @Stubbing
            class AnalyticsService {
                final var token: String {
                    "real"
                }
            }
            """,
            expandedSource: """
              class AnalyticsService {
                  final var token: String {
                      "real"
                  }
              }
              """,
            diagnostics: [
                DiagnosticSpec(
                    message: "MockSyn cannot mock final class members by subclass generation. Remove 'final' from the member or extract a protocol.",
                    line: 1,
                    column: 1,
                    severity: .error,
                    fixIts: [
                        FixItSpec(message: "Remove 'final'")
                    ]
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

    func testPublicAccessOnInternalClassEmitsDiagnostic() {
        assertExpansion(
            """
            @Mocking(access: .public)
            class UserService {
            }
            """,
            expandedSource: """
              class UserService {
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

    func testInvalidModeOptionEmitsDiagnostic() {
        assertExpansion(
            """
            @Mocking(mode: .lenient)
            protocol UserService {
            }
            """,
            expandedSource: """
              protocol UserService {
              }
              """,
            diagnostics: [
                DiagnosticSpec(
                    message: "MockSyn mode must be one of: strict, relaxed",
                    line: 1,
                    column: 1,
                    severity: .error
                )
            ]
        )
    }

    func testInvalidModeLiteralEmitsDiagnostic() {
        assertExpansion(
            """
            @Mocking(mode: "strict")
            protocol UserService {
            }
            """,
            expandedSource: """
              protocol UserService {
              }
              """,
            diagnostics: [
                DiagnosticSpec(
                    message: "MockSyn mode must be one of: strict, relaxed",
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
}
