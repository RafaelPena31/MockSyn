import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

extension MockSynMacroTests {
    func testMockingGeneratesStaticStubbingAndVerificationApiForProtocolMembers() {
        assertExpansion(
            """
            @Mocking
            protocol StaticFactory {
                static var version: String { get set }
                static func make(id: String) -> String
                static func ping()
            }
            """,
            expandedSource: """
              protocol StaticFactory {
                  static var version: String { get set }
                  static func make(id: String) -> String
                  static func ping()
              }

              #if MOCKSYN_ENABLE
              internal final class StaticFactoryMock: StaticFactory {
                internal static let __mockSynStatic = MockSynRuntime.global(kind: .mock, mode: .strict)
                internal let __mockSyn: MockSynRuntime

                internal init(mode: MockSynMode = .strict) {
                  self.__mockSyn = MockSynRuntime(kind: .mock, mode: mode)
                }
                internal static var given: __MockSynStaticGiven {
                  __MockSynStaticGiven(__mockSyn: __mockSynStatic)
                }

                internal static var when: __MockSynStaticGiven {
                  given
                }

                internal static var verify: __MockSynStaticVerify {
                  __MockSynStaticVerify(__mockSyn: __mockSynStatic)
                }

                internal static func confirmStaticVerified() throws {
                  try __mockSynStatic.confirmVerified()
                }

                internal static func checkUnnecessaryStaticStubs() throws {
                  try __mockSynStatic.checkUnnecessaryStubs()
                }

                internal static func resetStatic(_ scope: MockSynResetScope = .all) {
                  __mockSynStatic.reset(scope)
                }

                internal struct __MockSynStaticGiven {
                  internal let __mockSyn: MockSynRuntime

                  internal var version: MockSynNonThrowingPropertyStubber<String> {
                    MockSynNonThrowingPropertyStubber(runtime: __mockSyn, getMember: "version.get", setMember: "version.set")
                  }

                  internal func make(id: MockSynMatcher<String>) -> MockSynNonThrowingStubBuilder1<String, String> {
                    MockSynNonThrowingStubBuilder1<String, String>(runtime: __mockSyn, member: "make(id:)", matchers: [id.erase()])
                  }

                  internal func ping() -> MockSynNonThrowingStubBuilder<Void> {
                    MockSynNonThrowingStubBuilder<Void>(runtime: __mockSyn, member: "ping()", matchers: [])
                  }
                }

                internal struct __MockSynStaticVerify {
                  internal let __mockSyn: MockSynRuntime

                  internal var version: MockSynPropertyVerification<String> {
                    MockSynPropertyVerification(runtime: __mockSyn, getMember: "version.get", setMember: "version.set")
                  }

                  internal func make(id: MockSynMatcher<String>) -> MockSynVerification {
                    MockSynVerification(runtime: __mockSyn, member: "make(id:)", matchers: [id.erase()])
                  }

                  internal func ping() -> MockSynVerification {
                    MockSynVerification(runtime: __mockSyn, member: "ping()", matchers: [])
                  }
                }

                internal static var version: String {
                  get {
                    __mockSynStatic.resolve(member: "version.get", arguments: [], returnType: String.self)
                  }
                  set {
                    __mockSynStatic.resolveVoid(member: "version.set", arguments: [newValue as Any])
                  }
                }

                internal static func make(id: String) -> String {
                  return __mockSynStatic.resolve(member: "make(id:)", arguments: [id as Any], returnType: String.self)
                }

                internal static func ping() {
                  __mockSynStatic.resolveVoid(member: "ping()", arguments: [])
                }
              }
              #endif
              """
        )
    }

