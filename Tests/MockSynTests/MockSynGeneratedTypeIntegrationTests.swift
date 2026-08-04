import MockSyn
import Foundation
import XCTest

@Mocking
protocol EmptyUserService {
}

protocol EmptyParentService {
}

@Mocking
protocol EmptyChildService: EmptyParentService {
}

@Stubbing
protocol EmptyAnalyticsService {
}

@Spying
protocol EmptyCacheStore {
}

struct InMemoryCacheStore: EmptyCacheStore {
}

@Mocking
class EmptyUserServiceBase {
}

@Stubbing
class EmptyAnalyticsServiceBase {
}

@Spying
class EmptyCacheStoreBase {
}

enum ClassInitializerMirrorLog {
    static var mockSeed: String?
    static var requiredMockSeed: String?
    static var stubSeed: String?
    static var spySeed: String?

    static func reset() {
        mockSeed = nil
        requiredMockSeed = nil
        stubSeed = nil
        spySeed = nil
    }
}

@Mocking
class SeededUserServiceBase {
    init(seed: String) {
        ClassInitializerMirrorLog.mockSeed = seed
    }
}

@Mocking
class RequiredSeededUserServiceBase {
    required init(seed: String) {
        ClassInitializerMirrorLog.requiredMockSeed = seed
    }
}

@Stubbing
class SeededAnalyticsServiceBase {
    init(seed: String) {
        ClassInitializerMirrorLog.stubSeed = seed
    }
}

@Spying
class SeededCacheStoreBase {
    init(seed: String) {
        ClassInitializerMirrorLog.spySeed = seed
    }
}

@Mocking
@objcMembers
class EmptyLegacyService: NSObject {
}

@Mocking
class EmptyDynamicLegacyService: NSObject {
    @objc dynamic func ping() -> String {
        "real"
    }
}

@Mocking
protocol MemberUserService {
    init(seed: String)
    var token: String { get set }
    func refresh()
    func save(_ value: String) async throws
    subscript(key: String) -> String? { get set }
}

@Spying
protocol MemberCacheStore {
    var count: Int { get }
    func load(id: String) -> String
    func save(_ value: String) async throws
    subscript(key: String) -> String? { get }
}

struct RealMemberCacheStore: MemberCacheStore {
    let count = 2

    func load(id: String) -> String {
        "cached-\(id)"
    }

    func save(_ value: String) async throws {
    }

    subscript(key: String) -> String? {
        "value-\(key)"
    }
}

@Mocking
class MemberUserServiceBase {
    var token: String {
        get { "real" }
        set { }
    }

    func refresh() {
    }

    func save(_ value: String) throws {
    }
}

@Mocking
class ObservedPropertyServiceBase {
    var willSetValue: String = "initial" {
        willSet { }
    }

    var didSetValue: String = "initial" {
        didSet { }
    }
}

@Mocking
protocol LanguageFeatureService {
    func update(_ value: inout Int)
    func handle(_ action: @escaping (String) -> Void)
}

@Spying
protocol MutableCounterService {
    func update(_ value: inout Int)
}

struct RealMutableCounterService: MutableCounterService {
    func update(_ value: inout Int) {
        value += 1
    }
}

@Spying
protocol VariadicSumService {
    func sum(_ values: Int...) -> Int
}

struct RealVariadicSumService: VariadicSumService {
    func sum(_ values: Int...) -> Int {
        values.reduce(0, +)
    }
}

@Mocking
class GenericBox<Value> where Value: Sendable {
    func load(_ value: Value) -> Value {
        value
    }
}

@Mocking
@MainActor
protocol MainActorService {
    func refresh()
}

enum StubbedServiceError: Error, Equatable {
    case offline
}

struct StubbedToken: Equatable {
    let value: String
}

@Mocking
protocol StubbedUserService {
    var displayName: String { get set }

    func name(id: String) -> String
    func combined(_ name: String, retry: Int) -> String
    func asyncName(id: String) async -> String
    func nextCount() -> Int
    func failingName() throws -> String
    func doubled(_ value: Int) -> Int
    func ping()
    subscript(key: String) -> String? { get set }
}

