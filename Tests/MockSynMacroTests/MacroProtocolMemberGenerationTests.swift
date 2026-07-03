import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

extension MockSynMacroTests {
    func testMockingGeneratesSupportedProtocolMembers() {
        assertExpansion(
            """
            @Mocking
            protocol UserService {
                init(seed: String)
                var currentUser: String { get }
                var token: String? { get set }
                static var version: String { get }
                static var build: String { get set }
                static func makeDefault() -> String
                static func reset()
                func load(id: String) -> String
                func combine(_ name: String, retry: Int) -> String
                func save(_ user: String) throws
                func refresh() async
                func fetch(id: String) async throws -> Int
                subscript(key: String) -> String? { get set }
            }
            """,
            expandedSource: """
              protocol UserService {
                  init(seed: String)
                  var currentUser: String { get }
                  var token: String? { get set }
                  static var version: String { get }
                  static var build: String { get set }
                  static func makeDefault() -> String
                  static func reset()
                  func load(id: String) -> String
                  func combine(_ name: String, retry: Int) -> String
                  func save(_ user: String) throws
                  func refresh() async
                  func fetch(id: String) async throws -> Int
                  subscript(key: String) -> String? { get set }
              }

              #if MOCKSYN_ENABLE
              internal final class UserServiceMock: UserService {
                internal static let __mockSynStatic = MockSynRuntime(kind: .mock, mode: .strict)
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

                  internal var version: MockSynPropertyStubber<String> {
                    MockSynPropertyStubber(runtime: __mockSyn, getMember: "version.get", setMember: "version.set")
                  }

                  internal var build: MockSynPropertyStubber<String> {
                    MockSynPropertyStubber(runtime: __mockSyn, getMember: "build.get", setMember: "build.set")
                  }

                  internal func makeDefault() -> MockSynStubBuilder<String> {
                    MockSynStubBuilder<String>(runtime: __mockSyn, member: "makeDefault()", matchers: [])
                  }

                  internal func reset() -> MockSynStubBuilder<Void> {
                    MockSynStubBuilder<Void>(runtime: __mockSyn, member: "reset()", matchers: [])
                  }
                }

                internal struct __MockSynStaticVerify {
                  internal let __mockSyn: MockSynRuntime

                  internal var version: MockSynPropertyVerification<String> {
                    MockSynPropertyVerification(runtime: __mockSyn, getMember: "version.get", setMember: "version.set")
                  }

                  internal var build: MockSynPropertyVerification<String> {
                    MockSynPropertyVerification(runtime: __mockSyn, getMember: "build.get", setMember: "build.set")
                  }

                  internal func makeDefault() -> MockSynVerification {
                    MockSynVerification(runtime: __mockSyn, member: "makeDefault()", matchers: [])
                  }

                  internal func reset() -> MockSynVerification {
                    MockSynVerification(runtime: __mockSyn, member: "reset()", matchers: [])
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

                  internal var currentUser: MockSynPropertyStubber<String> {
                    MockSynPropertyStubber(runtime: __mockSyn, getMember: "currentUser.get", setMember: "currentUser.set")
                  }

                  internal var token: MockSynPropertyStubber<String?> {
                    MockSynPropertyStubber(runtime: __mockSyn, getMember: "token.get", setMember: "token.set")
                  }

                  internal func load(id: MockSynMatcher<String>) -> MockSynStubBuilder1<String, String> {
                    MockSynStubBuilder1<String, String>(runtime: __mockSyn, member: "load(id:)", matchers: [id.erase()])
                  }

                  internal func combine(_ name: MockSynMatcher<String>, retry: MockSynMatcher<Int>) -> MockSynStubBuilder2<String, Int, String> {
                    MockSynStubBuilder2<String, Int, String>(runtime: __mockSyn, member: "combine(_:retry:)", matchers: [name.erase(), retry.erase()])
                  }

                  internal func save(_ user: MockSynMatcher<String>) -> MockSynStubBuilder1<String, Void> {
                    MockSynStubBuilder1<String, Void>(runtime: __mockSyn, member: "save(_:)", matchers: [user.erase()])
                  }

                  internal func refresh() -> MockSynStubBuilder<Void> {
                    MockSynStubBuilder<Void>(runtime: __mockSyn, member: "refresh()", matchers: [])
                  }

                  internal func fetch(id: MockSynMatcher<String>) -> MockSynStubBuilder1<String, Int> {
                    MockSynStubBuilder1<String, Int>(runtime: __mockSyn, member: "fetch(id:)", matchers: [id.erase()])
                  }

                  internal func `subscript`(key: MockSynMatcher<String>) -> MockSynSubscriptStubber<String?> {
                    MockSynSubscriptStubber(runtime: __mockSyn, getMember: "subscript(key:).get", setMember: "subscript(key:).set", indexMatchers: [key.erase()])
                  }
                }

                internal struct __MockSynVerify {
                  internal let __mockSyn: MockSynRuntime

                  internal var currentUser: MockSynPropertyVerification<String> {
                    MockSynPropertyVerification(runtime: __mockSyn, getMember: "currentUser.get", setMember: "currentUser.set")
                  }

                  internal var token: MockSynPropertyVerification<String?> {
                    MockSynPropertyVerification(runtime: __mockSyn, getMember: "token.get", setMember: "token.set")
                  }

                  internal func load(id: MockSynMatcher<String>) -> MockSynVerification {
                    MockSynVerification(runtime: __mockSyn, member: "load(id:)", matchers: [id.erase()])
                  }

                  internal func combine(_ name: MockSynMatcher<String>, retry: MockSynMatcher<Int>) -> MockSynVerification {
                    MockSynVerification(runtime: __mockSyn, member: "combine(_:retry:)", matchers: [name.erase(), retry.erase()])
                  }

                  internal func save(_ user: MockSynMatcher<String>) -> MockSynVerification {
                    MockSynVerification(runtime: __mockSyn, member: "save(_:)", matchers: [user.erase()])
                  }

                  internal func refresh() -> MockSynVerification {
                    MockSynVerification(runtime: __mockSyn, member: "refresh()", matchers: [])
                  }

                  internal func fetch(id: MockSynMatcher<String>) -> MockSynVerification {
                    MockSynVerification(runtime: __mockSyn, member: "fetch(id:)", matchers: [id.erase()])
                  }

                  internal func `subscript`(key: MockSynMatcher<String>) -> MockSynSubscriptVerification<String?> {
                    MockSynSubscriptVerification(runtime: __mockSyn, getMember: "subscript(key:).get", setMember: "subscript(key:).set", indexMatchers: [key.erase()])
                  }
                }

                internal init(seed: String) {
                  self.__mockSyn = MockSynRuntime(kind: .mock, mode: .strict)
                }

                internal var currentUser: String {
                  get {
                    __mockSyn.resolve(member: "currentUser.get", arguments: [], returnType: String.self)
                  }
                }

                internal var token: String? {
                  get {
                    __mockSyn.resolve(member: "token.get", arguments: [], returnType: String?.self)
                  }
                  set {
                    __mockSyn.resolveVoid(member: "token.set", arguments: [newValue as Any])
                  }
                }

                internal static var version: String {
                  get {
                    __mockSynStatic.resolve(member: "version.get", arguments: [], returnType: String.self)
                  }
                }

                internal static var build: String {
                  get {
                    __mockSynStatic.resolve(member: "build.get", arguments: [], returnType: String.self)
                  }
                  set {
                    __mockSynStatic.resolveVoid(member: "build.set", arguments: [newValue as Any])
                  }
                }

                internal static func makeDefault() -> String {
                  return __mockSynStatic.resolve(member: "makeDefault()", arguments: [], returnType: String.self)
                }

                internal static func reset() {
                  __mockSynStatic.resolveVoid(member: "reset()", arguments: [])
                }

                internal func load(id: String) -> String {
                  return __mockSyn.resolve(member: "load(id:)", arguments: [id as Any], returnType: String.self)
                }

                internal func combine(_ name: String, retry: Int) -> String {
                  return __mockSyn.resolve(member: "combine(_:retry:)", arguments: [name as Any, retry as Any], returnType: String.self)
                }

                internal func save(_ user: String) throws {
                  try __mockSyn.resolveVoidThrowing(member: "save(_:)", arguments: [user as Any])
                }

                internal func refresh() async {
                  __mockSyn.resolveVoid(member: "refresh()", arguments: [])
                }

                internal func fetch(id: String) async throws -> Int {
                  return try __mockSyn.resolveThrowing(member: "fetch(id:)", arguments: [id as Any], returnType: Int.self)
                }

                internal subscript(key: String) -> String? {
                  get {
                    __mockSyn.resolve(member: "subscript(key:).get", arguments: [key as Any], returnType: String?.self)
                  }
                  set {
                    __mockSyn.resolveVoid(member: "subscript(key:).set", arguments: [key as Any, newValue as Any])
                  }
                }
              }
              #endif
              """
        )
    }

