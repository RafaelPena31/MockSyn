import MockSyn
import Foundation
import XCTest

extension MockSynGeneratedTypeIntegrationTests {
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

    func testGeneratedMockUsesGenericSubscriptStubbingAndVerification() throws {
        #if MOCKSYN_ENABLE
        let mock = GenericSubscriptServiceMock()
        var assignedValue: String?

        mock.given.subscript(key: .value("name"), default: .value("fallback")).get.willReturn("Rafael")
        mock.given.subscript(key: .value("name"), default: .value("fallback")).set(.value("assigned")).willRun { newValue in
            assignedValue = newValue
        }
        let optionalStub: MockSynNonThrowingReadOnlySubscriptStubber<Int?> = mock.given.subscript(optional: .value("score"))
        optionalStub.get.willReturn(42)

        let name: String = mock["name", default: "fallback"]
        mock["name", default: "fallback"] = "assigned"
        let score: Int? = mock[optional: "score"]

        XCTAssertEqual(name, "Rafael")
        XCTAssertEqual(assignedValue, "assigned")
        XCTAssertEqual(score, 42)

        try mock.verify.subscript(key: .value("name"), default: .value("fallback")).get.once()
        try mock.verify.subscript(key: .value("name"), default: .value("fallback")).set(.value("assigned")).once()
        let optionalVerification: MockSynReadOnlySubscriptVerification<Int?> = mock.verify.subscript(optional: .value("score"))
        try optionalVerification.get.once()
        try mock.confirmVerified()
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
}
