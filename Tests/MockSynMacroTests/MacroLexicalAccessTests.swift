import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

extension MockSynMacroTests {
    #if canImport(SwiftSyntax600)
    func testMockingInheritsPublicExtensionAccess() {
        assertLexicalExtensionAccess(modifier: "public", expectedAccess: "public")
    }

    func testMockingInheritsPackageExtensionAccess() {
        assertLexicalExtensionAccess(modifier: "package", expectedAccess: "package")
    }

    func testMockingInheritsFileprivateExtensionAccess() {
        assertLexicalExtensionAccess(modifier: "fileprivate", expectedAccess: "fileprivate")
    }

    func testMockingInheritsPrivateExtensionAccess() {
        assertLexicalExtensionAccess(modifier: "private", expectedAccess: "private")
    }
    #endif

    func testMockingDoesNotInheritAccessFromLexicalNominalType() {
        assertExpansion(
            """
            public struct Services {
                @Mocking
                protocol UserService {
                }
            }
            """,
            expandedSource: """
              public struct Services {
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
              }
              """
        )
    }

    func testWideningDiagnosticReportsRequestedAndDeclarationAccess() {
        assertExpansion(
            """
            @Mocking(access: .package)
            private protocol UserService {
            }
            """,
            expandedSource: """
              private protocol UserService {
              }
              """,
            diagnostics: [
                DiagnosticSpec(
                    message: "MockSyn cannot generate package access for a declaration with private access",
                    line: 1,
                    column: 1,
                    severity: .error
                ),
            ]
        )
    }

    #if canImport(SwiftSyntax600)
    private func assertLexicalExtensionAccess(modifier: String, expectedAccess: String) {
        let expectedMemberAccess = expectedAccess == "private" ? "fileprivate" : expectedAccess
        assertExpansion(
            """
            struct Services {
            }

            \(modifier) extension Services {
                @Mocking
                protocol UserService {
                }
            }
            """,
            expandedSource: """
              struct Services {
              }

              \(modifier) extension Services {
                  protocol UserService {
                  }

                  #if MOCKSYN_ENABLE
                  final class UserServiceMock: UserService {
                    \(expectedMemberAccess) let __mockSyn: MockSynRuntime

                    \(expectedMemberAccess) init(mode: MockSynMode = .strict) {
                      self.__mockSyn = MockSynRuntime(kind: .mock, mode: mode)
                    }
                  }
                  #endif
              }
              """
        )
    }
    #endif
}
