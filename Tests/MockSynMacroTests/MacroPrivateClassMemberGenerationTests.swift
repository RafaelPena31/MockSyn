import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

extension MockSynMacroTests {
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
                    message: "MockSyn cannot subclass a class whose declared initializers are all private. Add an internal or broader initializer, or mock a protocol instead.",
                    line: 1,
                    column: 1,
                    severity: .error
                ),
            ]
        )
    }
}
