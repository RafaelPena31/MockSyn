import MockSyn
import Foundation
import XCTest

extension MockSynGeneratedTypeIntegrationTests {
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

    func testGeneratedClassMockMirrorsInitializerAndCallsSuperclassInitializer() {
        #if MOCKSYN_ENABLE
        ClassInitializerMirrorLog.reset()

        let mock = SeededUserServiceBaseMock(seed: "mock-seed", mode: .relaxed)
        let base: SeededUserServiceBase = mock

        XCTAssertTrue(base === mock)
        XCTAssertEqual(ClassInitializerMirrorLog.mockSeed, "mock-seed")
        XCTAssertEqual(mock.__mockSyn.kind, .mock)
        XCTAssertEqual(mock.__mockSyn.mode, .relaxed)
        #else
        XCTFail("MOCKSYN_ENABLE must be active for generated test doubles")
        #endif
    }

    func testGeneratedClassMockMirrorsRequiredInitializerAndCustomModeInitializer() {
        #if MOCKSYN_ENABLE
        ClassInitializerMirrorLog.reset()

        let requiredMock = RequiredSeededUserServiceBaseMock(seed: "required-seed")

        XCTAssertEqual(ClassInitializerMirrorLog.requiredMockSeed, "required-seed")
        XCTAssertEqual(requiredMock.__mockSyn.kind, .mock)
        XCTAssertEqual(requiredMock.__mockSyn.mode, .strict)

        let relaxedMock = RequiredSeededUserServiceBaseMock(seed: "relaxed-seed", mode: .relaxed)

        XCTAssertEqual(ClassInitializerMirrorLog.requiredMockSeed, "relaxed-seed")
        XCTAssertEqual(relaxedMock.__mockSyn.kind, .mock)
        XCTAssertEqual(relaxedMock.__mockSyn.mode, .relaxed)
        #else
        XCTFail("MOCKSYN_ENABLE must be active for generated test doubles")
        #endif
    }

    func testGeneratedClassStubMirrorsInitializerAndCallsSuperclassInitializer() {
        #if MOCKSYN_ENABLE
        ClassInitializerMirrorLog.reset()

        let stub = SeededAnalyticsServiceBaseStub(seed: "stub-seed", mode: .strict)
        let base: SeededAnalyticsServiceBase = stub

        XCTAssertTrue(base === stub)
        XCTAssertEqual(ClassInitializerMirrorLog.stubSeed, "stub-seed")
        XCTAssertEqual(stub.__mockSyn.kind, .stub)
        XCTAssertEqual(stub.__mockSyn.mode, .strict)
        #else
        XCTFail("MOCKSYN_ENABLE must be active for generated test doubles")
        #endif
    }

    func testGeneratedClassSpyMirrorsInitializerAndCallsSuperclassInitializer() {
        #if MOCKSYN_ENABLE
        ClassInitializerMirrorLog.reset()

        let wrapped = SeededCacheStoreBase(seed: "wrapped-seed")
        let spy = SeededCacheStoreBaseSpy(wrapping: wrapped, seed: "spy-seed", mode: .relaxed)
        let base: SeededCacheStoreBase = spy

        XCTAssertTrue(base === spy)
        XCTAssertTrue(spy.__mockSynWrapped === wrapped)
        XCTAssertEqual(ClassInitializerMirrorLog.spySeed, "spy-seed")
        XCTAssertEqual(spy.__mockSyn.kind, .spy)
        XCTAssertEqual(spy.__mockSyn.mode, .relaxed)
        #else
        XCTFail("MOCKSYN_ENABLE must be active for generated test doubles")
        #endif
    }

    #if canImport(ObjectiveC)
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
    #endif

    func testGeneratedObservedClassPropertiesExposeSetterCapabilities() throws {
        #if MOCKSYN_ENABLE
        let mock = ObservedPropertyServiceBaseMock()
        let willSetStubber: MockSynNonThrowingPropertyStubber<String> = mock.given.willSetValue
        let didSetStubber: MockSynNonThrowingPropertyStubber<String> = mock.given.didSetValue
        let willSetVerification: MockSynPropertyVerification<String> = mock.verify.willSetValue
        let didSetVerification: MockSynPropertyVerification<String> = mock.verify.didSetValue

        willSetStubber.set(.value("will")).willRun { _ in }
        didSetStubber.set(.value("did")).willRun { _ in }

        mock.willSetValue = "will"
        mock.didSetValue = "did"

        try willSetVerification.set(.value("will")).once()
        try didSetVerification.set(.value("did")).once()
        #else
        XCTFail("MOCKSYN_ENABLE must be active for generated test doubles")
        #endif
    }
}
