import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

extension MockSynMacroTests {
    func testMockingDisambiguatesReturnTypeOnlyOverloads() {
        assertExpansion(
            """
            @Mocking
            protocol ReturnOverloadedService {
                var status: Bool { get }
                func refresh()
                func load() -> String
                func load() -> Int
                func load() -> String?
            }
            """,
            expandedSource: """
              protocol ReturnOverloadedService {
                  var status: Bool { get }
                  func refresh()
                  func load() -> String
                  func load() -> Int
                  func load() -> String?
              }

              #if MOCKSYN_ENABLE
              internal final class ReturnOverloadedServiceMock: ReturnOverloadedService {
                internal let __mockSyn: MockSynRuntime

                internal init(mode: MockSynMode = .strict) {
                  self.__mockSyn = MockSynRuntime(kind: .mock, mode: mode)
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

                  internal var status: MockSynNonThrowingReadOnlyPropertyStubber<Bool> {
                    MockSynNonThrowingReadOnlyPropertyStubber(runtime: __mockSyn, getMember: "status.get")
                  }

                  internal func refresh() -> MockSynNonThrowingStubBuilder<Void> {
                    MockSynNonThrowingStubBuilder<Void>(runtime: __mockSyn, member: "refresh()", matchers: [])
                  }

                  internal func loadReturningString() -> MockSynNonThrowingStubBuilder<String> {
                    MockSynNonThrowingStubBuilder<String>(runtime: __mockSyn, member: "load() -> String", matchers: [])
                  }

                  internal func loadReturningInt() -> MockSynNonThrowingStubBuilder<Int> {
                    MockSynNonThrowingStubBuilder<Int>(runtime: __mockSyn, member: "load() -> Int", matchers: [])
                  }

                  internal func loadReturningStringOptional() -> MockSynNonThrowingStubBuilder<String?> {
                    MockSynNonThrowingStubBuilder<String?>(runtime: __mockSyn, member: "load() -> String?", matchers: [])
                  }
                }

                internal struct __MockSynVerify {
                  internal let __mockSyn: MockSynRuntime

                  internal var status: MockSynReadOnlyPropertyVerification<Bool> {
                    MockSynReadOnlyPropertyVerification(runtime: __mockSyn, getMember: "status.get")
                  }

                  internal func refresh() -> MockSynVerification {
                    MockSynVerification(runtime: __mockSyn, member: "refresh()", matchers: [])
                  }

                  internal func loadReturningString() -> MockSynVerification {
                    MockSynVerification(runtime: __mockSyn, member: "load() -> String", matchers: [])
                  }

                  internal func loadReturningInt() -> MockSynVerification {
                    MockSynVerification(runtime: __mockSyn, member: "load() -> Int", matchers: [])
                  }

                  internal func loadReturningStringOptional() -> MockSynVerification {
                    MockSynVerification(runtime: __mockSyn, member: "load() -> String?", matchers: [])
                  }
                }

                internal var status: Bool {
                  get {
                    __mockSyn.resolve(member: "status.get", arguments: [], returnType: Bool.self)
                  }
                }

                internal func refresh() {
                  __mockSyn.resolveVoid(member: "refresh()", arguments: [])
                }

                internal func load() -> String {
                  return __mockSyn.resolve(member: "load() -> String", arguments: [], returnType: String.self)
                }

                internal func load() -> Int {
                  return __mockSyn.resolve(member: "load() -> Int", arguments: [], returnType: Int.self)
                }

                internal func load() -> String? {
                  return __mockSyn.resolve(member: "load() -> String?", arguments: [], returnType: String?.self)
                }
              }
              #endif
              """
        )
    }

