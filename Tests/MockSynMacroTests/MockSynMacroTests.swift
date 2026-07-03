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
                static var build: String { get }
                static func makeDefault() -> String
                func load(id: String) -> String
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
                  static var build: String { get }
                  static func makeDefault() -> String
                  func load(id: String) -> String
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

                internal init(seed: String) {
                  self.__mockSyn = MockSynRuntime(kind: .mock, mode: .strict)
                }

                internal var currentUser: String {
                  get {
                    fatalError("MockSyn member currentUser is not configured")
                  }
                }

                internal var token: String? {
                  get {
                    fatalError("MockSyn member token is not configured")
                  }
                  set {
                  }
                }

                internal static var build: String {
                  get {
                    fatalError("MockSyn member build is not configured")
                  }
                }

                internal static func makeDefault() -> String {
                  fatalError("MockSyn member makeDefault() is not configured")
                }

                internal func load(id: String) -> String {
                  fatalError("MockSyn member load(id:) is not configured")
                }

                internal func save(_ user: String) throws {
                }

                internal func refresh() async {
                }

                internal func fetch(id: String) async throws -> Int {
                  fatalError("MockSyn member fetch(id:) is not configured")
                }

                internal subscript(key: String) -> String? {
                  get {
                    fatalError("MockSyn member subscript(key:) is not configured")
                  }
                  set {
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

                internal var count: Int {
                  get {
                    __mockSynWrapped.count
                  }
                }

                internal var token: String? {
                  get {
                    __mockSynWrapped.token
                  }
                  set {
                  }
                }

                internal func load(id: String) -> String {
                  __mockSynWrapped.load(id: id)
                }

                internal func fail() throws {
                  try __mockSynWrapped.fail()
                }

                internal func stream() async -> String {
                  await __mockSynWrapped.stream()
                }

                internal func save(_ value: String) async throws {
                  try await __mockSynWrapped.save(value)
                }

                internal subscript(key: String) -> String? {
                  get {
                    __mockSynWrapped[key]
                  }
                }

                internal subscript(label key: String) -> String? {
                  get {
                    __mockSynWrapped[label: key]
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

                internal subscript(_ key: String) -> String? {
                  get {
                    __mockSynWrapped[key]
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

                @MainActor internal var title: String {
                  get {
                    fatalError("MockSyn member title is not configured")
                  }
                }

                internal func map<Value>(_ value: Value) -> Value where Value: Sendable {
                  fatalError("MockSyn member map(_:) is not configured")
                }

                internal func update(_ value: inout Int) {
                }

                internal func handle(_ action: @escaping (String) -> Void) {
                }

                internal func clone() -> Self {
                  fatalError("MockSyn member clone() is not configured")
                }

                internal func collect(_ values: Int...) -> Int {
                  fatalError("MockSyn member collect(_:) is not configured")
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

                internal func update(_ value: inout Int) {
                  __mockSynWrapped.update(&value)
                }

                internal func handle(_ action: @escaping (String) -> Void) {
                  __mockSynWrapped.handle(action)
                }

                internal func collect(_ values: Int...) -> Int {
                  fatalError("MockSyn member collect(_:) is not configured")
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

                internal func refresh() {
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

                internal override func load(_ value: Value) -> Value {
                  fatalError("MockSyn member load(_:) is not configured")
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

                internal override var storedToken: String {
                  get {
                    fatalError("MockSyn member storedToken is not configured")
                  }
                  set {
                  }
                }

                internal override var token: String {
                  get {
                    fatalError("MockSyn member token is not configured")
                  }
                  set {
                  }
                }

                internal override func load(id: String) -> String {
                  fatalError("MockSyn member load(id:) is not configured")
                }

                internal override func save(_ user: String) throws {
                }

                internal override subscript(key: String) -> String {
                  get {
                    fatalError("MockSyn member subscript(key:) is not configured")
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
