import MockSyn
import Foundation
import XCTest

extension MockSynGeneratedTypeIntegrationTests {
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
}
