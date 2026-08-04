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
                internal let objectWillChange: MockSynObservableObjectPublisher
                internal let __mockSyn: MockSynRuntime

                internal init(mode: MockSynMode = .strict) {
                  let __mockSynObjectWillChange = MockSynObservableObjectPublisher()
                  self.objectWillChange = __mockSynObjectWillChange
                  self.__mockSyn = MockSynRuntime(kind: .mock, mode: mode, onChange: {
                    __mockSynObjectWillChange.send()
                  })
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
}