    func testMockingGeneratesStaticThrowingProtocolMembers() {
        assertExpansion(
            """
            @Mocking
            protocol StaticThrowingService {
                static func fetch() throws -> String
                static func save() throws
            }
            """,
            expandedSource: """
              protocol StaticThrowingService {
                  static func fetch() throws -> String
                  static func save() throws
              }

              #if MOCKSYN_ENABLE
              internal final class StaticThrowingServiceMock: StaticThrowingService {
                internal static let __mockSynStatic = MockSynRuntime.global(kind: .mock, mode: .strict)
                internal let __mockSyn: MockSynRuntime

                internal init(mode: MockSynMode = .strict) {
                  self.__mockSyn = MockSynRuntime(kind: .mock, mode: mode)
                }
                internal static var given: __MockSynStaticGiven {
                  __MockSynStaticGiven(__mockSyn: __mockSynStatic)
                }

                internal static var when: __MockSynStaticGiven {
                  given
                }

                internal static var verify: __MockSynStaticVerify {
                  __MockSynStaticVerify(__mockSyn: __mockSynStatic)
                }

                internal static func confirmStaticVerified() throws {
                  try __mockSynStatic.confirmVerified()
                }

                internal static func checkUnnecessaryStaticStubs() throws {
                  try __mockSynStatic.checkUnnecessaryStubs()
                }

                internal static func resetStatic(_ scope: MockSynResetScope = .all) {
                  __mockSynStatic.reset(scope)
                }

                internal struct __MockSynStaticGiven {
                  internal let __mockSyn: MockSynRuntime

                  internal func fetch() -> MockSynStubBuilder<String> {
                    MockSynStubBuilder<String>(runtime: __mockSyn, member: "fetch()", matchers: [])
                  }

                  internal func save() -> MockSynStubBuilder<Void> {
                    MockSynStubBuilder<Void>(runtime: __mockSyn, member: "save()", matchers: [])
                  }
                }

                internal struct __MockSynStaticVerify {
                  internal let __mockSyn: MockSynRuntime

                  internal func fetch() -> MockSynVerification {
                    MockSynVerification(runtime: __mockSyn, member: "fetch()", matchers: [])
                  }

                  internal func save() -> MockSynVerification {
                    MockSynVerification(runtime: __mockSyn, member: "save()", matchers: [])
                  }
                }

                internal static func fetch() throws -> String {
                  return try __mockSynStatic.resolveThrowing(member: "fetch()", arguments: [], returnType: String.self)
                }

                internal static func save() throws {
                  try __mockSynStatic.resolveVoidThrowing(member: "save()", arguments: [])
                }
              }
              #endif
              """
        )
    }

    func testMockingGeneratesRethrowingMembersWithNonThrowingResolution() {
        assertExpansion(
            """
            @Mocking
            protocol RethrowingService {
                func transform(_ operation: @escaping () throws -> String) rethrows -> String
                func consume(_ operation: @escaping () throws -> Void) rethrows
                static func make(_ operation: @escaping () throws -> String) rethrows -> String
                static func save(_ operation: @escaping () throws -> Void) rethrows
            }
            """,
            expandedSource: """
              protocol RethrowingService {
                  func transform(_ operation: @escaping () throws -> String) rethrows -> String
                  func consume(_ operation: @escaping () throws -> Void) rethrows
                  static func make(_ operation: @escaping () throws -> String) rethrows -> String
                  static func save(_ operation: @escaping () throws -> Void) rethrows
              }

              #if MOCKSYN_ENABLE
              internal final class RethrowingServiceMock: RethrowingService {
                internal static let __mockSynStatic = MockSynRuntime.global(kind: .mock, mode: .strict)
                internal let __mockSyn: MockSynRuntime

                internal init(mode: MockSynMode = .strict) {
                  self.__mockSyn = MockSynRuntime(kind: .mock, mode: mode)
                }
                internal static var given: __MockSynStaticGiven {
                  __MockSynStaticGiven(__mockSyn: __mockSynStatic)
                }

                internal static var when: __MockSynStaticGiven {
                  given
                }

                internal static var verify: __MockSynStaticVerify {
                  __MockSynStaticVerify(__mockSyn: __mockSynStatic)
                }

                internal static func confirmStaticVerified() throws {
                  try __mockSynStatic.confirmVerified()
                }

                internal static func checkUnnecessaryStaticStubs() throws {
                  try __mockSynStatic.checkUnnecessaryStubs()
                }

                internal static func resetStatic(_ scope: MockSynResetScope = .all) {
                  __mockSynStatic.reset(scope)
                }

                internal struct __MockSynStaticGiven {
                  internal let __mockSyn: MockSynRuntime

                  internal func make(_ operation: MockSynMatcher<() throws -> String>) -> MockSynRethrowingStubBuilder1<() throws -> String, String> {
                    MockSynRethrowingStubBuilder1<() throws -> String, String>(runtime: __mockSyn, member: "make(_:)", matchers: [operation.erase()])
                  }

                  internal func save(_ operation: MockSynMatcher<() throws -> Void>) -> MockSynRethrowingStubBuilder1<() throws -> Void, Void> {
                    MockSynRethrowingStubBuilder1<() throws -> Void, Void>(runtime: __mockSyn, member: "save(_:)", matchers: [operation.erase()])
                  }
                }

                internal struct __MockSynStaticVerify {
                  internal let __mockSyn: MockSynRuntime

                  internal func make(_ operation: MockSynMatcher<() throws -> String>) -> MockSynVerification {
                    MockSynVerification(runtime: __mockSyn, member: "make(_:)", matchers: [operation.erase()])
                  }

                  internal func save(_ operation: MockSynMatcher<() throws -> Void>) -> MockSynVerification {
                    MockSynVerification(runtime: __mockSyn, member: "save(_:)", matchers: [operation.erase()])
                  }
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
                  return __mockSyn.resolve(member: "transform(_:)", arguments: [operation as Any], returnType: String.self)
                }

                internal func consume(_ operation: @escaping () throws -> Void) rethrows {
                  __mockSyn.resolveVoid(member: "consume(_:)", arguments: [operation as Any])
                }

                internal static func make(_ operation: @escaping () throws -> String) rethrows -> String {
                  return __mockSynStatic.resolve(member: "make(_:)", arguments: [operation as Any], returnType: String.self)
                }

                internal static func save(_ operation: @escaping () throws -> Void) rethrows {
                  __mockSynStatic.resolveVoid(member: "save(_:)", arguments: [operation as Any])
                }
              }
              #endif
              """
        )
    }

