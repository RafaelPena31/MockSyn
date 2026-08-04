import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

extension MockSynMacroTests {
    func testMockingObservableObjectGeneratesPublisherAndNotificationWiring() {
        assertExpansion(
            """
            @Mocking
            protocol ObservableService: ObservableObject {
                var name: String { get set }
            }
            """,
            expandedSource: """
              protocol ObservableService: ObservableObject {
                  var name: String { get set }
              }

              #if MOCKSYN_ENABLE
              internal final class ObservableServiceMock: ObservableService {
                internal let objectWillChange: MockSynObservableObjectPublisher
                internal let __mockSyn: MockSynRuntime

                internal init(mode: MockSynMode = .strict) {
                  let __mockSynObjectWillChange = MockSynObservableObjectPublisher()
                  self.objectWillChange = __mockSynObjectWillChange
                  self.__mockSyn = MockSynRuntime(kind: .mock, mode: mode, onChange: {
                    __mockSynObjectWillChange.send()
                  })
                }
                internal var given: __MockSynGiven {
                  __MockSynGiven(__mockSyn: __mockSyn)
                }

                internal var when: __MockSynGiven {
                  given
                }

                internal var verify: __MockSynVerify {
                  __MockSynVerify(__mockSyn: __mockSyn)
                }

                internal func confirmVerified() throws {
                  try __mockSyn.confirmVerified()
                }

                internal func checkUnnecessaryStubs() throws {
                  try __mockSyn.checkUnnecessaryStubs()
                }

                internal func reset(_ scope: MockSynResetScope = .all) {
                  __mockSyn.reset(scope)
                }

                internal struct __MockSynGiven {
                  internal let __mockSyn: MockSynRuntime

                  internal var name: MockSynNonThrowingPropertyStubber<String> {
                    MockSynNonThrowingPropertyStubber(runtime: __mockSyn, getMember: "name.get", setMember: "name.set")
                  }
                }

                internal struct __MockSynVerify {
                  internal let __mockSyn: MockSynRuntime

                  internal var name: MockSynPropertyVerification<String> {
                    MockSynPropertyVerification(runtime: __mockSyn, getMember: "name.get", setMember: "name.set")
                  }
                }

                internal var name: String {
                  get {
                    __mockSyn.resolve(member: "name.get", arguments: [], returnType: String.self)
                  }
                  set {
                    __mockSyn.notifyChange()
                    __mockSyn.resolveVoid(member: "name.set", arguments: [newValue as Any])
                  }
                }
              }
              #endif
              """
        )
    }

    func testStubbingQualifiedObservableObjectGeneratesPublisher() {
        assertExpansion(
            """
            @Stubbing
            protocol ObservableService: Combine.ObservableObject {
            }
            """,
            expandedSource: """
              protocol ObservableService: Combine.ObservableObject {
              }

              #if MOCKSYN_ENABLE
              internal final class ObservableServiceStub: ObservableService {
                internal let objectWillChange: MockSynObservableObjectPublisher
                internal let __mockSyn: MockSynRuntime

                internal init(mode: MockSynMode = .relaxed) {
                  let __mockSynObjectWillChange = MockSynObservableObjectPublisher()
                  self.objectWillChange = __mockSynObjectWillChange
                  self.__mockSyn = MockSynRuntime(kind: .stub, mode: mode, onChange: {
                    __mockSynObjectWillChange.send()
                  })
                }
              }
              #endif
              """
        )
    }

    func testSpyingObservableObjectGeneratesPublisher() {
        assertExpansion(
            """
            @Spying
            protocol ObservableService: ObservableObject {
            }
            """,
            expandedSource: """
              protocol ObservableService: ObservableObject {
              }

              #if MOCKSYN_ENABLE
              internal final class ObservableServiceSpy: ObservableService {
                internal let objectWillChange: MockSynObservableObjectPublisher
                internal let __mockSyn: MockSynRuntime
                internal let __mockSynWrapped: any ObservableService

                internal init(wrapping __mockSynWrapped: any ObservableService, mode: MockSynMode = .strict) {
                  let __mockSynObjectWillChange = MockSynObservableObjectPublisher()
                  self.objectWillChange = __mockSynObjectWillChange
                  self.__mockSyn = MockSynRuntime(kind: .spy, mode: mode, onChange: {
                    __mockSynObjectWillChange.send()
                  })
                  self.__mockSynWrapped = __mockSynWrapped
                }
              }
              #endif
              """
        )
    }

    func testTransitiveObservableObjectInheritanceDoesNotGeneratePublisherWiring() {
        assertExpansion(
            """
            protocol ObservableParent: ObservableObject {
            }

            @Mocking
            protocol ObservableChild: ObservableParent {
            }
            """,
            expandedSource: """
              protocol ObservableParent: ObservableObject {
              }
              protocol ObservableChild: ObservableParent {
              }

              #if MOCKSYN_ENABLE
              internal final class ObservableChildMock: ObservableChild {
                internal let __mockSyn: MockSynRuntime

                internal init(mode: MockSynMode = .strict) {
                  self.__mockSyn = MockSynRuntime(kind: .mock, mode: mode)
                }
              }
              #endif
              """,
            diagnostics: [
                DiagnosticSpec(
                    message: "@Mocking does not generate requirements inherited from ObservableParent. Redeclare required members in the annotated protocol body or use a local mirror protocol.",
                    line: 4,
                    column: 1,
                    severity: .warning
                )
            ]
        )
    }
}
