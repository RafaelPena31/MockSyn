import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

extension MockSynMacroTests {
    func testSpyingGeneratesDelegatingProtocolMembers() {
        assertExpansion(
            """
            @Spying
            protocol CacheStore {
                var count: Int { get }
                var token: String? { get set }
                func load(id: String) -> String
                func fail() throws
                func mutate(_ value: inout Int)
                func normalize(_ value: inout Int) -> String
                func stream() async -> String
                func save(_ value: String) async throws
                subscript(key: String) -> String? { get }
                subscript(label key: String) -> String? { get }
            }
            """,
            expandedSource: """
              protocol CacheStore {
                  var count: Int { get }
                  var token: String? { get set }
                  func load(id: String) -> String
                  func fail() throws
                  func mutate(_ value: inout Int)
                  func normalize(_ value: inout Int) -> String
                  func stream() async -> String
                  func save(_ value: String) async throws
                  subscript(key: String) -> String? { get }
                  subscript(label key: String) -> String? { get }
              }

              #if MOCKSYN_ENABLE
              internal final class CacheStoreSpy: CacheStore {
                internal let __mockSyn: MockSynRuntime
                internal let __mockSynWrapped: any CacheStore

                internal init(wrapping __mockSynWrapped: any CacheStore, mode: MockSynMode = .strict) {
                  self.__mockSyn = MockSynRuntime(kind: .spy, mode: mode)
                  self.__mockSynWrapped = __mockSynWrapped
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

                  internal var token: MockSynNonThrowingPropertyStubber<String?> {
                    MockSynNonThrowingPropertyStubber(runtime: __mockSyn, getMember: "token.get", setMember: "token.set")
                  }

                  internal func load(id: MockSynMatcher<String>) -> MockSynNonThrowingStubBuilder1<String, String> {
                    MockSynNonThrowingStubBuilder1<String, String>(runtime: __mockSyn, member: "load(id:)", matchers: [id.erase()])
                  }

                  internal func fail() -> MockSynStubBuilder<Void> {
                    MockSynStubBuilder<Void>(runtime: __mockSyn, member: "fail()", matchers: [])
                  }

                  internal func mutate(_ value: MockSynMatcher<Int>) -> MockSynNonThrowingStubBuilder1<Int, Void> {
                    MockSynNonThrowingStubBuilder1<Int, Void>(runtime: __mockSyn, member: "mutate(_:)", matchers: [value.erase()])
                  }

                  internal func normalize(_ value: MockSynMatcher<Int>) -> MockSynNonThrowingStubBuilder1<Int, String> {
                    MockSynNonThrowingStubBuilder1<Int, String>(runtime: __mockSyn, member: "normalize(_:)", matchers: [value.erase()])
                  }

                  internal func stream() -> MockSynNonThrowingStubBuilder<String> {
                    MockSynNonThrowingStubBuilder<String>(runtime: __mockSyn, member: "stream()", matchers: [])
                  }

                  internal func save(_ value: MockSynMatcher<String>) -> MockSynStubBuilder1<String, Void> {
                    MockSynStubBuilder1<String, Void>(runtime: __mockSyn, member: "save(_:)", matchers: [value.erase()])
                  }

                  internal func `subscript`(key: MockSynMatcher<String>) -> MockSynNonThrowingReadOnlySubscriptStubber<String?> {
                    MockSynNonThrowingReadOnlySubscriptStubber(runtime: __mockSyn, getMember: "subscript(key:).get", indexMatchers: [key.erase()])
                  }

                  internal func `subscript`(label key: MockSynMatcher<String>) -> MockSynNonThrowingReadOnlySubscriptStubber<String?> {
                    MockSynNonThrowingReadOnlySubscriptStubber(runtime: __mockSyn, getMember: "subscript(label:).get", indexMatchers: [key.erase()])
                  }
                }

                internal struct __MockSynVerify {
                  internal let __mockSyn: MockSynRuntime

                  internal var count: MockSynReadOnlyPropertyVerification<Int> {
                    MockSynReadOnlyPropertyVerification(runtime: __mockSyn, getMember: "count.get")
                  }

                  internal var token: MockSynPropertyVerification<String?> {
                    MockSynPropertyVerification(runtime: __mockSyn, getMember: "token.get", setMember: "token.set")
                  }

                  internal func load(id: MockSynMatcher<String>) -> MockSynVerification {
                    MockSynVerification(runtime: __mockSyn, member: "load(id:)", matchers: [id.erase()])
                  }

                  internal func fail() -> MockSynVerification {
                    MockSynVerification(runtime: __mockSyn, member: "fail()", matchers: [])
                  }

                  internal func mutate(_ value: MockSynMatcher<Int>) -> MockSynVerification {
                    MockSynVerification(runtime: __mockSyn, member: "mutate(_:)", matchers: [value.erase()])
                  }

                  internal func normalize(_ value: MockSynMatcher<Int>) -> MockSynVerification {
                    MockSynVerification(runtime: __mockSyn, member: "normalize(_:)", matchers: [value.erase()])
                  }

                  internal func stream() -> MockSynVerification {
                    MockSynVerification(runtime: __mockSyn, member: "stream()", matchers: [])
                  }

                  internal func save(_ value: MockSynMatcher<String>) -> MockSynVerification {
                    MockSynVerification(runtime: __mockSyn, member: "save(_:)", matchers: [value.erase()])
                  }

                  internal func `subscript`(key: MockSynMatcher<String>) -> MockSynReadOnlySubscriptVerification<String?> {
                    MockSynReadOnlySubscriptVerification(runtime: __mockSyn, getMember: "subscript(key:).get", indexMatchers: [key.erase()])
                  }

                  internal func `subscript`(label key: MockSynMatcher<String>) -> MockSynReadOnlySubscriptVerification<String?> {
                    MockSynReadOnlySubscriptVerification(runtime: __mockSyn, getMember: "subscript(label:).get", indexMatchers: [key.erase()])
                  }
                }

                internal var count: Int {
                  get {
                    __mockSyn.resolve(member: "count.get", arguments: [], returnType: Int.self, fallback: {
                        self.__mockSynWrapped.count
                      })
                  }
                }

                internal var token: String? {
                  get {
                    __mockSyn.resolve(member: "token.get", arguments: [], returnType: String?.self, fallback: {
                        self.__mockSynWrapped.token
                      })
                  }
                  set {
                    __mockSyn.resolveVoid(member: "token.set", arguments: [newValue as Any])
                  }
                }

                internal func load(id: String) -> String {
                  return __mockSyn.resolve(member: "load(id:)", arguments: [id as Any], returnType: String.self, fallback: {
                      self.__mockSynWrapped.load(id: id)
                    })
                }

                internal func fail() throws {
                  try __mockSyn.resolveVoidThrowing(member: "fail()", arguments: [], fallback: {
                      try self.__mockSynWrapped.fail()
                    })
                }

                internal func mutate(_ value: inout Int) {
                  __mockSyn.record(member: "mutate(_:)", arguments: [value as Any])
                  __mockSynWrapped.mutate(&value)
                }

                internal func normalize(_ value: inout Int) -> String {
                  __mockSyn.record(member: "normalize(_:)", arguments: [value as Any])
                  return __mockSynWrapped.normalize(&value)
                }

                internal func stream() async -> String {
                  await __mockSynWrapped.stream()
                }

                internal func save(_ value: String) async throws {
                  try await __mockSynWrapped.save(value)
                }

                internal subscript(key: String) -> String? {
                  get {
                    __mockSyn.resolve(member: "subscript(key:).get", arguments: [key as Any], returnType: String?.self, fallback: {
                        self.__mockSynWrapped[key]
                      })
                  }
                }

                internal subscript(label key: String) -> String? {
                  get {
                    __mockSyn.resolve(member: "subscript(label:).get", arguments: [key as Any], returnType: String?.self, fallback: {
                        self.__mockSynWrapped[label: key]
                      })
                  }
                }
              }
              #endif
              """
        )
    }

