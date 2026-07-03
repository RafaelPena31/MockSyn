import MockSyn
import Foundation
import XCTest

extension MockSynGeneratedTypeIntegrationTests {
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
}
