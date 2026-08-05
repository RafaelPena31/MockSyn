import MockSyn
import Foundation
import XCTest

extension MockSynGeneratedTypeIntegrationTests {
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

    func testGeneratedProtocolSpyDelegatesVariadicArguments() throws {
        #if MOCKSYN_ENABLE
        let spy = VariadicSumServiceSpy(wrapping: RealVariadicSumService(), mode: .relaxed)

        let result = spy.sum(1, 2, 3)

        XCTAssertEqual(result, 6)
        try spy.verify.sum(.value([1, 2, 3])).once()
        try spy.confirmVerified()
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

    func testGeneratedMainActorMockPreservesIsolation() async {
        #if MOCKSYN_ENABLE
        await MainActor.run {
            let mock = MainActorServiceMock()

            mock.refresh()

            XCTAssertEqual(mock.__mockSyn.kind, .mock)
        }
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
}
