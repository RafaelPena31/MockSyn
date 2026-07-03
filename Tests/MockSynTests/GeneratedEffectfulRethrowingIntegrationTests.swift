import MockSyn
import Foundation
import XCTest

extension MockSynGeneratedTypeIntegrationTests {
    func testGeneratedRethrowingMembersPreserveRethrowsAndUseNonThrowingStubs() throws {
        #if MOCKSYN_ENABLE
        RethrowingServiceMock.resetStatic()
        let mock = RethrowingServiceMock()
        var consumed = false
        var staticConsumed = false

        mock.given.transform(.any).willReturn("stubbed")
        mock.given.consume(.any).willRun { _ in
            consumed = true
        }
        RethrowingServiceMock.given.make(.any).willReturn("static-stubbed")
        RethrowingServiceMock.given.save(.any).willRun { _ in
            staticConsumed = true
        }

        let transformed = try mock.transform {
            throw StubbedServiceError.offline
        }
        try mock.consume {
            throw StubbedServiceError.offline
        }
        let staticValue = try RethrowingServiceMock.make {
            throw StubbedServiceError.offline
        }
        try RethrowingServiceMock.save {
            throw StubbedServiceError.offline
        }

        XCTAssertEqual(transformed, "stubbed")
        XCTAssertTrue(consumed)
        XCTAssertTrue(staticConsumed)
        XCTAssertEqual(staticValue, "static-stubbed")

        try mock.verify.transform(.any).once()
        try mock.verify.consume(.any).once()
        try RethrowingServiceMock.verify.make(.any).once()
        try RethrowingServiceMock.verify.save(.any).once()
        RethrowingServiceMock.resetStatic()

        let stubbedSpy = RethrowingSpyServiceSpy(wrapping: RealRethrowingSpyService())
        stubbedSpy.given.transform(.any).willReturn("spy-stubbed")

        let stubbedSpyValue = try stubbedSpy.transform {
            throw StubbedServiceError.offline
        }

        XCTAssertEqual(stubbedSpyValue, "spy-stubbed")
        try stubbedSpy.verify.transform(.any).once()

        let spy = RethrowingSpyServiceSpy(wrapping: RealRethrowingSpyService())
        let delegated = spy.transform {
            "delegated"
        }

        XCTAssertEqual(delegated, "delegated")
        XCTAssertThrowsError(try spy.consume {
            throw StubbedServiceError.offline
        }) { error in
            XCTAssertEqual(error as? StubbedServiceError, .offline)
        }

        try spy.verify.transform(.any).once()
        try spy.verify.consume(.any).once()
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
}
