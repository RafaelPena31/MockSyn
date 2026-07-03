import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

#if canImport(MockSynMacros)
@testable import MockSynMacros

private let testMacros: [String: Macro.Type] = [
    "Mocking": MockingMacro.self,
    "Stubbing": StubbingMacro.self,
    "Spying": SpyingMacro.self,
]
#endif

final class MockSynMacroTests: XCTestCase {
    func testPluginProvidesBlockOneMacros() {
        #if canImport(MockSynMacros)
        let plugin = MockSynPlugin()

        XCTAssertEqual(plugin.providingMacros.count, 3)
        XCTAssertTrue(plugin.providingMacros.contains { $0 == MockingMacro.self })
        XCTAssertTrue(plugin.providingMacros.contains { $0 == StubbingMacro.self })
        XCTAssertTrue(plugin.providingMacros.contains { $0 == SpyingMacro.self })
        #endif
    }

    func testMockingGeneratesInternalStrictMockByDefault() {
        assertExpansion(
            """
            @Mocking
            protocol UserService {
            }
            """,
            expandedSource: """
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
              """
        )
    }

    func testMockingGeneratesPackageAccessWhenDeclarationAllowsIt() {
        assertExpansion(
            """
            @Mocking(access: .package)
            package protocol UserService {
            }
            """,
            expandedSource: """
              package protocol UserService {
              }

              #if MOCKSYN_ENABLE
              package final class UserServiceMock: UserService {
                package let __mockSyn: MockSynRuntime

                package init(mode: MockSynMode = .strict) {
                  self.__mockSyn = MockSynRuntime(kind: .mock, mode: mode)
                }
              }
              #endif
              """
        )
    }

    func testMockingGeneratesFileprivateAccessWhenDeclarationAllowsIt() {
        assertExpansion(
            """
            @Mocking(access: .fileprivate)
            fileprivate protocol UserService {
            }
            """,
            expandedSource: """
              fileprivate protocol UserService {
              }

              #if MOCKSYN_ENABLE
              fileprivate final class UserServiceMock: UserService {
                fileprivate let __mockSyn: MockSynRuntime

                fileprivate init(mode: MockSynMode = .strict) {
                  self.__mockSyn = MockSynRuntime(kind: .mock, mode: mode)
                }
              }
              #endif
              """
        )
    }

    func testMockingGeneratesPrivateAccessWhenDeclarationAllowsIt() {
        assertExpansion(
            """
            @Mocking(access: .private)
            private protocol UserService {
            }
            """,
            expandedSource: """
              private protocol UserService {
              }

              #if MOCKSYN_ENABLE
              private final class UserServiceMock: UserService {
                private let __mockSyn: MockSynRuntime

                private init(mode: MockSynMode = .strict) {
                  self.__mockSyn = MockSynRuntime(kind: .mock, mode: mode)
                }
              }
              #endif
              """
        )
    }

    func testStubbingGeneratesInternalRelaxedStubByDefault() {
        assertExpansion(
            """
            @Stubbing
            protocol AnalyticsService {
            }
            """,
            expandedSource: """
              protocol AnalyticsService {
              }

              #if MOCKSYN_ENABLE
              internal final class AnalyticsServiceStub: AnalyticsService {
                internal let __mockSyn: MockSynRuntime

                internal init(mode: MockSynMode = .relaxed) {
                  self.__mockSyn = MockSynRuntime(kind: .stub, mode: mode)
                }
              }
              #endif
              """
        )
    }

    func testSpyingGeneratesInternalStrictSpyWithWrappedImplementation() {
        assertExpansion(
            """
            @Spying
            protocol CacheStore {
            }
            """,
            expandedSource: """
              protocol CacheStore {
              }

              #if MOCKSYN_ENABLE
              internal final class CacheStoreSpy: CacheStore {
                internal let __mockSyn: MockSynRuntime
                internal let __mockSynWrapped: any CacheStore

                internal init(wrapping __mockSynWrapped: any CacheStore, mode: MockSynMode = .strict) {
                  self.__mockSyn = MockSynRuntime(kind: .spy, mode: mode)
                  self.__mockSynWrapped = __mockSynWrapped
                }
              }
              #endif
              """
        )
    }

