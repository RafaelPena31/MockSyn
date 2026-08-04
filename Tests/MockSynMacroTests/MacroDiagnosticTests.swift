import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

extension MockSynMacroTests {
    func testCustomProtocolInheritanceEmitsActionableMacroSpecificWarnings() {
        assertExpansion(
            """
            protocol ParentService {
                func load()
            }

            @Mocking
            protocol ChildService: ParentService {
            }
            """,
            expandedSource: """
              protocol ParentService {
                  func load()
              }
              protocol ChildService: ParentService {
              }

              #if MOCKSYN_ENABLE
              internal final class ChildServiceMock: ChildService {
                internal let __mockSyn: MockSynRuntime

                internal init(mode: MockSynMode = .strict) {
                  self.__mockSyn = MockSynRuntime(kind: .mock, mode: mode)
                }
              }
              #endif
              """,
            diagnostics: [
                DiagnosticSpec(
                    message: "@Mocking does not generate requirements inherited from ParentService. Redeclare required members in the annotated protocol body or use a local mirror protocol.",
                    line: 5,
                    column: 1,
                    severity: .warning
                )
            ]
        )

        assertExpansion(
            """
            protocol ParentService {
                func load()
            }

            @Stubbing
            protocol ChildService: ParentService {
            }
            """,
            expandedSource: """
              protocol ParentService {
                  func load()
              }
              protocol ChildService: ParentService {
              }

              #if MOCKSYN_ENABLE
              internal final class ChildServiceStub: ChildService {
                internal let __mockSyn: MockSynRuntime

                internal init(mode: MockSynMode = .relaxed) {
                  self.__mockSyn = MockSynRuntime(kind: .stub, mode: mode)
                }
              }
              #endif
              """,
            diagnostics: [
                DiagnosticSpec(
                    message: "@Stubbing does not generate requirements inherited from ParentService. Redeclare required members in the annotated protocol body or use a local mirror protocol.",
                    line: 5,
                    column: 1,
                    severity: .warning
                )
            ]
        )

        assertExpansion(
            """
            protocol ParentService {
                func load()
            }

            @Spying
            protocol ChildService: ParentService {
            }
            """,
            expandedSource: """
              protocol ParentService {
                  func load()
              }
              protocol ChildService: ParentService {
              }

              #if MOCKSYN_ENABLE
              internal final class ChildServiceSpy: ChildService {
                internal let __mockSyn: MockSynRuntime
                internal let __mockSynWrapped: any ChildService

                internal init(wrapping __mockSynWrapped: any ChildService, mode: MockSynMode = .strict) {
                  self.__mockSyn = MockSynRuntime(kind: .spy, mode: mode)
                  self.__mockSynWrapped = __mockSynWrapped
                }
              }
              #endif
              """,
            diagnostics: [
                DiagnosticSpec(
                    message: "@Spying does not generate requirements inherited from ParentService. Redeclare required members in the annotated protocol body or use a local mirror protocol.",
                    line: 5,
                    column: 1,
                    severity: .warning
                )
            ]
        )
    }

    func testMarkerAndDefaultSatisfiedProtocolInheritanceDoesNotWarn() {
        assertExpansion(
            """
            @Mocking
            protocol MarkerService: AnyObject, Sendable, Swift.Sendable, ObservableObject, Combine.ObservableObject {
            }
            """,
            expandedSource: """
              protocol MarkerService: AnyObject, Sendable, Swift.Sendable, ObservableObject, Combine.ObservableObject {
              }

              #if MOCKSYN_ENABLE
              internal final class MarkerServiceMock: MarkerService {
                internal let __mockSyn: MockSynRuntime

                internal init(mode: MockSynMode = .strict) {
                  self.__mockSyn = MockSynRuntime(kind: .mock, mode: mode)
                }
              }
              #endif
              """
        )
    }

    func testStandardRequirementBearingProtocolInheritanceWarns() {
        assertExpansion(
            """
            @Mocking
            protocol EntityService: Hashable, Identifiable {
            }
            """,
            expandedSource: """
              protocol EntityService: Hashable, Identifiable {
              }

              #if MOCKSYN_ENABLE
              internal final class EntityServiceMock: EntityService {
                internal let __mockSyn: MockSynRuntime

                internal init(mode: MockSynMode = .strict) {
                  self.__mockSyn = MockSynRuntime(kind: .mock, mode: mode)
                }
              }
              #endif
              """,
            diagnostics: [
                DiagnosticSpec(
                    message: "@Mocking does not generate requirements inherited from Hashable, Identifiable. Redeclare required members in the annotated protocol body or use a local mirror protocol.",
                    line: 1,
                    column: 1,
                    severity: .warning
                )
            ]
        )
    }

    func testMultipleUnsupportedProtocolInheritanceWarnsInSourceOrder() {
        assertExpansion(
            """
            @Mocking
            protocol CompositeService: FirstParent, Support.SecondParent, Sendable, ThirdParent {
            }
            """,
            expandedSource: """
              protocol CompositeService: FirstParent, Support.SecondParent, Sendable, ThirdParent {
              }

              #if MOCKSYN_ENABLE
              internal final class CompositeServiceMock: CompositeService {
                internal let __mockSyn: MockSynRuntime

                internal init(mode: MockSynMode = .strict) {
                  self.__mockSyn = MockSynRuntime(kind: .mock, mode: mode)
                }
              }
              #endif
              """,
            diagnostics: [
                DiagnosticSpec(
                    message: "@Mocking does not generate requirements inherited from FirstParent, Support.SecondParent, ThirdParent. Redeclare required members in the annotated protocol body or use a local mirror protocol.",
                    line: 1,
                    column: 1,
                    severity: .warning
                )
            ]
        )
    }

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
