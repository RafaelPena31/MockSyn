import MockSyn
import Foundation
import XCTest

extension MockSynGeneratedTypeIntegrationTests {
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
