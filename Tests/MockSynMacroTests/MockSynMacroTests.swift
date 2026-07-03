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

    func testMockingMirrorsClassInitializerParameters() {
        assertExpansion(
            """
            @Mocking
            class UserService {
                init(seed: String) {
                }
            }
            """,
            expandedSource: """
              class UserService {
                  init(seed: String) {
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

    func testMockingMirrorsExplicitZeroArgumentClassInitializer() {
        assertExpansion(
            """
            @Mocking
            class UserService {
                init() {
                }
            }
            """,
            expandedSource: """
              class UserService {
                  init() {
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

    func testMockingMirrorsRequiredClassInitializerWithConfigurableConvenience() {
        assertExpansion(
            """
            @Mocking
            class UserService {
                required init(seed: String) {
                }
            }
            """,
            expandedSource: """
              class UserService {
                  required init(seed: String) {
                  }
              }

              #if MOCKSYN_ENABLE
              internal final class UserServiceMock: UserService {
                internal let __mockSyn: MockSynRuntime

                internal required init(seed: String) {
                  self.__mockSyn = MockSynRuntime(kind: .mock, mode: .strict)
                  super.init(seed: seed)
                }

                internal init(seed: String, mode: MockSynMode = .strict) {
                  self.__mockSyn = MockSynRuntime(kind: .mock, mode: mode)
                  super.init(seed: seed)
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

    func testStubbingMirrorsClassInitializerParameters() {
        assertExpansion(
            """
            @Stubbing
            class AnalyticsService {
                init(seed: String) {
                }
            }
            """,
            expandedSource: """
              class AnalyticsService {
                  init(seed: String) {
                  }
              }

              #if MOCKSYN_ENABLE
              internal final class AnalyticsServiceStub: AnalyticsService {
                internal let __mockSyn: MockSynRuntime

                internal init(seed: String, mode: MockSynMode = .relaxed) {
                  self.__mockSyn = MockSynRuntime(kind: .stub, mode: mode)
                  super.init(seed: seed)
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

    func testSpyingMirrorsClassInitializerParameters() {
        assertExpansion(
            """
            @Spying
            class CacheStore {
                init(seed: String) {
                }
            }
            """,
            expandedSource: """
              class CacheStore {
                  init(seed: String) {
                  }
              }

              #if MOCKSYN_ENABLE
              internal final class CacheStoreSpy: CacheStore {
                internal let __mockSyn: MockSynRuntime
                internal let __mockSynWrapped: CacheStore

                internal init(wrapping __mockSynWrapped: CacheStore, seed: String, mode: MockSynMode = .strict) {
                  self.__mockSyn = MockSynRuntime(kind: .spy, mode: mode)
                  self.__mockSynWrapped = __mockSynWrapped
                  super.init(seed: seed)
                }
              }
              #endif
              """
        )
    }

    func testSpyingMirrorsExplicitZeroArgumentClassInitializer() {
        assertExpansion(
            """
            @Spying
            class CacheStore {
                init() {
                }
            }
            """,
            expandedSource: """
              class CacheStore {
                  init() {
                  }
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

    func testSpyingOnClassWithRequiredInitializerEmitsDiagnostic() {
        assertExpansion(
            """
            @Spying
            class CacheStore {
                required init(seed: String) {
                }
            }
            """,
            expandedSource: """
              class CacheStore {
                  required init(seed: String) {
                  }
              }
              """,
            diagnostics: [
                DiagnosticSpec(
                    message: "MockSyn cannot mirror required class initializers for spies because class spies need a wrapped instance. Prefer a protocol spy or remove the required initializer.",
                    line: 1,
                    column: 1
                )
            ]
        )
    }

    func testMockingClassWithVariadicInitializerEmitsDiagnostic() {
        assertExpansion(
            """
            @Mocking
            class UserService {
                init(values: Int...) {
                }
            }
            """,
            expandedSource: """
              class UserService {
                  init(values: Int...) {
                  }
              }
              """,
            diagnostics: [
                DiagnosticSpec(
                    message: "MockSyn cannot mirror variadic class initializers because Swift cannot forward captured variadic arrays to super.init.",
                    line: 1,
                    column: 1
                )
            ]
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

                  internal func make(id: MockSynMatcher<String>) -> MockSynStubBuilder1<String, String> {
                    MockSynStubBuilder1<String, String>(runtime: __mockSyn, member: "make(id:)", matchers: [id.erase()])
                  }

                  internal func ping() -> MockSynStubBuilder<Void> {
                    MockSynStubBuilder<Void>(runtime: __mockSyn, member: "ping()", matchers: [])
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

                  internal var staticAsyncThrowingName: MockSynPropertyStubber<String> {
                    MockSynPropertyStubber(runtime: __mockSyn, getMember: "staticAsyncThrowingName.get", setMember: "staticAsyncThrowingName.set")
                  }
                }

                internal struct __MockSynStaticVerify {
                  internal let __mockSyn: MockSynRuntime

                  internal var staticAsyncThrowingName: MockSynPropertyVerification<String> {
                    MockSynPropertyVerification(runtime: __mockSyn, getMember: "staticAsyncThrowingName.get", setMember: "staticAsyncThrowingName.set")
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

                  internal var asyncName: MockSynPropertyStubber<String> {
                    MockSynPropertyStubber(runtime: __mockSyn, getMember: "asyncName.get", setMember: "asyncName.set")
                  }

                  internal var throwingName: MockSynPropertyStubber<String> {
                    MockSynPropertyStubber(runtime: __mockSyn, getMember: "throwingName.get", setMember: "throwingName.set")
                  }

                  internal var asyncThrowingName: MockSynPropertyStubber<String> {
                    MockSynPropertyStubber(runtime: __mockSyn, getMember: "asyncThrowingName.get", setMember: "asyncThrowingName.set")
                  }
                }

                internal struct __MockSynVerify {
                  internal let __mockSyn: MockSynRuntime

                  internal var asyncName: MockSynPropertyVerification<String> {
                    MockSynPropertyVerification(runtime: __mockSyn, getMember: "asyncName.get", setMember: "asyncName.set")
                  }

                  internal var throwingName: MockSynPropertyVerification<String> {
                    MockSynPropertyVerification(runtime: __mockSyn, getMember: "throwingName.get", setMember: "throwingName.set")
                  }

                  internal var asyncThrowingName: MockSynPropertyVerification<String> {
                    MockSynPropertyVerification(runtime: __mockSyn, getMember: "asyncThrowingName.get", setMember: "asyncThrowingName.set")
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

    func testSpyingGeneratesDelegatingEffectfulPropertyAccessors() {
        assertExpansion(
            """
            @Spying
            protocol EffectfulPropertyService {
                var asyncName: String { get async }
                var asyncThrowingName: String { get async throws }
            }
            """,
            expandedSource: """
              protocol EffectfulPropertyService {
                  var asyncName: String { get async }
                  var asyncThrowingName: String { get async throws }
              }

              #if MOCKSYN_ENABLE
              internal final class EffectfulPropertyServiceSpy: EffectfulPropertyService {
                internal let __mockSyn: MockSynRuntime
                internal let __mockSynWrapped: any EffectfulPropertyService

                internal init(wrapping __mockSynWrapped: any EffectfulPropertyService, mode: MockSynMode = .strict) {
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

                  internal var asyncName: MockSynPropertyStubber<String> {
                    MockSynPropertyStubber(runtime: __mockSyn, getMember: "asyncName.get", setMember: "asyncName.set")
                  }

                  internal var asyncThrowingName: MockSynPropertyStubber<String> {
                    MockSynPropertyStubber(runtime: __mockSyn, getMember: "asyncThrowingName.get", setMember: "asyncThrowingName.set")
                  }
                }

                internal struct __MockSynVerify {
                  internal let __mockSyn: MockSynRuntime

                  internal var asyncName: MockSynPropertyVerification<String> {
                    MockSynPropertyVerification(runtime: __mockSyn, getMember: "asyncName.get", setMember: "asyncName.set")
                  }

                  internal var asyncThrowingName: MockSynPropertyVerification<String> {
                    MockSynPropertyVerification(runtime: __mockSyn, getMember: "asyncThrowingName.get", setMember: "asyncThrowingName.set")
                  }
                }

                internal var asyncName: String {
                  get async {
                    __mockSyn.record(member: "asyncName.get", arguments: [])
                    return await self.__mockSynWrapped.asyncName
                  }
                }

                internal var asyncThrowingName: String {
                  get async throws {
                    __mockSyn.record(member: "asyncThrowingName.get", arguments: [])
                    return try await self.__mockSynWrapped.asyncThrowingName
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

                internal func reset(_ scope: MockSynResetScope = .all) {
                  __mockSyn.reset(scope)
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

                  internal func clone() -> MockSynStubBuilder<ProcessorMock> {
                    MockSynStubBuilder<ProcessorMock>(runtime: __mockSyn, member: "clone()", matchers: [])
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

                internal func reset(_ scope: MockSynResetScope = .all) {
                  __mockSyn.reset(scope)
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
                  return __mockSyn.resolve(member: "collect(_:)", arguments: [values as Any], returnType: Int.self, fallback: {
                        switch values.count {
                    case 0:
                      return self.__mockSynWrapped.collect()
                    case 1:
                      return self.__mockSynWrapped.collect(values[0])
                    case 2:
                      return self.__mockSynWrapped.collect(values[0], values[1])
                    case 3:
                      return self.__mockSynWrapped.collect(values[0], values[1], values[2])
                    case 4:
                      return self.__mockSynWrapped.collect(values[0], values[1], values[2], values[3])
                    case 5:
                      return self.__mockSynWrapped.collect(values[0], values[1], values[2], values[3], values[4])
                    case 6:
                      return self.__mockSynWrapped.collect(values[0], values[1], values[2], values[3], values[4], values[5])
                    case 7:
                      return self.__mockSynWrapped.collect(values[0], values[1], values[2], values[3], values[4], values[5], values[6])
                    case 8:
                      return self.__mockSynWrapped.collect(values[0], values[1], values[2], values[3], values[4], values[5], values[6], values[7])
                        default:
                          fatalError("MockSyn spy cannot delegate variadic member collect(_:) with more than 8 values")
                        }
                  })
                }
              }
              #endif
              """
        )
    }

    func testSpyingDelegatesLabeledVariadicVoidMembers() {
        assertExpansion(
            """
            @Spying
            protocol Recorder {
                func record(_ prefix: String, suffix: String, values: Int...)
            }
            """,
            expandedSource: """
              protocol Recorder {
                  func record(_ prefix: String, suffix: String, values: Int...)
              }

              #if MOCKSYN_ENABLE
              internal final class RecorderSpy: Recorder {
                internal let __mockSyn: MockSynRuntime
                internal let __mockSynWrapped: any Recorder

                internal init(wrapping __mockSynWrapped: any Recorder, mode: MockSynMode = .strict) {
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

                  internal func record(_ prefix: MockSynMatcher<String>, suffix: MockSynMatcher<String>, values: MockSynMatcher<[Int]>) -> MockSynStubBuilder<Void> {
                    MockSynStubBuilder<Void>(runtime: __mockSyn, member: "record(_:suffix:values:)", matchers: [prefix.erase(), suffix.erase(), values.erase()])
                  }
                }

                internal struct __MockSynVerify {
                  internal let __mockSyn: MockSynRuntime

                  internal func record(_ prefix: MockSynMatcher<String>, suffix: MockSynMatcher<String>, values: MockSynMatcher<[Int]>) -> MockSynVerification {
                    MockSynVerification(runtime: __mockSyn, member: "record(_:suffix:values:)", matchers: [prefix.erase(), suffix.erase(), values.erase()])
                  }
                }

                internal func record(_ prefix: String, suffix: String, values: Int...) {
                  __mockSyn.resolveVoid(member: "record(_:suffix:values:)", arguments: [prefix as Any, suffix as Any, values as Any], fallback: {
                        switch values.count {
                    case 0:
                      self.__mockSynWrapped.record(prefix, suffix: suffix)
                    case 1:
                      self.__mockSynWrapped.record(prefix, suffix: suffix, values: values[0])
                    case 2:
                      self.__mockSynWrapped.record(prefix, suffix: suffix, values: values[0], values[1])
                    case 3:
                      self.__mockSynWrapped.record(prefix, suffix: suffix, values: values[0], values[1], values[2])
                    case 4:
                      self.__mockSynWrapped.record(prefix, suffix: suffix, values: values[0], values[1], values[2], values[3])
                    case 5:
                      self.__mockSynWrapped.record(prefix, suffix: suffix, values: values[0], values[1], values[2], values[3], values[4])
                    case 6:
                      self.__mockSynWrapped.record(prefix, suffix: suffix, values: values[0], values[1], values[2], values[3], values[4], values[5])
                    case 7:
                      self.__mockSynWrapped.record(prefix, suffix: suffix, values: values[0], values[1], values[2], values[3], values[4], values[5], values[6])
                    case 8:
                      self.__mockSynWrapped.record(prefix, suffix: suffix, values: values[0], values[1], values[2], values[3], values[4], values[5], values[6], values[7])
                        default:
                          fatalError("MockSyn spy cannot delegate variadic member record(_:suffix:values:) with more than 8 values")
                        }
                  })
                }
              }
              #endif
              """
        )
    }

    func testSpyingLeavesAsyncVariadicMembersStubDriven() {
        assertExpansion(
            """
            @Spying
            protocol AsyncCollector {
                func collect(_ values: Int...) async -> Int
            }
            """,
            expandedSource: """
              protocol AsyncCollector {
                  func collect(_ values: Int...) async -> Int
              }

              #if MOCKSYN_ENABLE
              internal final class AsyncCollectorSpy: AsyncCollector {
                internal let __mockSyn: MockSynRuntime
                internal let __mockSynWrapped: any AsyncCollector

                internal init(wrapping __mockSynWrapped: any AsyncCollector, mode: MockSynMode = .strict) {
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

                  internal func collect(_ values: MockSynMatcher<[Int]>) -> MockSynStubBuilder1<[Int], Int> {
                    MockSynStubBuilder1<[Int], Int>(runtime: __mockSyn, member: "collect(_:)", matchers: [values.erase()])
                  }
                }

                internal struct __MockSynVerify {
                  internal let __mockSyn: MockSynRuntime

                  internal func collect(_ values: MockSynMatcher<[Int]>) -> MockSynVerification {
                    MockSynVerification(runtime: __mockSyn, member: "collect(_:)", matchers: [values.erase()])
                  }
                }

                internal func collect(_ values: Int...) async -> Int {
                  return __mockSyn.resolve(member: "collect(_:)", arguments: [values as Any], returnType: Int.self)
                }
              }
              #endif
              """
        )
    }

    func testSpyingLeavesMultipleVariadicMembersStubDriven() {
        assertExpansion(
            """
            @Spying
            protocol MultiCollector {
                func collect(_ values: Int..., labels: String...) -> String
            }
            """,
            expandedSource: """
              protocol MultiCollector {
                  func collect(_ values: Int..., labels: String...) -> String
              }

              #if MOCKSYN_ENABLE
              internal final class MultiCollectorSpy: MultiCollector {
                internal let __mockSyn: MockSynRuntime
                internal let __mockSynWrapped: any MultiCollector

                internal init(wrapping __mockSynWrapped: any MultiCollector, mode: MockSynMode = .strict) {
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

                  internal func collect(_ values: MockSynMatcher<[Int]>, labels: MockSynMatcher<[String]>) -> MockSynStubBuilder2<[Int], [String], String> {
                    MockSynStubBuilder2<[Int], [String], String>(runtime: __mockSyn, member: "collect(_:labels:)", matchers: [values.erase(), labels.erase()])
                  }
                }

                internal struct __MockSynVerify {
                  internal let __mockSyn: MockSynRuntime

                  internal func collect(_ values: MockSynMatcher<[Int]>, labels: MockSynMatcher<[String]>) -> MockSynVerification {
                    MockSynVerification(runtime: __mockSyn, member: "collect(_:labels:)", matchers: [values.erase(), labels.erase()])
                  }
                }

                internal func collect(_ values: Int..., labels: String...) -> String {
                  return __mockSyn.resolve(member: "collect(_:labels:)", arguments: [values as Any, labels as Any], returnType: String.self)
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

                internal func reset(_ scope: MockSynResetScope = .all) {
                  __mockSyn.reset(scope)
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

                internal func reset(_ scope: MockSynResetScope = .all) {
                  __mockSyn.reset(scope)
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

    func testMockingGeneratesGenericMockForAssociatedTypeProtocol() {
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

              #if MOCKSYN_ENABLE
              internal final class RepositoryMock<Entity>: Repository {
                internal typealias Entity = Entity
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

                  internal func load() -> MockSynStubBuilder<Entity> {
                    MockSynStubBuilder<Entity>(runtime: __mockSyn, member: "load()", matchers: [])
                  }
                }

                internal struct __MockSynVerify {
                  internal let __mockSyn: MockSynRuntime

                  internal func load() -> MockSynVerification {
                    MockSynVerification(runtime: __mockSyn, member: "load()", matchers: [])
                  }
                }

                internal func load() -> Entity {
                  return __mockSyn.resolve(member: "load()", arguments: [], returnType: Entity.self)
                }
              }
              #endif
              """
        )
    }

    func testMockingPreservesAssociatedTypeConstraints() {
        assertExpansion(
            """
            @Mocking
            protocol Repository {
                associatedtype ID: Hashable
                associatedtype Entity: Sendable where Entity: Equatable
                func load(id: ID) -> Entity
            }
            """,
            expandedSource: """
              protocol Repository {
                  associatedtype ID: Hashable
                  associatedtype Entity: Sendable where Entity: Equatable
                  func load(id: ID) -> Entity
              }

              #if MOCKSYN_ENABLE
              internal final class RepositoryMock<ID: Hashable, Entity: Sendable>: Repository where Entity: Equatable {
                internal typealias ID = ID
                internal typealias Entity = Entity
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

                  internal func load(id: MockSynMatcher<ID>) -> MockSynStubBuilder1<ID, Entity> {
                    MockSynStubBuilder1<ID, Entity>(runtime: __mockSyn, member: "load(id:)", matchers: [id.erase()])
                  }
                }

                internal struct __MockSynVerify {
                  internal let __mockSyn: MockSynRuntime

                  internal func load(id: MockSynMatcher<ID>) -> MockSynVerification {
                    MockSynVerification(runtime: __mockSyn, member: "load(id:)", matchers: [id.erase()])
                  }
                }

                internal func load(id: ID) -> Entity {
                  return __mockSyn.resolve(member: "load(id:)", arguments: [id as Any], returnType: Entity.self)
                }
              }
              #endif
              """
        )
    }

    func testMockingUsesFileprivateAssociatedTypeWitnessForPrivateProtocol() {
        assertExpansion(
            """
            @Mocking(access: .private)
            private protocol Repository {
                associatedtype Entity
                func load() -> Entity
            }
            """,
            expandedSource: """
              private protocol Repository {
                  associatedtype Entity
                  func load() -> Entity
              }

              #if MOCKSYN_ENABLE
              private final class RepositoryMock<Entity>: Repository {
                fileprivate typealias Entity = Entity
                private let __mockSyn: MockSynRuntime

                private init(mode: MockSynMode = .strict) {
                  self.__mockSyn = MockSynRuntime(kind: .mock, mode: mode)
                }
                private var given: __MockSynGiven {
                  __MockSynGiven(__mockSyn: __mockSyn)
                }

                private var when: __MockSynGiven {
                  given
                }

                private var verify: __MockSynVerify {
                  __MockSynVerify(__mockSyn: __mockSyn)
                }

                private func confirmVerified() throws {
                  try __mockSyn.confirmVerified()
                }

                private func checkUnnecessaryStubs() throws {
                  try __mockSyn.checkUnnecessaryStubs()
                }

                private func reset(_ scope: MockSynResetScope = .all) {
                  __mockSyn.reset(scope)
                }

                private struct __MockSynGiven {
                  private let __mockSyn: MockSynRuntime

                  private func load() -> MockSynStubBuilder<Entity> {
                    MockSynStubBuilder<Entity>(runtime: __mockSyn, member: "load()", matchers: [])
                  }
                }

                private struct __MockSynVerify {
                  private let __mockSyn: MockSynRuntime

                  private func load() -> MockSynVerification {
                    MockSynVerification(runtime: __mockSyn, member: "load()", matchers: [])
                  }
                }

                private func load() -> Entity {
                  return __mockSyn.resolve(member: "load()", arguments: [], returnType: Entity.self)
                }
              }
              #endif
              """
        )
    }

    func testSpyingGeneratesGenericSpyForAssociatedTypeProtocol() {
        assertExpansion(
            """
            @Spying
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

              #if MOCKSYN_ENABLE
              internal final class RepositorySpy<Entity, __MockSynWrapped: Repository>: Repository where __MockSynWrapped.Entity == Entity {
                internal typealias Entity = Entity
                internal let __mockSyn: MockSynRuntime
                internal let __mockSynWrapped: __MockSynWrapped

                internal init(wrapping __mockSynWrapped: __MockSynWrapped, mode: MockSynMode = .strict) {
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

                  internal func load() -> MockSynStubBuilder<Entity> {
                    MockSynStubBuilder<Entity>(runtime: __mockSyn, member: "load()", matchers: [])
                  }
                }

                internal struct __MockSynVerify {
                  internal let __mockSyn: MockSynRuntime

                  internal func load() -> MockSynVerification {
                    MockSynVerification(runtime: __mockSyn, member: "load()", matchers: [])
                  }
                }

                internal func load() -> Entity {
                  return __mockSyn.resolve(member: "load()", arguments: [], returnType: Entity.self, fallback: {
                      self.__mockSynWrapped.load()
                    })
                }
              }
              #endif
              """
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

                internal func reset(_ scope: MockSynResetScope = .all) {
                  __mockSyn.reset(scope)
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

    func testClassComputedGetterShorthandGeneratesOverride() {
        assertExpansion(
            """
            @Mocking
            class UserService {
                var displayName: String { "base" }
            }
            """,
            expandedSource: """
              class UserService {
                  var displayName: String { "base" }
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

                internal func reset(_ scope: MockSynResetScope = .all) {
                  __mockSyn.reset(scope)
                }

                internal struct __MockSynGiven {
                  internal let __mockSyn: MockSynRuntime

                  internal var displayName: MockSynPropertyStubber<String> {
                    MockSynPropertyStubber(runtime: __mockSyn, getMember: "displayName.get", setMember: "displayName.set")
                  }
                }

                internal struct __MockSynVerify {
                  internal let __mockSyn: MockSynRuntime

                  internal var displayName: MockSynPropertyVerification<String> {
                    MockSynPropertyVerification(runtime: __mockSyn, getMember: "displayName.get", setMember: "displayName.set")
                  }
                }

                internal override var displayName: String {
                  get {
                    __mockSyn.resolve(member: "displayName.get", arguments: [], returnType: String.self)
                  }
                }
              }
              #endif
              """
        )
    }

    func testOperatorRequirementsGenerateStaticOperatorAndNamedDsl() {
        assertExpansion(
            """
            @Mocking
            protocol ComparableService {
                static func == (lhs: Self, rhs: Self) -> Bool
                static func + (lhs: Self, rhs: Self) -> Self
                static func <~> (lhs: Self, rhs: Self) -> Bool
            }
            """,
            expandedSource: """
              protocol ComparableService {
                  static func == (lhs: Self, rhs: Self) -> Bool
                  static func + (lhs: Self, rhs: Self) -> Self
                  static func <~> (lhs: Self, rhs: Self) -> Bool
              }

              #if MOCKSYN_ENABLE
              internal final class ComparableServiceMock: ComparableService {
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

                  internal func equalTo(lhs: MockSynMatcher<ComparableServiceMock>, rhs: MockSynMatcher<ComparableServiceMock>) -> MockSynStubBuilder2<ComparableServiceMock, ComparableServiceMock, Bool> {
                    MockSynStubBuilder2<ComparableServiceMock, ComparableServiceMock, Bool>(runtime: __mockSyn, member: "==(lhs:rhs:)", matchers: [lhs.erase(), rhs.erase()])
                  }

                  internal func plus(lhs: MockSynMatcher<ComparableServiceMock>, rhs: MockSynMatcher<ComparableServiceMock>) -> MockSynStubBuilder2<ComparableServiceMock, ComparableServiceMock, ComparableServiceMock> {
                    MockSynStubBuilder2<ComparableServiceMock, ComparableServiceMock, ComparableServiceMock>(runtime: __mockSyn, member: "+(lhs:rhs:)", matchers: [lhs.erase(), rhs.erase()])
                  }

                  internal func operator_u3c_u7e_u3e(lhs: MockSynMatcher<ComparableServiceMock>, rhs: MockSynMatcher<ComparableServiceMock>) -> MockSynStubBuilder2<ComparableServiceMock, ComparableServiceMock, Bool> {
                    MockSynStubBuilder2<ComparableServiceMock, ComparableServiceMock, Bool>(runtime: __mockSyn, member: "<~>(lhs:rhs:)", matchers: [lhs.erase(), rhs.erase()])
                  }
                }

                internal struct __MockSynStaticVerify {
                  internal let __mockSyn: MockSynRuntime

                  internal func equalTo(lhs: MockSynMatcher<ComparableServiceMock>, rhs: MockSynMatcher<ComparableServiceMock>) -> MockSynVerification {
                    MockSynVerification(runtime: __mockSyn, member: "==(lhs:rhs:)", matchers: [lhs.erase(), rhs.erase()])
                  }

                  internal func plus(lhs: MockSynMatcher<ComparableServiceMock>, rhs: MockSynMatcher<ComparableServiceMock>) -> MockSynVerification {
                    MockSynVerification(runtime: __mockSyn, member: "+(lhs:rhs:)", matchers: [lhs.erase(), rhs.erase()])
                  }

                  internal func operator_u3c_u7e_u3e(lhs: MockSynMatcher<ComparableServiceMock>, rhs: MockSynMatcher<ComparableServiceMock>) -> MockSynVerification {
                    MockSynVerification(runtime: __mockSyn, member: "<~>(lhs:rhs:)", matchers: [lhs.erase(), rhs.erase()])
                  }
                }

                internal static func == (lhs: ComparableServiceMock, rhs: ComparableServiceMock) -> Bool {
                  return __mockSynStatic.resolve(member: "==(lhs:rhs:)", arguments: [lhs as Any, rhs as Any], returnType: Bool.self)
                }

                internal static func + (lhs: ComparableServiceMock, rhs: ComparableServiceMock) -> Self {
                  return __mockSynStatic.resolve(member: "+(lhs:rhs:)", arguments: [lhs as Any, rhs as Any], returnType: Self.self)
                }

                internal static func <~> (lhs: ComparableServiceMock, rhs: ComparableServiceMock) -> Bool {
                  return __mockSynStatic.resolve(member: "<~>(lhs:rhs:)", arguments: [lhs as Any, rhs as Any], returnType: Bool.self)
                }
              }
              #endif
              """
        )
    }

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

                  internal var status: MockSynPropertyStubber<Bool> {
                    MockSynPropertyStubber(runtime: __mockSyn, getMember: "status.get", setMember: "status.set")
                  }

                  internal func refresh() -> MockSynStubBuilder<Void> {
                    MockSynStubBuilder<Void>(runtime: __mockSyn, member: "refresh()", matchers: [])
                  }

                  internal func loadReturningString() -> MockSynStubBuilder<String> {
                    MockSynStubBuilder<String>(runtime: __mockSyn, member: "load() -> String", matchers: [])
                  }

                  internal func loadReturningInt() -> MockSynStubBuilder<Int> {
                    MockSynStubBuilder<Int>(runtime: __mockSyn, member: "load() -> Int", matchers: [])
                  }

                  internal func loadReturningStringOptional() -> MockSynStubBuilder<String?> {
                    MockSynStubBuilder<String?>(runtime: __mockSyn, member: "load() -> String?", matchers: [])
                  }
                }

                internal struct __MockSynVerify {
                  internal let __mockSyn: MockSynRuntime

                  internal var status: MockSynPropertyVerification<Bool> {
                    MockSynPropertyVerification(runtime: __mockSyn, getMember: "status.get", setMember: "status.set")
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

                  internal func refresh() -> MockSynStubBuilder<Void> {
                    MockSynStubBuilder<Void>(runtime: __mockSyn, member: "refresh()", matchers: [])
                  }

                  internal func itemReturningReturnOverloadNamespaceValue() -> MockSynStubBuilder<ReturnOverloadNamespace.Value> {
                    MockSynStubBuilder<ReturnOverloadNamespace.Value>(runtime: __mockSyn, member: "item() -> ReturnOverloadNamespace.Value", matchers: [])
                  }

                  internal func itemReturningReturnOverloadNamespaceValueOverload2() -> MockSynStubBuilder<ReturnOverloadNamespaceValue> {
                    MockSynStubBuilder<ReturnOverloadNamespaceValue>(runtime: __mockSyn, member: "item() -> ReturnOverloadNamespaceValue", matchers: [])
                  }

                  internal func otherReturningString() -> MockSynStubBuilder<String> {
                    MockSynStubBuilder<String>(runtime: __mockSyn, member: "other() -> String", matchers: [])
                  }

                  internal func otherReturningInt() -> MockSynStubBuilder<Int> {
                    MockSynStubBuilder<Int>(runtime: __mockSyn, member: "other() -> Int", matchers: [])
                  }

                  internal func findReturningReturnOverloadNamespaceValue(id: MockSynMatcher<String>) -> MockSynStubBuilder1<String, ReturnOverloadNamespace.Value> {
                    MockSynStubBuilder1<String, ReturnOverloadNamespace.Value>(runtime: __mockSyn, member: "find(id:) -> ReturnOverloadNamespace.Value", matchers: [id.erase()])
                  }

                  internal func findReturningReturnOverloadNamespaceValueOverload2(id: MockSynMatcher<String>) -> MockSynStubBuilder1<String, ReturnOverloadNamespaceValue> {
                    MockSynStubBuilder1<String, ReturnOverloadNamespaceValue>(runtime: __mockSyn, member: "find(id:) -> ReturnOverloadNamespaceValue", matchers: [id.erase()])
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
                    message: "MockSyn cannot generate class operator members. Move the operator behind a protocol requirement.",
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

    func testMockingGlobalFunctionEmitsDiagnostic() {
        assertExpansion(
            """
            @Mocking
            func makeID() -> String {
                "real"
            }
            """,
            expandedSource: """
              func makeID() -> String {
                  "real"
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

    func testMockingClassWithStaticConcreteMethodEmitsDiagnostic() {
        assertExpansion(
            """
            @Mocking
            class IDFactory {
                static func make() -> String {
                    "real"
                }
            }
            """,
            expandedSource: """
              class IDFactory {
                  static func make() -> String {
                      "real"
                  }
              }
              """,
            diagnostics: [
                DiagnosticSpec(
                    message: "MockSyn cannot intercept concrete static class members. Move the static member behind a protocol requirement or use Objective-C interception for Objective-C class methods.",
                    line: 1,
                    column: 1,
                    severity: .error
                )
            ]
        )
    }

    func testStubbingClassWithStaticConcretePropertyEmitsDiagnostic() {
        assertExpansion(
            """
            @Stubbing
            class Configuration {
                static var value: String {
                    "real"
                }
            }
            """,
            expandedSource: """
              class Configuration {
                  static var value: String {
                      "real"
                  }
              }
              """,
            diagnostics: [
                DiagnosticSpec(
                    message: "MockSyn cannot intercept concrete static class members. Move the static member behind a protocol requirement or use Objective-C interception for Objective-C class methods.",
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
                    severity: .error,
                    fixIts: [
                        FixItSpec(message: "Remove 'final'")
                    ]
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
                    severity: .error,
                    fixIts: [
                        FixItSpec(message: "Remove 'final'")
                    ]
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
                    severity: .error,
                    fixIts: [
                        FixItSpec(message: "Remove 'final'")
                    ]
                )
            ]
        )
    }

    func testMockingClassWithFinalMethodEmitsDiagnostic() {
        assertExpansion(
            """
            @Mocking
            class UserService {
                final func load() -> String {
                    "real"
                }
            }
            """,
            expandedSource: """
              class UserService {
                  final func load() -> String {
                      "real"
                  }
              }
              """,
            diagnostics: [
                DiagnosticSpec(
                    message: "MockSyn cannot mock final class members by subclass generation. Remove 'final' from the member or extract a protocol.",
                    line: 1,
                    column: 1,
                    severity: .error,
                    fixIts: [
                        FixItSpec(message: "Remove 'final'")
                    ]
                )
            ]
        )
    }

    func testStubbingClassWithFinalPropertyEmitsDiagnostic() {
        assertExpansion(
            """
            @Stubbing
            class AnalyticsService {
                final var token: String {
                    "real"
                }
            }
            """,
            expandedSource: """
              class AnalyticsService {
                  final var token: String {
                      "real"
                  }
              }
              """,
            diagnostics: [
                DiagnosticSpec(
                    message: "MockSyn cannot mock final class members by subclass generation. Remove 'final' from the member or extract a protocol.",
                    line: 1,
                    column: 1,
                    severity: .error,
                    fixIts: [
                        FixItSpec(message: "Remove 'final'")
                    ]
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

    func testInvalidModeOptionEmitsDiagnostic() {
        assertExpansion(
            """
            @Mocking(mode: .lenient)
            protocol UserService {
            }
            """,
            expandedSource: """
              protocol UserService {
              }
              """,
            diagnostics: [
                DiagnosticSpec(
                    message: "MockSyn mode must be one of: strict, relaxed",
                    line: 1,
                    column: 1,
                    severity: .error
                )
            ]
        )
    }

    func testInvalidModeLiteralEmitsDiagnostic() {
        assertExpansion(
            """
            @Mocking(mode: "strict")
            protocol UserService {
            }
            """,
            expandedSource: """
              protocol UserService {
              }
              """,
            diagnostics: [
                DiagnosticSpec(
                    message: "MockSyn mode must be one of: strict, relaxed",
                    line: 1,
                    column: 1,
                    severity: .error
                )
            ]
        )
    }

    func testMockingSupportsQualifiedProtocolInheritance() {
        assertExpansion(
            """
            @Mocking
            protocol UserService: Foundation.Sendable {
            }
            """,
            expandedSource: """
              protocol UserService: Foundation.Sendable {
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
