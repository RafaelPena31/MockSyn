import MockSyn
import Foundation
import XCTest

extension MockSynGeneratedTypeIntegrationTests {
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
}
