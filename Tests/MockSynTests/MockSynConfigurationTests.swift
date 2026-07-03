import MockSyn
import Foundation
import XCTest

extension MockSynPublicAPITests {
    func testModeDescriptionsMatchMacroGeneratedSource() {
        XCTAssertEqual(MockSynMode.strict.generatedSourceName, ".strict")
        XCTAssertEqual(MockSynMode.relaxed.generatedSourceName, ".relaxed")
    }

    func testAccessDescriptionsMatchMacroGeneratedSource() {
        XCTAssertEqual(MockSynAccess.internal.generatedSourceName, "internal")
        XCTAssertEqual(MockSynAccess.public.generatedSourceName, "public")
        XCTAssertEqual(MockSynAccess.package.generatedSourceName, "package")
        XCTAssertEqual(MockSynAccess.fileprivate.generatedSourceName, "fileprivate")
        XCTAssertEqual(MockSynAccess.private.generatedSourceName, "private")
    }

    func testRuntimeStoresDoubleKindAndMode() {
        let runtime = MockSynRuntime(kind: .spy, mode: .relaxed)

        XCTAssertEqual(runtime.kind, .spy)
        XCTAssertEqual(runtime.mode, .relaxed)
    }

    func testStrictStubRuntimeDoesNotReturnRelaxedDefaults() {
        let runtime = MockSynRuntime(kind: .stub, mode: .strict)

        XCTAssertThrowsError(
            try runtime.resolveThrowing(member: "title()", arguments: [], returnType: String.self)
        ) { error in
            XCTAssertEqual(error as? MockSynRuntimeError, .missingStub(member: "title()"))
        }
    }

    func testManualFakeHelperRecordsAndVerifiesCalls() throws {
        let fake = ManualFakeService()

        XCTAssertEqual(fake.load(id: "42"), "fake-42")
        XCTAssertEqual(fake.__mockSyn.kind, .fake)

        try fake.verifyLoad(id: .value("42")).once()
        try fake.mockSynConfirmVerified()
        fake.mockSynReset(.invocations)
        try fake.verifyLoad(id: .any).never()
        try fake.mockSynCheckUnnecessaryStubs()
    }

    func testRuntimeResetClearsInvocationsAndStubsByScope() throws {
        let runtime = MockSynRuntime(kind: .mock, mode: .strict)

        MockSynStubBuilder<String>(
            runtime: runtime,
            member: "title()"
        ).willReturn("stubbed")

        XCTAssertEqual(runtime.resolve(member: "title()", arguments: [], returnType: String.self), "stubbed")
        try MockSynVerification(runtime: runtime, member: "title()", matchers: []).once()

        runtime.reset(.invocations)

        try MockSynVerification(runtime: runtime, member: "title()", matchers: []).never()
        XCTAssertEqual(runtime.resolve(member: "title()", arguments: [], returnType: String.self), "stubbed")

        runtime.reset(.stubs)

        XCTAssertEqual(
            runtime.resolve(member: "title()", arguments: [], returnType: String.self, fallback: { "fallback" }),
            "fallback"
        )

        runtime.resolveVoid(member: "refresh()", arguments: [])
        runtime.reset()

        try MockSynVerification(runtime: runtime, member: "refresh()", matchers: []).never()
        try runtime.checkUnnecessaryStubs()
    }
}