    func testMockingGeneratesEffectfulPropertyAccessors() {
        assertExpansion(
            """
            @Mocking
            protocol EffectfulPropertyService {
                var asyncName: String { get async }
                var throwingName: String { get throws }
                var asyncThrowingName: String { get async throws }
                static var staticAsyncThrowingName: String { get async throws }
            }
            """,
            expandedSource: """
              protocol EffectfulPropertyService {
                  var asyncName: String { get async }
                  var throwingName: String { get throws }
                  var asyncThrowingName: String { get async throws }
                  static var staticAsyncThrowingName: String { get async throws }
              }

              #if MOCKSYN_ENABLE
              internal final class EffectfulPropertyServiceMock: EffectfulPropertyService {
                internal static let __mockSynStatic = MockSynRuntime.global(kind: .mock, mode: .strict)
                internal let __mockSyn: MockSynRuntime

                internal init(mode: MockSynMode = .strict) {
                  self.__mockSyn = MockSynRuntime(kind: .mock, mode: mode)
                }
                internal static var given: __MockSynStaticGiven {
                  __MockSynStaticGiven(__mockSyn: __mockSynStatic)
                }

                internal static var when: __MockSynStaticGiven {
                  given
                }

                internal static var verify: __MockSynStaticVerify {
                  __MockSynStaticVerify(__mockSyn: __mockSynStatic)
                }

                internal static func confirmStaticVerified() throws {
                  try __mockSynStatic.confirmVerified()
                }

                internal static func checkUnnecessaryStaticStubs() throws {
                  try __mockSynStatic.checkUnnecessaryStubs()
                }

                internal static func resetStatic(_ scope: MockSynResetScope = .all) {
                  __mockSynStatic.reset(scope)
                }

                internal struct __MockSynStaticGiven {
                  internal let __mockSyn: MockSynRuntime

                  internal var staticAsyncThrowingName: MockSynPropertyStubber<String> {
                    MockSynPropertyStubber(runtime: __mockSyn, getMember: "staticAsyncThrowingName.get")
                  }
                }

                internal struct __MockSynStaticVerify {
                  internal let __mockSyn: MockSynRuntime

                  internal var staticAsyncThrowingName: MockSynReadOnlyPropertyVerification<String> {
                    MockSynReadOnlyPropertyVerification(runtime: __mockSyn, getMember: "staticAsyncThrowingName.get")
                  }
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

                  internal var asyncName: MockSynNonThrowingReadOnlyPropertyStubber<String> {
                    MockSynNonThrowingReadOnlyPropertyStubber(runtime: __mockSyn, getMember: "asyncName.get")
                  }

                  internal var throwingName: MockSynPropertyStubber<String> {
                    MockSynPropertyStubber(runtime: __mockSyn, getMember: "throwingName.get")
                  }

                  internal var asyncThrowingName: MockSynPropertyStubber<String> {
                    MockSynPropertyStubber(runtime: __mockSyn, getMember: "asyncThrowingName.get")
                  }
                }

                internal struct __MockSynVerify {
                  internal let __mockSyn: MockSynRuntime

                  internal var asyncName: MockSynReadOnlyPropertyVerification<String> {
                    MockSynReadOnlyPropertyVerification(runtime: __mockSyn, getMember: "asyncName.get")
                  }

                  internal var throwingName: MockSynReadOnlyPropertyVerification<String> {
                    MockSynReadOnlyPropertyVerification(runtime: __mockSyn, getMember: "throwingName.get")
                  }

                  internal var asyncThrowingName: MockSynReadOnlyPropertyVerification<String> {
                    MockSynReadOnlyPropertyVerification(runtime: __mockSyn, getMember: "asyncThrowingName.get")
                  }
                }

                internal var asyncName: String {
                  get async {
                    __mockSyn.resolve(member: "asyncName.get", arguments: [], returnType: String.self)
                  }
                }

                internal var throwingName: String {
                  get throws {
                    try __mockSyn.resolveThrowing(member: "throwingName.get", arguments: [], returnType: String.self)
                  }
                }

                internal var asyncThrowingName: String {
                  get async throws {
                    try __mockSyn.resolveThrowing(member: "asyncThrowingName.get", arguments: [], returnType: String.self)
                  }
                }

                internal static var staticAsyncThrowingName: String {
                  get async throws {
                    try __mockSynStatic.resolveThrowing(member: "staticAsyncThrowingName.get", arguments: [], returnType: String.self)
                  }
                }
              }
              #endif
              """
        )
    }
}