    func testSpyingGeneratesRethrowingMembersWithRethrowingFallbackResolution() {
        assertExpansion(
            """
            @Spying
            protocol RethrowingService {
                func transform(_ operation: @escaping () throws -> String) rethrows -> String
                func consume(_ operation: @escaping () throws -> Void) rethrows
            }
            """,
            expandedSource: """
              protocol RethrowingService {
                  func transform(_ operation: @escaping () throws -> String) rethrows -> String
                  func consume(_ operation: @escaping () throws -> Void) rethrows
              }

              #if MOCKSYN_ENABLE
              internal final class RethrowingServiceSpy: RethrowingService {
                internal let __mockSyn: MockSynRuntime
                internal let __mockSynWrapped: any RethrowingService

                internal init(wrapping __mockSynWrapped: any RethrowingService, mode: MockSynMode = .strict) {
                  self.__mockSyn = MockSynRuntime(kind: .spy, mode: mode)
                  self.__mockSynWrapped = __mockSynWrapped
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

                  internal func transform(_ operation: MockSynMatcher<() throws -> String>) -> MockSynRethrowingStubBuilder1<() throws -> String, String> {
                    MockSynRethrowingStubBuilder1<() throws -> String, String>(runtime: __mockSyn, member: "transform(_:)", matchers: [operation.erase()])
                  }

                  internal func consume(_ operation: MockSynMatcher<() throws -> Void>) -> MockSynRethrowingStubBuilder1<() throws -> Void, Void> {
                    MockSynRethrowingStubBuilder1<() throws -> Void, Void>(runtime: __mockSyn, member: "consume(_:)", matchers: [operation.erase()])
                  }
                }

                internal struct __MockSynVerify {
                  internal let __mockSyn: MockSynRuntime

                  internal func transform(_ operation: MockSynMatcher<() throws -> String>) -> MockSynVerification {
                    MockSynVerification(runtime: __mockSyn, member: "transform(_:)", matchers: [operation.erase()])
                  }

                  internal func consume(_ operation: MockSynMatcher<() throws -> Void>) -> MockSynVerification {
                    MockSynVerification(runtime: __mockSyn, member: "consume(_:)", matchers: [operation.erase()])
                  }
                }

                internal func transform(_ operation: @escaping () throws -> String) rethrows -> String {
                  return try __mockSyn.resolveRethrowing(member: "transform(_:)", arguments: [operation as Any], returnType: String.self, fallback: {
                      try self.__mockSynWrapped.transform(operation)
                    })
                }

                internal func consume(_ operation: @escaping () throws -> Void) rethrows {
                  try __mockSyn.resolveVoidRethrowing(member: "consume(_:)", arguments: [operation as Any], fallback: {
                      try self.__mockSynWrapped.consume(operation)
                    })
                }
              }
              #endif
              """
        )
    }