    func testMockingGeneratesGenericSubscriptMembers() {
        assertExpansion(
            """
            @Mocking
            protocol GenericLookup {
                subscript<Value: Sendable>(key: String, default defaultValue: Value) -> Value { get set }
                subscript<Value>(optional key: String) -> Value? where Value: Equatable { get }
            }
            """,
            expandedSource: """
              protocol GenericLookup {
                  subscript<Value: Sendable>(key: String, default defaultValue: Value) -> Value { get set }
                  subscript<Value>(optional key: String) -> Value? where Value: Equatable { get }
              }

              #if MOCKSYN_ENABLE
              internal final class GenericLookupMock: GenericLookup {
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

                  internal func `subscript`<Value: Sendable>(key: MockSynMatcher<String>, default defaultValue: MockSynMatcher<Value>) -> MockSynSubscriptStubber<Value> {
                    MockSynSubscriptStubber(runtime: __mockSyn, getMember: "subscript<Value: Sendable>(key:default:).get", setMember: "subscript<Value: Sendable>(key:default:).set", indexMatchers: [key.erase(), defaultValue.erase()])
                  }

                  internal func `subscript`<Value>(optional key: MockSynMatcher<String>) -> MockSynSubscriptStubber<Value?> where Value: Equatable {
                    MockSynSubscriptStubber(runtime: __mockSyn, getMember: "subscript<Value>(optional:) where Value: Equatable.get", setMember: "subscript<Value>(optional:) where Value: Equatable.set", indexMatchers: [key.erase()])
                  }
                }

                internal struct __MockSynVerify {
                  internal let __mockSyn: MockSynRuntime

                  internal func `subscript`<Value: Sendable>(key: MockSynMatcher<String>, default defaultValue: MockSynMatcher<Value>) -> MockSynSubscriptVerification<Value> {
                    MockSynSubscriptVerification(runtime: __mockSyn, getMember: "subscript<Value: Sendable>(key:default:).get", setMember: "subscript<Value: Sendable>(key:default:).set", indexMatchers: [key.erase(), defaultValue.erase()])
                  }

                  internal func `subscript`<Value>(optional key: MockSynMatcher<String>) -> MockSynSubscriptVerification<Value?> where Value: Equatable {
                    MockSynSubscriptVerification(runtime: __mockSyn, getMember: "subscript<Value>(optional:) where Value: Equatable.get", setMember: "subscript<Value>(optional:) where Value: Equatable.set", indexMatchers: [key.erase()])
                  }
                }

                internal subscript <Value: Sendable>(key: String, default defaultValue: Value) -> Value {
                  get {
                    __mockSyn.resolve(member: "subscript<Value: Sendable>(key:default:).get", arguments: [key as Any, defaultValue as Any], returnType: Value.self)
                  }
                  set {
                    __mockSyn.resolveVoid(member: "subscript<Value: Sendable>(key:default:).set", arguments: [key as Any, defaultValue as Any, newValue as Any])
                  }
                }

                internal subscript <Value>(optional key: String) -> Value? where Value: Equatable {
                  get {
                    __mockSyn.resolve(member: "subscript<Value>(optional:) where Value: Equatable.get", arguments: [key as Any], returnType: Value?.self)
                  }
                }
              }
              #endif
              """
        )
    }
}
