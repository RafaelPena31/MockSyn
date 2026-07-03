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

private struct InMemoryCacheStore: EmptyCacheStore {
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

private struct RealMemberCacheStore: MemberCacheStore {
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
protocol LanguageFeatureService {
    func update(_ value: inout Int)
    func handle(_ action: @escaping (String) -> Void)
}

@Spying
protocol MutableCounterService {
    func update(_ value: inout Int)
}

private struct RealMutableCounterService: MutableCounterService {
    func update(_ value: inout Int) {
        value += 1
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

private enum StubbedServiceError: Error, Equatable {
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

private struct RealAssociatedCache: AssociatedCache {
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

private struct RealEffectfulPropertySpyService: EffectfulPropertySpyService {
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

final class MockSynGeneratedTypeIntegrationTests: XCTestCase {
    func testGeneratedMockCarriesRuntimeMetadata() {
        #if MOCKSYN_ENABLE
        let mock = EmptyUserServiceMock()

        XCTAssertEqual(mock.__mockSyn.kind, .mock)
        XCTAssertEqual(mock.__mockSyn.mode, .strict)
        #else
        XCTFail("MOCKSYN_ENABLE must be active for generated test doubles")
        #endif
    }

    func testGeneratedMockForInheritedProtocolCanBeUsedAsParentProtocol() {
        #if MOCKSYN_ENABLE
        let mock = EmptyChildServiceMock()
        let parent: EmptyParentService = mock

        XCTAssertTrue(parent is EmptyChildServiceMock)
        XCTAssertEqual(mock.__mockSyn.kind, .mock)
        #else
        XCTFail("MOCKSYN_ENABLE must be active for generated test doubles")
        #endif
    }

    func testGeneratedStubCarriesRuntimeMetadata() {
        #if MOCKSYN_ENABLE
        let stub = EmptyAnalyticsServiceStub()

        XCTAssertEqual(stub.__mockSyn.kind, .stub)
        XCTAssertEqual(stub.__mockSyn.mode, .relaxed)
        #else
        XCTFail("MOCKSYN_ENABLE must be active for generated test doubles")
        #endif
    }

    func testGeneratedSpyCarriesRuntimeMetadataAndWrappedImplementation() {
        #if MOCKSYN_ENABLE
        let wrapped = InMemoryCacheStore()
        let spy = EmptyCacheStoreSpy(wrapping: wrapped)

        XCTAssertEqual(spy.__mockSyn.kind, .spy)
        XCTAssertEqual(spy.__mockSyn.mode, .strict)
        XCTAssertNotNil(spy.__mockSynWrapped as? InMemoryCacheStore)
        #else
        XCTFail("MOCKSYN_ENABLE must be active for generated test doubles")
        #endif
    }

    func testGeneratedClassMockSubclassesAnnotatedClass() {
        #if MOCKSYN_ENABLE
        let mock = EmptyUserServiceBaseMock()
        let base: EmptyUserServiceBase = mock

        XCTAssertTrue(base === mock)
        XCTAssertEqual(mock.__mockSyn.kind, .mock)
        XCTAssertEqual(mock.__mockSyn.mode, .strict)
        #else
        XCTFail("MOCKSYN_ENABLE must be active for generated test doubles")
        #endif
    }

    func testGeneratedClassStubSubclassesAnnotatedClass() {
        #if MOCKSYN_ENABLE
        let stub = EmptyAnalyticsServiceBaseStub()
        let base: EmptyAnalyticsServiceBase = stub

        XCTAssertTrue(base === stub)
        XCTAssertEqual(stub.__mockSyn.kind, .stub)
        XCTAssertEqual(stub.__mockSyn.mode, .relaxed)
        #else
        XCTFail("MOCKSYN_ENABLE must be active for generated test doubles")
        #endif
    }

    func testGeneratedClassSpySubclassesAnnotatedClassAndStoresWrappedImplementation() {
        #if MOCKSYN_ENABLE
        let wrapped = EmptyCacheStoreBase()
        let spy = EmptyCacheStoreBaseSpy(wrapping: wrapped)
        let base: EmptyCacheStoreBase = spy

        XCTAssertTrue(base === spy)
        XCTAssertTrue(spy.__mockSynWrapped === wrapped)
        XCTAssertEqual(spy.__mockSyn.kind, .spy)
        XCTAssertEqual(spy.__mockSyn.mode, .strict)
        #else
        XCTFail("MOCKSYN_ENABLE must be active for generated test doubles")
        #endif
    }

    func testGeneratedNSObjectBackedMockSubclassesAnnotatedClass() {
        #if MOCKSYN_ENABLE
        let mock = EmptyLegacyServiceMock()
        let legacy: EmptyLegacyService = mock
        let object: NSObject = mock

        XCTAssertTrue(legacy === mock)
        XCTAssertTrue(object === mock)
        XCTAssertEqual(mock.__mockSyn.kind, .mock)
        #else
        XCTFail("MOCKSYN_ENABLE must be active for generated test doubles")
        #endif
    }

    func testGeneratedDynamicNSObjectBackedMockSubclassesAnnotatedClass() {
        #if MOCKSYN_ENABLE
        let mock = EmptyDynamicLegacyServiceMock()
        let legacy: EmptyDynamicLegacyService = mock
        let object: NSObject = mock

        XCTAssertTrue(legacy === mock)
        XCTAssertTrue(object === mock)
        XCTAssertEqual(mock.__mockSyn.kind, .mock)
        #else
        XCTFail("MOCKSYN_ENABLE must be active for generated test doubles")
        #endif
    }

    func testGeneratedProtocolMockSupportsCallableVoidMembersAndSetters() async throws {
        #if MOCKSYN_ENABLE
        let defaultMock = MemberUserServiceMock()
        let seededMock = MemberUserServiceMock(seed: "seed")

        defaultMock.refresh()
        defaultMock.token = "token"
        defaultMock["theme"] = "dark"
        try await defaultMock.save("value")

        XCTAssertEqual(defaultMock.__mockSyn.kind, .mock)
        XCTAssertEqual(seededMock.__mockSyn.mode, .strict)
        #else
        XCTFail("MOCKSYN_ENABLE must be active for generated test doubles")
        #endif
    }

    func testGeneratedProtocolSpyDelegatesReadableMembers() async throws {
        #if MOCKSYN_ENABLE
        let spy = MemberCacheStoreSpy(wrapping: RealMemberCacheStore())

        XCTAssertEqual(spy.count, 2)
        XCTAssertEqual(spy.load(id: "user"), "cached-user")
        XCTAssertEqual(spy["theme"], "value-theme")
        try await spy.save("value")
        XCTAssertEqual(spy.__mockSyn.kind, .spy)
        #else
        XCTFail("MOCKSYN_ENABLE must be active for generated test doubles")
        #endif
    }

    func testGeneratedClassMockOverridesCallableVoidMembersAndSetters() throws {
        #if MOCKSYN_ENABLE
        let mock = MemberUserServiceBaseMock()
        let base: MemberUserServiceBase = mock

        mock.refresh()
        mock.token = "token"
        try mock.save("value")

        XCTAssertTrue(base === mock)
        XCTAssertEqual(mock.__mockSyn.kind, .mock)
        #else
        XCTFail("MOCKSYN_ENABLE must be active for generated test doubles")
        #endif
    }

    func testGeneratedProtocolMockSupportsInoutAndEscapingClosureSignatures() {
        #if MOCKSYN_ENABLE
        let mock = LanguageFeatureServiceMock()
        var value = 1

        mock.update(&value)
        mock.handle { _ in }

        XCTAssertEqual(value, 1)
        XCTAssertEqual(mock.__mockSyn.kind, .mock)
        #else
        XCTFail("MOCKSYN_ENABLE must be active for generated test doubles")
        #endif
    }

    func testGeneratedProtocolSpyDelegatesInoutArgument() {
        #if MOCKSYN_ENABLE
        let spy = MutableCounterServiceSpy(wrapping: RealMutableCounterService())
        var value = 1

        spy.update(&value)

        XCTAssertEqual(value, 2)
        XCTAssertEqual(spy.__mockSyn.kind, .spy)
        #else
        XCTFail("MOCKSYN_ENABLE must be active for generated test doubles")
        #endif
    }

    func testGeneratedGenericClassMockSubclassesGenericBase() {
        #if MOCKSYN_ENABLE
        let mock = GenericBoxMock<String>()
        let base: GenericBox<String> = mock

        XCTAssertTrue(base === mock)
        XCTAssertEqual(mock.__mockSyn.kind, .mock)
        #else
        XCTFail("MOCKSYN_ENABLE must be active for generated test doubles")
        #endif
    }

    @MainActor
    func testGeneratedMainActorMockPreservesIsolation() {
        #if MOCKSYN_ENABLE
        let mock = MainActorServiceMock()

        mock.refresh()

        XCTAssertEqual(mock.__mockSyn.kind, .mock)
        #else
        XCTFail("MOCKSYN_ENABLE must be active for generated test doubles")
        #endif
    }

    func testGeneratedMockUsesGivenWillReturnForMatchingArguments() {
        #if MOCKSYN_ENABLE
        let mock = StubbedUserServiceMock()

        mock.given.name(id: .value("42")).willReturn("Arthur")
        mock.given.name(id: .any).willReturn("fallback")

        XCTAssertEqual(mock.name(id: "42"), "Arthur")
        XCTAssertEqual(mock.name(id: "7"), "fallback")
        #else
        XCTFail("MOCKSYN_ENABLE must be active for generated test doubles")
        #endif
    }

    func testGeneratedMockUsesWhenAliasAndSequentialReturns() {
        #if MOCKSYN_ENABLE
        let mock = StubbedUserServiceMock()

        mock.when.nextCount().willReturn(1, 2, 3)

        XCTAssertEqual(mock.nextCount(), 1)
        XCTAssertEqual(mock.nextCount(), 2)
        XCTAssertEqual(mock.nextCount(), 3)
        XCTAssertEqual(mock.nextCount(), 3)
        #else
        XCTFail("MOCKSYN_ENABLE must be active for generated test doubles")
        #endif
    }

    func testGeneratedMockUsesWillThrowAndWillRun() throws {
        #if MOCKSYN_ENABLE
        let mock = StubbedUserServiceMock()

        mock.given.failingName().willThrow(StubbedServiceError.offline)
        mock.given.doubled(.any).willRun { value in
            value * 2
        }

        XCTAssertThrowsError(try mock.failingName()) { error in
            XCTAssertEqual(error as? StubbedServiceError, .offline)
        }
        XCTAssertEqual(mock.doubled(4), 8)
        #else
        XCTFail("MOCKSYN_ENABLE must be active for generated test doubles")
        #endif
    }

    func testGeneratedMockUsesStubsForMultipleArgumentsAndAsyncMembers() async {
        #if MOCKSYN_ENABLE
        let mock = StubbedUserServiceMock()

        mock.given.combined(.value("Rafael"), retry: .value(2)).willReturn("matched")
        mock.given.asyncName(id: .any).willReturn("async-value")

        let asyncName = await mock.asyncName(id: "42")

        XCTAssertEqual(mock.combined("Rafael", retry: 2), "matched")
        XCTAssertEqual(asyncName, "async-value")
        #else
        XCTFail("MOCKSYN_ENABLE must be active for generated test doubles")
        #endif
    }

    func testGeneratedMockUsesCaptorMatchersForStubbingAndVerification() throws {
        #if MOCKSYN_ENABLE
        let mock = StubbedUserServiceMock()
        let stubCaptor = MockSynArgumentCaptor<Int>()
        let verifyCaptor = MockSynArgumentCaptor<String>()

        mock.given.doubled(stubCaptor.capture()).willRun { value in
            value * 2
        }
        mock.given.name(id: .any).willReturn("matched")

        XCTAssertEqual(mock.doubled(4), 8)
        XCTAssertEqual(mock.name(id: "user-1"), "matched")

        try mock.verify.doubled(.value(4)).once()
        try mock.verify.name(id: verifyCaptor.capture()).once()

        XCTAssertEqual(stubCaptor.values, [4])
        XCTAssertEqual(verifyCaptor.value, "user-1")
        #else
        XCTFail("MOCKSYN_ENABLE must be active for generated test doubles")
        #endif
    }

    func testGeneratedMockUsesClosureCaptorForVerification() throws {
        #if MOCKSYN_ENABLE
        let mock = LanguageFeatureServiceMock()
        let captor = MockSynClosureCaptor<(String) -> Void>()
        var received: String?

        mock.handle { value in
            received = value
        }

        try mock.verify.handle(captor.capture()).once()
        captor.value?("captured")

        XCTAssertEqual(received, "captured")
        #else
        XCTFail("MOCKSYN_ENABLE must be active for generated test doubles")
        #endif
    }

    func testGeneratedMockUsesPropertyGetterAndSetterStubs() {
        #if MOCKSYN_ENABLE
        let mock = StubbedUserServiceMock()
        var assignedName: String?

        mock.given.displayName.get.willReturn("Rafael")
        mock.given.displayName.set(.any).willRun { newValue in
            assignedName = newValue
        }

        XCTAssertEqual(mock.displayName, "Rafael")
        mock.displayName = "MockSyn"
        XCTAssertEqual(assignedName, "MockSyn")
        #else
        XCTFail("MOCKSYN_ENABLE must be active for generated test doubles")
        #endif
    }

    func testGeneratedMockUsesSubscriptGetterAndSetterStubs() {
        #if MOCKSYN_ENABLE
        let mock = StubbedUserServiceMock()
        var assignedValue: String?

        mock.given.subscript(key: .value("theme")).get.willReturn("dark")
        mock.given.subscript(key: .any).set(.any).willRun { newValue in
            assignedValue = newValue
        }

        XCTAssertEqual(mock["theme"], "dark")
        mock["theme"] = "light"
        XCTAssertEqual(assignedValue, "light")
        #else
        XCTFail("MOCKSYN_ENABLE must be active for generated test doubles")
        #endif
    }

    func testGeneratedVoidMethodCanBeStubbedWithWillRun() {
        #if MOCKSYN_ENABLE
        let mock = StubbedUserServiceMock()
        var didPing = false

        mock.given.ping().willRun {
            didPing = true
        }

        mock.ping()

        XCTAssertTrue(didPing)
        #else
        XCTFail("MOCKSYN_ENABLE must be active for generated test doubles")
        #endif
    }

    func testGeneratedMockVerifiesMethodsPropertiesSubscriptsAndConfirmVerified() throws {
        #if MOCKSYN_ENABLE
        let mock = StubbedUserServiceMock()

        mock.given.name(id: .any).willReturn("Rafael")
        mock.given.displayName.get.willReturn("Display")
        mock.given.`subscript`(key: .any).get.willReturn("dark")

        XCTAssertEqual(mock.name(id: "42"), "Rafael")
        mock.displayName = "Stored"
        XCTAssertEqual(mock.displayName, "Display")
        mock.ping()
        mock["theme"] = "dark"
        XCTAssertEqual(mock["theme"], "dark")

        try mock.verify.name(id: .value("42")).once()
        try mock.verify.displayName.set(.value("Stored")).wasCalled(.once)
        try mock.verify.displayName.get.wasCalled(.once)
        try mock.verify.ping().times(1)
        try mock.verify.`subscript`(key: .value("theme")).set(.value("dark")).once()
        try mock.verify.`subscript`(key: .value("theme")).get.once()
        try mock.verify.name(id: .value("missing")).never()
        try mock.confirmVerified()
        try mock.checkUnnecessaryStubs()
        #else
        XCTFail("MOCKSYN_ENABLE must be active for generated test doubles")
        #endif
    }

    func testGeneratedCheckUnnecessaryStubsDetectsUnusedRules() {
        #if MOCKSYN_ENABLE
        let mock = StubbedUserServiceMock()

        mock.given.name(id: .value("used")).willReturn("used")
        mock.given.name(id: .value("unused")).willReturn("unused")

        XCTAssertEqual(mock.name(id: "used"), "used")

        XCTAssertThrowsError(try mock.checkUnnecessaryStubs()) { error in
            XCTAssertTrue(String(describing: error).contains("name(id:)"))
        }
        #else
        XCTFail("MOCKSYN_ENABLE must be active for generated test doubles")
        #endif
    }

    func testGeneratedVerificationSupportsOrderAcrossMocks() throws {
        #if MOCKSYN_ENABLE
        let first = StubbedUserServiceMock()
        let second = StubbedUserServiceMock()

        first.ping()
        second.ping()

        try MockSynVerifier.verifyOrder(first.verify.ping(), second.verify.ping())
        XCTAssertThrowsError(try MockSynVerifier.verifyOrder(second.verify.ping(), first.verify.ping()))
        #else
        XCTFail("MOCKSYN_ENABLE must be active for generated test doubles")
        #endif
    }

    func testGeneratedAssociatedTypeMockSupportsStubbingAndVerification() throws {
        #if MOCKSYN_ENABLE
        let mock = AssociatedRepositoryMock<String>()

        mock.given.load().willReturn("entity")
        mock.save("stored")

        XCTAssertEqual(mock.load(), "entity")
        try mock.verify.save(.value("stored")).once()
        try mock.verify.load().once()
        #else
        XCTFail("MOCKSYN_ENABLE must be active for generated test doubles")
        #endif
    }

    func testGeneratedConstrainedAssociatedTypeStubSupportsGenericBinding() {
        #if MOCKSYN_ENABLE
        let stub = AssociatedLookupStub<Int, String>()

        stub.given.load(id: .value(7)).willReturn("seven")

        XCTAssertEqual(stub.load(id: 7), "seven")
        #else
        XCTFail("MOCKSYN_ENABLE must be active for generated test doubles")
        #endif
    }

    func testGeneratedAssociatedTypeSpyDelegatesToWrappedImplementation() throws {
        #if MOCKSYN_ENABLE
        let spy = AssociatedCacheSpy<String, RealAssociatedCache>(wrapping: RealAssociatedCache())

        XCTAssertEqual(spy.load(), "real-associated")
        try spy.verify.load().once()
        #else
        XCTFail("MOCKSYN_ENABLE must be active for generated test doubles")
        #endif
    }

    func testGeneratedStaticMembersSupportStubbingAndVerification() throws {
        #if MOCKSYN_ENABLE
        StaticFactoryServiceMock.resetStatic()

        StaticFactoryServiceMock.given.version.get.willReturn("1.0")
        StaticFactoryServiceMock.given.make(id: .value("primary")).willReturn("made")

        XCTAssertEqual(StaticFactoryServiceMock.version, "1.0")
        StaticFactoryServiceMock.version = "2.0"
        XCTAssertEqual(StaticFactoryServiceMock.make(id: "primary"), "made")
        StaticFactoryServiceMock.ping()

        try StaticFactoryServiceMock.verify.version.get.once()
        try StaticFactoryServiceMock.verify.version.set(.value("2.0")).once()
        try StaticFactoryServiceMock.verify.make(id: .value("primary")).once()
        try StaticFactoryServiceMock.verify.ping().once()
        try StaticFactoryServiceMock.confirmStaticVerified()
        try StaticFactoryServiceMock.checkUnnecessaryStaticStubs()
        StaticFactoryServiceMock.resetStatic()
        #else
        XCTFail("MOCKSYN_ENABLE must be active for generated test doubles")
        #endif
    }

    func testGeneratedStaticThrowingMembersSupportStubbingAndVerification() throws {
        #if MOCKSYN_ENABLE
        StaticThrowingServiceMock.resetStatic()

        StaticThrowingServiceMock.given.fetch().willReturn("static")
        StaticThrowingServiceMock.given.save().willThrow(StubbedServiceError.offline)

        XCTAssertEqual(try StaticThrowingServiceMock.fetch(), "static")
        XCTAssertThrowsError(try StaticThrowingServiceMock.save()) { error in
            XCTAssertEqual(error as? StubbedServiceError, .offline)
        }

        try StaticThrowingServiceMock.verify.fetch().once()
        try StaticThrowingServiceMock.verify.save().once()
        StaticThrowingServiceMock.resetStatic()
        #else
        XCTFail("MOCKSYN_ENABLE must be active for generated test doubles")
        #endif
    }

    func testGeneratedOperatorRequirementsSupportStubbingAndVerification() throws {
        #if MOCKSYN_ENABLE
        OperatorComparableServiceMock.resetStatic()
        let lhs = OperatorComparableServiceMock()
        let rhs = OperatorComparableServiceMock()

        OperatorComparableServiceMock.given.equalTo(
            lhs: .matching { $0 === lhs },
            rhs: .matching { $0 === rhs }
        ).willReturn(true)
        OperatorComparableServiceMock.given.plus(
            lhs: .matching { $0 === lhs },
            rhs: .matching { $0 === rhs }
        ).willReturn(lhs)

        XCTAssertTrue(lhs == rhs)
        XCTAssertTrue((lhs + rhs) === lhs)

        try OperatorComparableServiceMock.verify.equalTo(
            lhs: .matching { $0 === lhs },
            rhs: .matching { $0 === rhs }
        ).once()
        try OperatorComparableServiceMock.verify.plus(
            lhs: .matching { $0 === lhs },
            rhs: .matching { $0 === rhs }
        ).once()
        try OperatorComparableServiceMock.confirmStaticVerified()
        try OperatorComparableServiceMock.checkUnnecessaryStaticStubs()
        OperatorComparableServiceMock.resetStatic()
        #else
        XCTFail("MOCKSYN_ENABLE must be active for generated test doubles")
        #endif
    }

    func testGeneratedEffectfulPropertyGettersSupportStubbingAndVerification() async throws {
        #if MOCKSYN_ENABLE
        EffectfulPropertyServiceMock.resetStatic()
        let mock = EffectfulPropertyServiceMock()

        mock.given.asyncName.get.willReturn("async")
        mock.given.throwingName.get.willThrow(StubbedServiceError.offline)
        mock.given.asyncThrowingName.get.willReturn("async-throws")
        EffectfulPropertyServiceMock.given.staticAsyncThrowingName.get.willReturn("static")

        let asyncName = await mock.asyncName
        XCTAssertEqual(asyncName, "async")
        XCTAssertThrowsError(try mock.throwingName) { error in
            XCTAssertEqual(error as? StubbedServiceError, .offline)
        }
        let asyncThrowingName = try await mock.asyncThrowingName
        let staticAsyncThrowingName = try await EffectfulPropertyServiceMock.staticAsyncThrowingName
        XCTAssertEqual(asyncThrowingName, "async-throws")
        XCTAssertEqual(staticAsyncThrowingName, "static")

        try mock.verify.asyncName.get.once()
        try mock.verify.throwingName.get.once()
        try mock.verify.asyncThrowingName.get.once()
        try EffectfulPropertyServiceMock.verify.staticAsyncThrowingName.get.once()
        try mock.confirmVerified()
        try EffectfulPropertyServiceMock.confirmStaticVerified()
        EffectfulPropertyServiceMock.resetStatic()
        #else
        XCTFail("MOCKSYN_ENABLE must be active for generated test doubles")
        #endif
    }

    func testGeneratedEffectfulPropertySpyDelegatesAndRecordsAsyncGetters() async throws {
        #if MOCKSYN_ENABLE
        let spy = EffectfulPropertySpyServiceSpy(wrapping: RealEffectfulPropertySpyService())

        let asyncName = await spy.asyncName
        let asyncThrowingName = try await spy.asyncThrowingName

        XCTAssertEqual(asyncName, "real-async")
        XCTAssertEqual(asyncThrowingName, "real-async-throws")
        try spy.verify.asyncName.get.once()
        try spy.verify.asyncThrowingName.get.once()
        try spy.confirmVerified()
        #else
        XCTFail("MOCKSYN_ENABLE must be active for generated test doubles")
        #endif
    }

    func testGeneratedMockSupportsQualifiedProtocolInheritance() {
        #if MOCKSYN_ENABLE
        let mock = QualifiedSendableServiceMock()
        let sendable: any Swift.Sendable = mock

        mock.refresh()

        XCTAssertTrue(sendable is QualifiedSendableServiceMock)
        #else
        XCTFail("MOCKSYN_ENABLE must be active for generated test doubles")
        #endif
    }

    func testGeneratedSpyRecordsDelegatedAndInoutCalls() throws {
        #if MOCKSYN_ENABLE
        let spy = MemberCacheStoreSpy(wrapping: RealMemberCacheStore())
        let counter = MutableCounterServiceSpy(wrapping: RealMutableCounterService())
        var value = 1

        XCTAssertEqual(spy.load(id: "1"), "cached-1")
        counter.update(&value)

        XCTAssertEqual(value, 2)
        try spy.verify.load(id: .value("1")).once()
        try counter.verify.update(.value(1)).once()
        #else
        XCTFail("MOCKSYN_ENABLE must be active for generated test doubles")
        #endif
    }

    func testGeneratedVerificationCanWaitForAsyncCall() async throws {
        #if MOCKSYN_ENABLE
        let mock = StubbedUserServiceMock()

        Task {
            try? await Task.sleep(nanoseconds: 20_000_000)
            mock.ping()
        }

        try await mock.verify.ping().wasCalled(.once, timeout: 0.5)
        #else
        XCTFail("MOCKSYN_ENABLE must be active for generated test doubles")
        #endif
    }

    func testGeneratedStubUsesRelaxedDefaultsAndCustomDefaultRegistry() {
        #if MOCKSYN_ENABLE
        let stub = RelaxedDefaultsServiceStub()

        MockSynDefaultValueRegistry.register(StubbedToken(value: "registered"), for: StubbedToken.self)
        defer { MockSynDefaultValueRegistry.reset() }

        XCTAssertEqual(stub.title(), "")
        XCTAssertEqual(stub.count(), 0)
        XCTAssertEqual(stub.enabled(), false)
        XCTAssertNil(stub.optionalName)
        XCTAssertEqual(stub.token(), StubbedToken(value: "registered"))
        #else
        XCTFail("MOCKSYN_ENABLE must be active for generated test doubles")
        #endif
    }

    func testGeneratedDoubleModesCanBeConfiguredPerInstance() {
        #if MOCKSYN_ENABLE
        let relaxedMock = StubbedUserServiceMock(mode: .relaxed)
        let strictStub = RelaxedDefaultsServiceStub(mode: .strict)
        let relaxedSpy = MemberCacheStoreSpy(wrapping: RealMemberCacheStore(), mode: .relaxed)

        XCTAssertEqual(relaxedMock.__mockSyn.mode, .relaxed)
        XCTAssertEqual(strictStub.__mockSyn.mode, .strict)
        XCTAssertEqual(relaxedSpy.__mockSyn.mode, .relaxed)
        XCTAssertEqual(relaxedMock.name(id: "missing"), "")
        XCTAssertEqual(relaxedSpy.load(id: "user"), "cached-user")
        #else
        XCTFail("MOCKSYN_ENABLE must be active for generated test doubles")
        #endif
    }

    func testGeneratedDoubleResetClearsRecordedCallsAndStubs() throws {
        #if MOCKSYN_ENABLE
        let mock = StubbedUserServiceMock(mode: .relaxed)

        mock.given.name(id: .any).willReturn("stubbed")

        XCTAssertEqual(mock.name(id: "42"), "stubbed")
        try mock.verify.name(id: .value("42")).once()

        mock.reset(.invocations)

        try mock.verify.name(id: .any).never()
        XCTAssertEqual(mock.name(id: "42"), "stubbed")

        mock.reset()

        XCTAssertEqual(mock.name(id: "42"), "")
        try mock.verify.name(id: .any).once()
        #else
        XCTFail("MOCKSYN_ENABLE must be active for generated test doubles")
        #endif
    }
}