    func testMockingUsesCustomNameAccessAndMode() {
        assertExpansion(
            """
            @Mocking(name: "MockUserService", access: .public, mode: .relaxed)
            public protocol UserService {
            }
            """,
            expandedSource: """
              public protocol UserService {
              }

              #if MOCKSYN_ENABLE
              public final class MockUserService: UserService {
                public let __mockSyn: MockSynRuntime

                public init(mode: MockSynMode = .relaxed) {
                  self.__mockSyn = MockSynRuntime(kind: .mock, mode: mode)
                }
              }
              #endif
              """
        )
    }

    func testMockingSupportsSimpleProtocolInheritance() {
        assertExpansion(
            """
            protocol UserService {
            }

            @Mocking
            protocol AdminUserService: UserService {
            }
            """,
            expandedSource: """
              protocol UserService {
              }
              protocol AdminUserService: UserService {
              }

              #if MOCKSYN_ENABLE
              internal final class AdminUserServiceMock: AdminUserService {
                internal let __mockSyn: MockSynRuntime

                internal init(mode: MockSynMode = .strict) {
                  self.__mockSyn = MockSynRuntime(kind: .mock, mode: mode)
                }
              }
              #endif
              """
        )
    }

    func testMockingGeneratesSubclassForNonFinalClass() {
        assertExpansion(
            """
            @Mocking
            class UserService {
            }
            """,
            expandedSource: """
              class UserService {
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

    func testStubbingGeneratesSubclassForNonFinalClass() {
        assertExpansion(
            """
            @Stubbing
            class AnalyticsService {
            }
            """,
            expandedSource: """
              class AnalyticsService {
              }

              #if MOCKSYN_ENABLE
              internal final class AnalyticsServiceStub: AnalyticsService {
                internal let __mockSyn: MockSynRuntime

                internal init(mode: MockSynMode = .relaxed) {
                  self.__mockSyn = MockSynRuntime(kind: .stub, mode: mode)
                  super.init()
                }
              }
              #endif
              """
        )
    }

    func testSpyingGeneratesSubclassForNonFinalClassWithWrappedImplementation() {
        assertExpansion(
            """
            @Spying
            class CacheStore {
            }
            """,
            expandedSource: """
              class CacheStore {
              }

              #if MOCKSYN_ENABLE
              internal final class CacheStoreSpy: CacheStore {
                internal let __mockSyn: MockSynRuntime
                internal let __mockSynWrapped: CacheStore

                internal init(wrapping __mockSynWrapped: CacheStore, mode: MockSynMode = .strict) {
                  self.__mockSyn = MockSynRuntime(kind: .spy, mode: mode)
                  self.__mockSynWrapped = __mockSynWrapped
                  super.init()
                }
              }
              #endif
              """
        )
    }

    func testMockingGeneratesSubclassForNSObjectBackedClass() {
        assertExpansion(
            """
            @Mocking
            @objcMembers
            class LegacyService: NSObject {
            }
            """,
            expandedSource: """
              @objcMembers
              class LegacyService: NSObject {
              }

              #if MOCKSYN_ENABLE
              internal final class LegacyServiceMock: LegacyService {
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

    func testMockingTreatsOpenClassAsPublicDeclaration() {
        assertExpansion(
            """
            @Mocking(access: .public)
            open class UserService {
            }
            """,
            expandedSource: """
              open class UserService {
              }

              #if MOCKSYN_ENABLE
              public final class UserServiceMock: UserService {
                public let __mockSyn: MockSynRuntime

                public init(mode: MockSynMode = .strict) {
                  self.__mockSyn = MockSynRuntime(kind: .mock, mode: mode)
                  super.init()
                }
              }
              #endif
              """
        )
    }

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
                    fatalError("MockSyn member version is not configured")
                  }
                }

                internal static var build: String {
                  get {
                    fatalError("MockSyn member build is not configured")
                  }
                  set {
                  }
                }

                internal static func makeDefault() -> String {
                  fatalError("MockSyn member makeDefault() is not configured")
                }

                internal static func reset() {
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

                internal struct __MockSynGiven {
                  internal let __mockSyn: MockSynRuntime

                  internal var count: MockSynPropertyStubber<Int> {
                    MockSynPropertyStubber(runtime: __mockSyn, getMember: "count.get", setMember: "count.set")
                  }

                  internal var token: MockSynPropertyStubber<String?> {
                    MockSynPropertyStubber(runtime: __mockSyn, getMember: "token.get", setMember: "token.set")
                  }

                  internal func load(id: MockSynMatcher<String>) -> MockSynStubBuilder1<String, String> {
                    MockSynStubBuilder1<String, String>(runtime: __mockSyn, member: "load(id:)", matchers: [id.erase()])
                  }

                  internal func fail() -> MockSynStubBuilder<Void> {
                    MockSynStubBuilder<Void>(runtime: __mockSyn, member: "fail()", matchers: [])
                  }

                  internal func mutate(_ value: MockSynMatcher<Int>) -> MockSynStubBuilder1<Int, Void> {
                    MockSynStubBuilder1<Int, Void>(runtime: __mockSyn, member: "mutate(_:)", matchers: [value.erase()])
                  }

                  internal func normalize(_ value: MockSynMatcher<Int>) -> MockSynStubBuilder1<Int, String> {
                    MockSynStubBuilder1<Int, String>(runtime: __mockSyn, member: "normalize(_:)", matchers: [value.erase()])
                  }

                  internal func stream() -> MockSynStubBuilder<String> {
                    MockSynStubBuilder<String>(runtime: __mockSyn, member: "stream()", matchers: [])
                  }

                  internal func save(_ value: MockSynMatcher<String>) -> MockSynStubBuilder1<String, Void> {
                    MockSynStubBuilder1<String, Void>(runtime: __mockSyn, member: "save(_:)", matchers: [value.erase()])
                  }

                  internal func `subscript`(key: MockSynMatcher<String>) -> MockSynSubscriptStubber<String?> {
                    MockSynSubscriptStubber(runtime: __mockSyn, getMember: "subscript(key:).get", setMember: "subscript(key:).set", indexMatchers: [key.erase()])
                  }

                  internal func `subscript`(label key: MockSynMatcher<String>) -> MockSynSubscriptStubber<String?> {
                    MockSynSubscriptStubber(runtime: __mockSyn, getMember: "subscript(label:).get", setMember: "subscript(label:).set", indexMatchers: [key.erase()])
                  }
                }

                internal struct __MockSynVerify {
                  internal let __mockSyn: MockSynRuntime

                  internal var count: MockSynPropertyVerification<Int> {
                    MockSynPropertyVerification(runtime: __mockSyn, getMember: "count.get", setMember: "count.set")
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

                  internal func `subscript`(key: MockSynMatcher<String>) -> MockSynSubscriptVerification<String?> {
                    MockSynSubscriptVerification(runtime: __mockSyn, getMember: "subscript(key:).get", setMember: "subscript(key:).set", indexMatchers: [key.erase()])
                  }

                  internal func `subscript`(label key: MockSynMatcher<String>) -> MockSynSubscriptVerification<String?> {
                    MockSynSubscriptVerification(runtime: __mockSyn, getMember: "subscript(label:).get", setMember: "subscript(label:).set", indexMatchers: [key.erase()])
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

                internal struct __MockSynGiven {
                  internal let __mockSyn: MockSynRuntime

                  internal func `subscript`(_ key: MockSynMatcher<String>) -> MockSynSubscriptStubber<String?> {
                    MockSynSubscriptStubber(runtime: __mockSyn, getMember: "subscript(_:).get", setMember: "subscript(_:).set", indexMatchers: [key.erase()])
                  }
                }

                internal struct __MockSynVerify {
                  internal let __mockSyn: MockSynRuntime

                  internal func `subscript`(_ key: MockSynMatcher<String>) -> MockSynSubscriptVerification<String?> {
                    MockSynSubscriptVerification(runtime: __mockSyn, getMember: "subscript(_:).get", setMember: "subscript(_:).set", indexMatchers: [key.erase()])
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

    func testMockingPreservesSwiftLanguageFeatureMembers() {
        assertExpansion(
            """
            @Mocking
            protocol Processor: Sendable {
                @MainActor var title: String { get }
                func map<Value>(_ value: Value) -> Value where Value: Sendable
                func update(_ value: inout Int)
                func handle(_ action: @escaping (String) -> Void)
                func clone() -> Self
                func collect(_ values: Int...) -> Int
            }
            """,
            expandedSource: """
              protocol Processor: Sendable {
                  @MainActor var title: String { get }
                  func map<Value>(_ value: Value) -> Value where Value: Sendable
                  func update(_ value: inout Int)
                  func handle(_ action: @escaping (String) -> Void)
                  func clone() -> Self
                  func collect(_ values: Int...) -> Int
              }

              #if MOCKSYN_ENABLE
              internal final class ProcessorMock: Processor {
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

                internal struct __MockSynGiven {
                  internal let __mockSyn: MockSynRuntime

                  internal var title: MockSynPropertyStubber<String> {
                    MockSynPropertyStubber(runtime: __mockSyn, getMember: "title.get", setMember: "title.set")
                  }

                  internal func map<Value>(_ value: MockSynMatcher<Value>) -> MockSynStubBuilder1<Value, Value> where Value: Sendable {
                    MockSynStubBuilder1<Value, Value>(runtime: __mockSyn, member: "map(_:)", matchers: [value.erase()])
                  }

                  internal func update(_ value: MockSynMatcher<Int>) -> MockSynStubBuilder1<Int, Void> {
                    MockSynStubBuilder1<Int, Void>(runtime: __mockSyn, member: "update(_:)", matchers: [value.erase()])
                  }

                  internal func handle(_ action: MockSynMatcher<(String) -> Void>) -> MockSynStubBuilder1<(String) -> Void, Void> {
                    MockSynStubBuilder1<(String) -> Void, Void>(runtime: __mockSyn, member: "handle(_:)", matchers: [action.erase()])
                  }

                  internal func clone() -> MockSynStubBuilder<Self> {
                    MockSynStubBuilder<Self>(runtime: __mockSyn, member: "clone()", matchers: [])
                  }

                  internal func collect(_ values: MockSynMatcher<[Int]>) -> MockSynStubBuilder1<[Int], Int> {
                    MockSynStubBuilder1<[Int], Int>(runtime: __mockSyn, member: "collect(_:)", matchers: [values.erase()])
                  }
                }

                internal struct __MockSynVerify {
                  internal let __mockSyn: MockSynRuntime

                  internal var title: MockSynPropertyVerification<String> {
                    MockSynPropertyVerification(runtime: __mockSyn, getMember: "title.get", setMember: "title.set")
                  }

                  internal func map<Value>(_ value: MockSynMatcher<Value>) -> MockSynVerification where Value: Sendable {
                    MockSynVerification(runtime: __mockSyn, member: "map(_:)", matchers: [value.erase()])
                  }

                  internal func update(_ value: MockSynMatcher<Int>) -> MockSynVerification {
                    MockSynVerification(runtime: __mockSyn, member: "update(_:)", matchers: [value.erase()])
                  }

                  internal func handle(_ action: MockSynMatcher<(String) -> Void>) -> MockSynVerification {
                    MockSynVerification(runtime: __mockSyn, member: "handle(_:)", matchers: [action.erase()])
                  }

                  internal func clone() -> MockSynVerification {
                    MockSynVerification(runtime: __mockSyn, member: "clone()", matchers: [])
                  }

                  internal func collect(_ values: MockSynMatcher<[Int]>) -> MockSynVerification {
                    MockSynVerification(runtime: __mockSyn, member: "collect(_:)", matchers: [values.erase()])
                  }
                }

                @MainActor internal var title: String {
                  get {
                    __mockSyn.resolve(member: "title.get", arguments: [], returnType: String.self)
                  }
                }

                internal func map<Value>(_ value: Value) -> Value where Value: Sendable {
                  return __mockSyn.resolve(member: "map(_:)", arguments: [value as Any], returnType: Value.self)
                }

                internal func update(_ value: inout Int) {
                  __mockSyn.resolveVoid(member: "update(_:)", arguments: [value as Any])
                }

                internal func handle(_ action: @escaping (String) -> Void) {
                  __mockSyn.resolveVoid(member: "handle(_:)", arguments: [action as Any])
                }

                internal func clone() -> Self {
                  return __mockSyn.resolve(member: "clone()", arguments: [], returnType: Self.self)
                }

                internal func collect(_ values: Int...) -> Int {
                  return __mockSyn.resolve(member: "collect(_:)", arguments: [values as Any], returnType: Int.self)
                }
              }
              #endif
              """
        )
    }

    func testSpyingDelegatesSupportedSwiftLanguageFeatureMembers() {
        assertExpansion(
            """
            @Spying
            protocol Processor {
                func update(_ value: inout Int)
                func handle(_ action: @escaping (String) -> Void)
                func collect(_ values: Int...) -> Int
            }
            """,
            expandedSource: """
              protocol Processor {
                  func update(_ value: inout Int)
                  func handle(_ action: @escaping (String) -> Void)
                  func collect(_ values: Int...) -> Int
              }

              #if MOCKSYN_ENABLE
              internal final class ProcessorSpy: Processor {
                internal let __mockSyn: MockSynRuntime
                internal let __mockSynWrapped: any Processor

                internal init(wrapping __mockSynWrapped: any Processor, mode: MockSynMode = .strict) {
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

                internal struct __MockSynGiven {
                  internal let __mockSyn: MockSynRuntime

                  internal func update(_ value: MockSynMatcher<Int>) -> MockSynStubBuilder1<Int, Void> {
                    MockSynStubBuilder1<Int, Void>(runtime: __mockSyn, member: "update(_:)", matchers: [value.erase()])
                  }

                  internal func handle(_ action: MockSynMatcher<(String) -> Void>) -> MockSynStubBuilder1<(String) -> Void, Void> {
                    MockSynStubBuilder1<(String) -> Void, Void>(runtime: __mockSyn, member: "handle(_:)", matchers: [action.erase()])
                  }

                  internal func collect(_ values: MockSynMatcher<[Int]>) -> MockSynStubBuilder1<[Int], Int> {
                    MockSynStubBuilder1<[Int], Int>(runtime: __mockSyn, member: "collect(_:)", matchers: [values.erase()])
                  }
                }

                internal struct __MockSynVerify {
                  internal let __mockSyn: MockSynRuntime

                  internal func update(_ value: MockSynMatcher<Int>) -> MockSynVerification {
                    MockSynVerification(runtime: __mockSyn, member: "update(_:)", matchers: [value.erase()])
                  }

                  internal func handle(_ action: MockSynMatcher<(String) -> Void>) -> MockSynVerification {
                    MockSynVerification(runtime: __mockSyn, member: "handle(_:)", matchers: [action.erase()])
                  }

                  internal func collect(_ values: MockSynMatcher<[Int]>) -> MockSynVerification {
                    MockSynVerification(runtime: __mockSyn, member: "collect(_:)", matchers: [values.erase()])
                  }
                }

                internal func update(_ value: inout Int) {
                  __mockSyn.record(member: "update(_:)", arguments: [value as Any])
                  __mockSynWrapped.update(&value)
                }

                internal func handle(_ action: @escaping (String) -> Void) {
                  __mockSyn.resolveVoid(member: "handle(_:)", arguments: [action as Any], fallback: {
                      self.__mockSynWrapped.handle(action)
                    })
                }

                internal func collect(_ values: Int...) -> Int {
                  return __mockSyn.resolve(member: "collect(_:)", arguments: [values as Any], returnType: Int.self)
                }
              }
              #endif
              """
        )
    }

    func testMockingPreservesGlobalActorOnType() {
        assertExpansion(
            """
            @Mocking
            @MainActor
            protocol MainService {
                func refresh()
            }
            """,
            expandedSource: """
              @MainActor
              protocol MainService {
                  func refresh()
              }

              #if MOCKSYN_ENABLE
              @MainActor internal final class MainServiceMock: MainService {
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

                internal struct __MockSynGiven {
                  internal let __mockSyn: MockSynRuntime

                  internal func refresh() -> MockSynStubBuilder<Void> {
                    MockSynStubBuilder<Void>(runtime: __mockSyn, member: "refresh()", matchers: [])
                  }
                }

                internal struct __MockSynVerify {
                  internal let __mockSyn: MockSynRuntime

                  internal func refresh() -> MockSynVerification {
                    MockSynVerification(runtime: __mockSyn, member: "refresh()", matchers: [])
                  }
                }

                internal func refresh() {
                  __mockSyn.resolveVoid(member: "refresh()", arguments: [])
                }
              }
              #endif
              """
        )
    }

    func testMockingGeneratesGenericClassDouble() {
        assertExpansion(
            """
            @Mocking
            class Box<Value> where Value: Sendable {
                func load(_ value: Value) -> Value {
                    value
                }
            }
            """,
            expandedSource: """
              class Box<Value> where Value: Sendable {
                  func load(_ value: Value) -> Value {
                      value
                  }
              }

              #if MOCKSYN_ENABLE
              internal final class BoxMock<Value>: Box<Value> where Value: Sendable {
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

                internal struct __MockSynGiven {
                  internal let __mockSyn: MockSynRuntime

                  internal func load(_ value: MockSynMatcher<Value>) -> MockSynStubBuilder1<Value, Value> {
                    MockSynStubBuilder1<Value, Value>(runtime: __mockSyn, member: "load(_:)", matchers: [value.erase()])
                  }
                }

                internal struct __MockSynVerify {
                  internal let __mockSyn: MockSynRuntime

                  internal func load(_ value: MockSynMatcher<Value>) -> MockSynVerification {
                    MockSynVerification(runtime: __mockSyn, member: "load(_:)", matchers: [value.erase()])
                  }
                }

                internal override func load(_ value: Value) -> Value {
                  return __mockSyn.resolve(member: "load(_:)", arguments: [value as Any], returnType: Value.self)
                }
              }
              #endif
              """
        )
    }

    func testAssociatedTypeProtocolEmitsDiagnostic() {
        assertExpansion(
            """
            @Mocking
            protocol Repository {
                associatedtype Entity
                func load() -> Entity
            }
            """,
            expandedSource: """
              protocol Repository {
                  associatedtype Entity
                  func load() -> Entity
              }
              """,
            diagnostics: [
                DiagnosticSpec(
                    message: "MockSyn cannot generate protocols with associated types yet. Use a type-erased protocol or concrete wrapper.",
                    line: 1,
                    column: 1,
                    severity: .error
                )
            ]
        )
    }

    func testMockingGeneratesSupportedClassMemberOverrides() {
        assertExpansion(
            """
            @Mocking
            class UserService {
                var storedToken: String = "real"

                var token: String {
                    get { "real" }
                    set { }
                }

                func load(id: String) -> String {
                    "real"
                }

                func save(_ user: String) throws {
                }

                subscript(key: String) -> String {
                    "real"
                }
            }
            """,
            expandedSource: """
              class UserService {
                  var storedToken: String = "real"

                  var token: String {
                      get { "real" }
                      set { }
                  }

                  func load(id: String) -> String {
                      "real"
                  }

                  func save(_ user: String) throws {
                  }

                  subscript(key: String) -> String {
                      "real"
                  }
              }

              #if MOCKSYN_ENABLE
              internal final class UserServiceMock: UserService {
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

                internal struct __MockSynGiven {
                  internal let __mockSyn: MockSynRuntime

                  internal var storedToken: MockSynPropertyStubber<String> {
                    MockSynPropertyStubber(runtime: __mockSyn, getMember: "storedToken.get", setMember: "storedToken.set")
                  }

                  internal var token: MockSynPropertyStubber<String> {
                    MockSynPropertyStubber(runtime: __mockSyn, getMember: "token.get", setMember: "token.set")
                  }

                  internal func load(id: MockSynMatcher<String>) -> MockSynStubBuilder1<String, String> {
                    MockSynStubBuilder1<String, String>(runtime: __mockSyn, member: "load(id:)", matchers: [id.erase()])
                  }

                  internal func save(_ user: MockSynMatcher<String>) -> MockSynStubBuilder1<String, Void> {
                    MockSynStubBuilder1<String, Void>(runtime: __mockSyn, member: "save(_:)", matchers: [user.erase()])
                  }

                  internal func `subscript`(key: MockSynMatcher<String>) -> MockSynSubscriptStubber<String> {
                    MockSynSubscriptStubber(runtime: __mockSyn, getMember: "subscript(key:).get", setMember: "subscript(key:).set", indexMatchers: [key.erase()])
                  }
                }

                internal struct __MockSynVerify {
                  internal let __mockSyn: MockSynRuntime

                  internal var storedToken: MockSynPropertyVerification<String> {
                    MockSynPropertyVerification(runtime: __mockSyn, getMember: "storedToken.get", setMember: "storedToken.set")
                  }

                  internal var token: MockSynPropertyVerification<String> {
                    MockSynPropertyVerification(runtime: __mockSyn, getMember: "token.get", setMember: "token.set")
                  }

                  internal func load(id: MockSynMatcher<String>) -> MockSynVerification {
                    MockSynVerification(runtime: __mockSyn, member: "load(id:)", matchers: [id.erase()])
                  }

                  internal func save(_ user: MockSynMatcher<String>) -> MockSynVerification {
                    MockSynVerification(runtime: __mockSyn, member: "save(_:)", matchers: [user.erase()])
                  }

                  internal func `subscript`(key: MockSynMatcher<String>) -> MockSynSubscriptVerification<String> {
                    MockSynSubscriptVerification(runtime: __mockSyn, getMember: "subscript(key:).get", setMember: "subscript(key:).set", indexMatchers: [key.erase()])
                  }
                }

                internal override var storedToken: String {
                  get {
                    __mockSyn.resolve(member: "storedToken.get", arguments: [], returnType: String.self)
                  }
                  set {
                    __mockSyn.resolveVoid(member: "storedToken.set", arguments: [newValue as Any])
                  }
                }

                internal override var token: String {
                  get {
                    __mockSyn.resolve(member: "token.get", arguments: [], returnType: String.self)
                  }
                  set {
                    __mockSyn.resolveVoid(member: "token.set", arguments: [newValue as Any])
                  }
                }

                internal override func load(id: String) -> String {
                  return __mockSyn.resolve(member: "load(id:)", arguments: [id as Any], returnType: String.self)
                }

                internal override func save(_ user: String) throws {
                  try __mockSyn.resolveVoidThrowing(member: "save(_:)", arguments: [user as Any])
                }

                internal override subscript(key: String) -> String {
                  get {
                    __mockSyn.resolve(member: "subscript(key:).get", arguments: [key as Any], returnType: String.self)
                  }
                }
              }
              #endif
              """
        )
    }

    func testPropertyWithoutExplicitTypeIsIgnored() {
        assertExpansion(
            """
            @Mocking
            class UserService {
                var inferred = "value"
            }
            """,
            expandedSource: """
              class UserService {
                  var inferred = "value"
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

    func testOperatorRequirementEmitsDiagnostic() {
        assertExpansion(
            """
            @Mocking
            protocol ComparableService {
                static func == (lhs: ComparableService, rhs: ComparableService) -> Bool
            }
            """,
            expandedSource: """
              protocol ComparableService {
                  static func == (lhs: ComparableService, rhs: ComparableService) -> Bool
              }
              """,
            diagnostics: [
                DiagnosticSpec(
                    message: "MockSyn cannot generate operator requirements yet. Wrap the operator behind a named method.",
                    line: 1,
                    column: 1,
                    severity: .error
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
                    message: "MockSyn cannot generate operator requirements yet. Wrap the operator behind a named method.",
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
                    severity: .error
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
                    severity: .error
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
                    severity: .error
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

    private func assertExpansion(
        _ source: String,
        expandedSource: String,
        diagnostics: [DiagnosticSpec] = [],
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        #if canImport(MockSynMacros)
        assertMacroExpansion(
            source,
            expandedSource: expandedSource,
            diagnostics: diagnostics,
            macros: testMacros,
            indentationWidth: .spaces(2),
            file: file,
            line: line
        )
        #else
        XCTFail("macros are only supported when running tests for the host platform", file: file, line: line)
        #endif
    }
}
