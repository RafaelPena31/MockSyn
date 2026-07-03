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
        XCTAssertEqual(mock.ping(), "real")
        XCTAssertEqual(mock.__mockSyn.kind, .mock)
        #else
        XCTFail("MOCKSYN_ENABLE must be active for generated test doubles")
        #endif
    }
}