    func testMockingDisambiguatesReturnTypeOnlyOverloadsWithCollidingDslSuffixes() {
        assertExpansion(
            """
            @Mocking
            protocol ReturnOverloadedService {
                func refresh()
                func item() -> ReturnOverloadNamespace.Value
                func item() -> ReturnOverloadNamespaceValue
                func other() -> String
                func other() -> Int
                func find(id: String) -> ReturnOverloadNamespace.Value
                func find(id: String) -> ReturnOverloadNamespaceValue
            }
            """,
            expandedSource: """
              protocol ReturnOverloadedService {
                  func refresh()
                  func item() -> ReturnOverloadNamespace.Value
                  func item() -> ReturnOverloadNamespaceValue
                  func other() -> String
                  func other() -> Int
                  func find(id: String) -> ReturnOverloadNamespace.Value
                  func find(id: String) -> ReturnOverloadNamespaceValue
              }

              #if MOCKSYN_ENABLE
              internal final class ReturnOverloadedServiceMock: ReturnOverloadedService {
                internal let __mockSyn: MockSynRuntime

                internal init(mode: MockSynMode = .strict) {
                  self.__mockSyn = MockSynRuntime(kind: .mock, mode: mode)
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

                  internal func refresh() -> MockSynNonThrowingStubBuilder<Void> {
                    MockSynNonThrowingStubBuilder<Void>(runtime: __mockSyn, member: "refresh()", matchers: [])
                  }

                  internal func itemReturningReturnOverloadNamespaceValue() -> MockSynNonThrowingStubBuilder<ReturnOverloadNamespace.Value> {
                    MockSynNonThrowingStubBuilder<ReturnOverloadNamespace.Value>(runtime: __mockSyn, member: "item() -> ReturnOverloadNamespace.Value", matchers: [])
                  }

                  internal func itemReturningReturnOverloadNamespaceValueOverload2() -> MockSynNonThrowingStubBuilder<ReturnOverloadNamespaceValue> {
                    MockSynNonThrowingStubBuilder<ReturnOverloadNamespaceValue>(runtime: __mockSyn, member: "item() -> ReturnOverloadNamespaceValue", matchers: [])
                  }

                  internal func otherReturningString() -> MockSynNonThrowingStubBuilder<String> {
                    MockSynNonThrowingStubBuilder<String>(runtime: __mockSyn, member: "other() -> String", matchers: [])
                  }

                  internal func otherReturningInt() -> MockSynNonThrowingStubBuilder<Int> {
                    MockSynNonThrowingStubBuilder<Int>(runtime: __mockSyn, member: "other() -> Int", matchers: [])
                  }

                  internal func findReturningReturnOverloadNamespaceValue(id: MockSynMatcher<String>) -> MockSynNonThrowingStubBuilder1<String, ReturnOverloadNamespace.Value> {
                    MockSynNonThrowingStubBuilder1<String, ReturnOverloadNamespace.Value>(runtime: __mockSyn, member: "find(id:) -> ReturnOverloadNamespace.Value", matchers: [id.erase()])
                  }

                  internal func findReturningReturnOverloadNamespaceValueOverload2(id: MockSynMatcher<String>) -> MockSynNonThrowingStubBuilder1<String, ReturnOverloadNamespaceValue> {
                    MockSynNonThrowingStubBuilder1<String, ReturnOverloadNamespaceValue>(runtime: __mockSyn, member: "find(id:) -> ReturnOverloadNamespaceValue", matchers: [id.erase()])
                  }
                }

                internal struct __MockSynVerify {
                  internal let __mockSyn: MockSynRuntime

                  internal func refresh() -> MockSynVerification {
                    MockSynVerification(runtime: __mockSyn, member: "refresh()", matchers: [])
                  }

                  internal func itemReturningReturnOverloadNamespaceValue() -> MockSynVerification {
                    MockSynVerification(runtime: __mockSyn, member: "item() -> ReturnOverloadNamespace.Value", matchers: [])
                  }

                  internal func itemReturningReturnOverloadNamespaceValueOverload2() -> MockSynVerification {
                    MockSynVerification(runtime: __mockSyn, member: "item() -> ReturnOverloadNamespaceValue", matchers: [])
                  }

                  internal func otherReturningString() -> MockSynVerification {
                    MockSynVerification(runtime: __mockSyn, member: "other() -> String", matchers: [])
                  }

                  internal func otherReturningInt() -> MockSynVerification {
                    MockSynVerification(runtime: __mockSyn, member: "other() -> Int", matchers: [])
                  }

                  internal func findReturningReturnOverloadNamespaceValue(id: MockSynMatcher<String>) -> MockSynVerification {
                    MockSynVerification(runtime: __mockSyn, member: "find(id:) -> ReturnOverloadNamespace.Value", matchers: [id.erase()])
                  }

                  internal func findReturningReturnOverloadNamespaceValueOverload2(id: MockSynMatcher<String>) -> MockSynVerification {
                    MockSynVerification(runtime: __mockSyn, member: "find(id:) -> ReturnOverloadNamespaceValue", matchers: [id.erase()])
                  }
                }

                internal func refresh() {
                  __mockSyn.resolveVoid(member: "refresh()", arguments: [])
                }

                internal func item() -> ReturnOverloadNamespace.Value {
                  return __mockSyn.resolve(member: "item() -> ReturnOverloadNamespace.Value", arguments: [], returnType: ReturnOverloadNamespace.Value.self)
                }

                internal func item() -> ReturnOverloadNamespaceValue {
                  return __mockSyn.resolve(member: "item() -> ReturnOverloadNamespaceValue", arguments: [], returnType: ReturnOverloadNamespaceValue.self)
                }

                internal func other() -> String {
                  return __mockSyn.resolve(member: "other() -> String", arguments: [], returnType: String.self)
                }

                internal func other() -> Int {
                  return __mockSyn.resolve(member: "other() -> Int", arguments: [], returnType: Int.self)
                }

                internal func find(id: String) -> ReturnOverloadNamespace.Value {
                  return __mockSyn.resolve(member: "find(id:) -> ReturnOverloadNamespace.Value", arguments: [id as Any], returnType: ReturnOverloadNamespace.Value.self)
                }

                internal func find(id: String) -> ReturnOverloadNamespaceValue {
                  return __mockSyn.resolve(member: "find(id:) -> ReturnOverloadNamespaceValue", arguments: [id as Any], returnType: ReturnOverloadNamespaceValue.self)
                }
              }
              #endif
              """
        )
    }
}