@Mocking
protocol GenericSubscriptService {
    subscript<Value: Sendable>(key: String, default defaultValue: Value) -> Value { get set }
    subscript<Value>(optional key: String) -> Value? where Value: Equatable { get }
}

@Stubbing
protocol RelaxedDefaultsService {
    var optionalName: String? { get }

    func title() -> String
    func count() -> Int
    func enabled() -> Bool
    func token() -> StubbedToken
}

@Mocking
protocol AssociatedRepository {
    associatedtype Entity

    func load() -> Entity
    func save(_ entity: Entity)
}

@Stubbing
protocol AssociatedLookup {
    associatedtype ID: Hashable
    associatedtype Entity: Sendable where Entity: Equatable

    func load(id: ID) -> Entity
}

@Spying
protocol AssociatedCache {
    associatedtype Entity

    func load() -> Entity
}

struct RealAssociatedCache: AssociatedCache {
    func load() -> String {
        "real-associated"
    }
}

@Mocking
protocol StaticFactoryService {
    static var version: String { get set }

    static func make(id: String) -> String
    static func ping()
}

@Mocking
protocol StaticThrowingService {
    static func fetch() throws -> String
    static func save() throws
}

@Mocking
protocol OperatorComparableService {
    static func == (lhs: Self, rhs: Self) -> Bool
    static func + (lhs: Self, rhs: Self) -> Self
}

@Mocking
protocol ReturnOverloadedService {
    func load() -> String
    func load() -> Int
    func load() -> String?
}

enum ReturnOverloadNamespace {
    struct Value: Equatable {
        let raw: String
    }
}

struct ReturnOverloadNamespaceValue: Equatable {
    let raw: String
}

@Mocking
protocol CollidingReturnOverloadedService {
    func item() -> ReturnOverloadNamespace.Value
    func item() -> ReturnOverloadNamespaceValue
    func find(id: String) -> ReturnOverloadNamespace.Value
    func find(id: String) -> ReturnOverloadNamespaceValue
}

@Mocking
protocol StaticReturnOverloadedService {
    static func make() -> String
    static func make() -> Int
}

@Mocking
protocol RethrowingService {
    func transform(_ operation: @escaping () throws -> String) rethrows -> String
    func consume(_ operation: @escaping () throws -> Void) rethrows

    static func make(_ operation: @escaping () throws -> String) rethrows -> String
    static func save(_ operation: @escaping () throws -> Void) rethrows
}

@Spying
protocol RethrowingSpyService {
    func transform(_ operation: @escaping () throws -> String) rethrows -> String
    func consume(_ operation: @escaping () throws -> Void) rethrows
}

struct RealRethrowingSpyService: RethrowingSpyService {
    func transform(_ operation: @escaping () throws -> String) rethrows -> String {
        try operation()
    }

    func consume(_ operation: @escaping () throws -> Void) rethrows {
        try operation()
    }
}

@Mocking
protocol EffectfulPropertyService {
    var asyncName: String { get async }
    var throwingName: String { get throws }
    var asyncThrowingName: String { get async throws }

    static var staticAsyncThrowingName: String { get async throws }
}

@Spying
protocol EffectfulPropertySpyService {
    var asyncName: String { get async }
    var asyncThrowingName: String { get async throws }
}

struct RealEffectfulPropertySpyService: EffectfulPropertySpyService {
    var asyncName: String {
        get async {
            "real-async"
        }
    }

    var asyncThrowingName: String {
        get async throws {
            "real-async-throws"
        }
    }
}

@Mocking
protocol QualifiedSendableService: Swift.Sendable {
    func refresh()
}

protocol InheritedRequirementService {
    func inheritedValue() -> String
}

@Mocking
protocol RedeclaredInheritedRequirementService: InheritedRequirementService {
    func inheritedValue() -> String
}

final class MockSynGeneratedTypeIntegrationTests: XCTestCase {
    func testRedeclaredInheritedRequirementGeneratesAndCompiles() {
        #if MOCKSYN_ENABLE
        let mock = RedeclaredInheritedRequirementServiceMock()
        mock.given.inheritedValue().willReturn("generated")

        XCTAssertEqual(mock.inheritedValue(), "generated")
        #else
        XCTFail("MOCKSYN_ENABLE must be active for generated test doubles")
        #endif
    }
}
