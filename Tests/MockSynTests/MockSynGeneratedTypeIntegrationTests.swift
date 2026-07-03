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
}
