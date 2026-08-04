import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

extension MockSynMacroTests {
    func testPrivateSetterGeneratesReadOnlyPropertyApis() {
        assertExpansion(
            """
            @Mocking
            class Counter {
                private(set) var count: Int = 0
            }
            """,
            expandedSource: """
              class Counter {
                  private(set) var count: Int = 0
              }

              #if MOCKSYN_ENABLE
              internal final class CounterMock: Counter {
                internal let __mockSyn: MockSynRuntime

                internal init(mode: MockSynMode = .strict) {
                  self.__mockSyn = MockSynRuntime(kind: .mock, mode: mode)
                  super.init()
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

                  internal var count: MockSynNonThrowingReadOnlyPropertyStubber<Int> {
                    MockSynNonThrowingReadOnlyPropertyStubber(runtime: __mockSyn, getMember: "count.get")
                  }
                }

                internal struct __MockSynVerify {
                  internal let __mockSyn: MockSynRuntime

                  internal var count: MockSynReadOnlyPropertyVerification<Int> {
                    MockSynReadOnlyPropertyVerification(runtime: __mockSyn, getMember: "count.get")
                  }
                }

                internal override var count: Int {
                  get {
                    __mockSyn.resolve(member: "count.get", arguments: [], returnType: Int.self)
                  }
                }
              }
              #endif
              """
        )
    }

    func testPrivateClassMembersAndInitializerAreIgnoredWhenUsableInitializerExists() {
        assertExpansion(
            """
            @Mocking
            class UserService {
                private init(secret: String) {
                }

                init(value: String) {
                }

                private func helper() -> String {
                    "secret"
                }

                private var token: String {
                    "secret"
                }

                private subscript(secret: String) -> String {
                    secret
                }
            }
            """,
            expandedSource: """
              class UserService {
                  private init(secret: String) {
                  }

                  init(value: String) {
                  }

                  private func helper() -> String {
                      "secret"
                  }

                  private var token: String {
                      "secret"
                  }

                  private subscript(secret: String) -> String {
                      secret
                  }
              }

              #if MOCKSYN_ENABLE
              internal final class UserServiceMock: UserService {
                internal let __mockSyn: MockSynRuntime

                internal init(value: String, mode: MockSynMode = .strict) {
                  self.__mockSyn = MockSynRuntime(kind: .mock, mode: mode)
                  super.init(value: value)
                }
              }
              #endif
              """
        )
    }

    func testClassWithOnlyPrivateInitializersEmitsDiagnostic() {
        assertExpansion(
            """
            @Mocking
            class UserService {
                private init(secret: String) {
                }
            }
            """,
            expandedSource: """
              class UserService {
                  private init(secret: String) {
                  }
              }
              """,
            diagnostics: [
                DiagnosticSpec(
                    message: "MockSyn cannot subclass a class whose declared designated initializers are all private. Add an internal or broader designated initializer, or mock a protocol instead.",
                    line: 1,
                    column: 1,
                    severity: .error
                ),
            ]
        )
    }

    func testConvenienceInitializerIsNotForwardedWhenDesignatedInitializerExists() {
        assertExpansion(
            """
            @Mocking
            class UserService {
                init(seed: String) {
                }

                convenience init() {
                    self.init(seed: "default")
                }
            }
            """,
            expandedSource: """
              class UserService {
                  init(seed: String) {
                  }

                  convenience init() {
                      self.init(seed: "default")
                  }
              }

              #if MOCKSYN_ENABLE
              internal final class UserServiceMock: UserService {
                internal let __mockSyn: MockSynRuntime

                internal init(seed: String, mode: MockSynMode = .strict) {
                  self.__mockSyn = MockSynRuntime(kind: .mock, mode: mode)
                  super.init(seed: seed)
                }
              }
              #endif
              """
        )
    }

    func testPrivateConvenienceInitializerUsesImplicitDesignatedInitializer() {
        assertExpansion(
            """
            @Mocking
            class UserService {
                private convenience init(seed: String) {
                    self.init()
                }
            }
            """,
            expandedSource: """
              class UserService {
                  private convenience init(seed: String) {
                      self.init()
                  }
              }

              #if MOCKSYN_ENABLE
              internal final class UserServiceMock: UserService {
                internal let __mockSyn: MockSynRuntime

                internal init(mode: MockSynMode = .strict) {
                  self.__mockSyn = MockSynRuntime(kind: .mock, mode: mode)
                  super.init()
                }
              }
              #endif
              """
        )
    }

    func testAccessibleConvenienceDoesNotHidePrivateDesignatedInitializerDiagnostic() {
        assertExpansion(
            """
            @Mocking
            class UserService {
                private init(seed: String) {
                }

                convenience init() {
                    self.init(seed: "default")
                }
            }
            """,
            expandedSource: """
              class UserService {
                  private init(seed: String) {
                  }

                  convenience init() {
                      self.init(seed: "default")
                  }
              }
              """,
            diagnostics: [
                DiagnosticSpec(
                    message: "MockSyn cannot subclass a class whose declared designated initializers are all private. Add an internal or broader designated initializer, or mock a protocol instead.",
                    line: 1,
                    column: 1,
                    severity: .error
                ),
            ]
        )
    }
}
