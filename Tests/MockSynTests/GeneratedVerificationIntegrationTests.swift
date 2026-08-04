import MockSyn
import Foundation
import XCTest

extension MockSynGeneratedTypeIntegrationTests {
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

    @MainActor
    func testGeneratedVerificationCanWaitForAsyncCall() async throws {
        #if MOCKSYN_ENABLE
        let mock = StubbedUserServiceMock()

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 20_000_000)
            mock.ping()
        }

        try await mock.verify.ping().wasCalled(.once, timeout: 0.5)
        #else
        XCTFail("MOCKSYN_ENABLE must be active for generated test doubles")
        #endif
    }
}