    func testSpyingGeneratesDelegatingUnderscoredSubscript() {
        assertExpansion(
            """
            @Spying
            protocol CacheStore {
                subscript(_ key: String) -> String? { get }
            }
            """,
            expandedSource: """
              protocol CacheStore {
                  subscript(_ key: String) -> String? { get }
              }

              #if MOCKSYN_ENABLE
              internal final class CacheStoreSpy: CacheStore {
                internal let __mockSyn: MockSynRuntime
                internal let __mockSynWrapped: any CacheStore

                internal init(wrapping __mockSynWrapped: any CacheStore, mode: MockSynMode = .strict) {
                  self.__mockSyn = MockSynRuntime(kind: .spy, mode: mode)
                  self.__mockSynWrapped = __mockSynWrapped
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

                  internal func `subscript`(_ key: MockSynMatcher<String>) -> MockSynNonThrowingReadOnlySubscriptStubber<String?> {
                    MockSynNonThrowingReadOnlySubscriptStubber(runtime: __mockSyn, getMember: "subscript(_:).get", indexMatchers: [key.erase()])
                  }
                }

                internal struct __MockSynVerify {
                  internal let __mockSyn: MockSynRuntime

                  internal func `subscript`(_ key: MockSynMatcher<String>) -> MockSynReadOnlySubscriptVerification<String?> {
                    MockSynReadOnlySubscriptVerification(runtime: __mockSyn, getMember: "subscript(_:).get", indexMatchers: [key.erase()])
                  }
                }

                internal subscript(_ key: String) -> String? {
                  get {
                    __mockSyn.resolve(member: "subscript(_:).get", arguments: [key as Any], returnType: String?.self, fallback: {
                        self.__mockSynWrapped[key]
                      })
                  }
                }
              }
              #endif
              """
        )
    }
}
