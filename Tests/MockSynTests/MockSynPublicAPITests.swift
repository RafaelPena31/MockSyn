import MockSyn
import Foundation
import XCTest
#if canImport(ObjectiveC)
import ObjectiveC.runtime
#endif

private enum RuntimeStubError: Error, Equatable {
    case failed
}

private struct ConstructedUser: Equatable {
    let id: String
    let name: String
}

private struct RichRenderedUser: CustomDebugStringConvertible {
    let id: String

    var debugDescription: String {
        "RichRenderedUser(id: \"\(id)\")"
    }
}

private final class ManualFakeService: MockSynFake {
    let __mockSyn = MockSynRuntime(kind: .fake, mode: .relaxed)

    func load(id: String) -> String {
        mockSynRecord(member: "load(id:)", arguments: [id])
        return "fake-\(id)"
    }

    func verifyLoad(id matcher: MockSynMatcher<String>) -> MockSynVerification {
        mockSynVerification(member: "load(id:)", matchers: [matcher.erase()])
    }
}

private final class FailureRecorder: @unchecked Sendable {
    private let lock = NSRecursiveLock()
    private var storedFailures: [MockSynFailure] = []

    var failures: [MockSynFailure] {
        lock.lock()
        defer { lock.unlock() }

        return storedFailures
    }

    func record(_ failure: MockSynFailure) {
        lock.lock()
        defer { lock.unlock() }

        storedFailures.append(failure)
    }
}

private final class AdapterFailureRecorder: @unchecked Sendable {
    private let lock = NSRecursiveLock()
    private var storedFailure: (message: String, file: String, line: UInt)?

    var failure: (message: String, file: String, line: UInt)? {
        lock.lock()
        defer { lock.unlock() }

        return storedFailure
    }

    func record(message: String, file: String, line: UInt) {
        lock.lock()
        defer { lock.unlock() }

        storedFailure = (message, file, line)
    }
}

#if canImport(ObjectiveC)
@objcMembers
private final class ObjCLegacyService: NSObject {
    dynamic func greeting() -> NSString {
        "real"
    }

    dynamic class func build() -> NSString {
        "real-class"
    }
}
#endif

final class MockSynPublicAPITests: XCTestCase {
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

    func testFailureReporterReceivesRuntimeFailures() {
        let recorder = FailureRecorder()
        let runtime = MockSynRuntime(kind: .mock, mode: .strict)

        MockSynFailureReporter.setHandler { failure in
            recorder.record(failure)
        }
        defer { MockSynFailureReporter.reset() }

        XCTAssertThrowsError(
            try runtime.resolveThrowing(member: "missing()", arguments: [], returnType: String.self)
        )

        XCTAssertThrowsError(
            try MockSynVerification(runtime: runtime, member: "save(_:)", matchers: []).once()
        )

        XCTAssertTrue(recorder.failures[0].message.hasPrefix("MockSyn member missing() is not configured"))
        XCTAssertTrue(recorder.failures[1].message.hasPrefix("Expected save(_:) to be called exactly 1 time"))
    }

    func testFailureReporterAdaptersForwardMessageFileAndLine() {
        let xctestRecorder = AdapterFailureRecorder()
        let swiftTestingRecorder = AdapterFailureRecorder()

        MockSynFailureReporter.useXCTest { message, file, line in
            xctestRecorder.record(message: message, file: "\(file)", line: line)
        }
        MockSynFailureReporter.report(MockSynFailure(message: "xctest failure", file: "XCTestFile.swift", line: 41))

        MockSynFailureReporter.useSwiftTesting { message, file, line in
            swiftTestingRecorder.record(message: message, file: "\(file)", line: line)
        }
        MockSynFailureReporter.report(MockSynFailure(message: "swift testing failure", file: "SwiftTestingFile.swift", line: 42))
        MockSynFailureReporter.reset()

        XCTAssertEqual(xctestRecorder.failure?.message, "xctest failure")
        XCTAssertEqual(xctestRecorder.failure?.file, "XCTestFile.swift")
        XCTAssertEqual(xctestRecorder.failure?.line, 41)
        XCTAssertEqual(swiftTestingRecorder.failure?.message, "swift testing failure")
        XCTAssertEqual(swiftTestingRecorder.failure?.file, "SwiftTestingFile.swift")
        XCTAssertEqual(swiftTestingRecorder.failure?.line, 42)

        let directRecorder = FailureRecorder()
        MockSynFailureReporter.setHandler { failure in
            directRecorder.record(failure)
        }
        MockSynFailureReporter.report(
            MockSynRuntimeError.missingStub(member: "direct()"),
            file: "DirectFile.swift",
            line: 43
        )
        MockSynFailureReporter.reset()

        XCTAssertEqual(directRecorder.failures.last?.message, "MockSyn member direct() is not configured")
        XCTAssertEqual(directRecorder.failures.last.map { "\($0.file)" }, "DirectFile.swift")
        XCTAssertEqual(directRecorder.failures.last?.line, 43)
    }

    func testVerificationFailuresForwardFileLineAndRecordedCalls() {
        let recorder = FailureRecorder()
        let runtime = MockSynRuntime(kind: .mock, mode: .strict)

        MockSynFailureReporter.setHandler { failure in
            recorder.record(failure)
        }
        defer { MockSynFailureReporter.reset() }

        runtime.resolveVoid(member: "save(_:)", arguments: ["received"])

        XCTAssertThrowsError(
            try MockSynVerification(
                runtime: runtime,
                member: "save(_:)",
                matchers: [MockSynMatcher<String>.value("expected").erase()]
            ).once(file: "ForwardedFile.swift", line: 123)
        )

        XCTAssertEqual(recorder.failures.last.map { "\($0.file)" }, "ForwardedFile.swift")
        XCTAssertEqual(recorder.failures.last?.line, 123)
        XCTAssertTrue(recorder.failures.last?.message.contains("Recorded calls:") == true)
        XCTAssertTrue(recorder.failures.last?.message.contains(#"save(_:)("received")"#) == true)
    }

    func testRuntimeFailuresRenderArgumentsWithRichStableDescriptions() {
        let recorder = FailureRecorder()
        let runtime = MockSynRuntime(kind: .mock, mode: .strict)
        let callback: () -> Void = {}

        MockSynFailureReporter.setHandler { failure in
            recorder.record(failure)
        }
        defer { MockSynFailureReporter.reset() }

        XCTAssertThrowsError(
            try runtime.resolveThrowing(
                member: "load(_:_:_:_:_:_:_:_:_:_:)",
                arguments: [
                    "secret",
                    Optional<String>.some("value") as Any,
                    Optional<Int>.some(42) as Any,
                    Optional<Int>.none as Any,
                    ["first", "second"],
                    ["id": "42"],
                    Set(["user", "admin"]),
                    String.self,
                    callback,
                    RichRenderedUser(id: "42"),
                    7,
                ],
                returnType: String.self
            )
        )

        let message = recorder.failures.last?.message ?? ""
        XCTAssertTrue(message.contains(#""secret""#), message)
        XCTAssertTrue(message.contains(#""value""#), message)
        XCTAssertTrue(message.contains("42"), message)
        XCTAssertTrue(message.contains("nil"), message)
        XCTAssertTrue(message.contains(#"["first", "second"]"#), message)
        XCTAssertTrue(message.contains(#"["id": "42"]"#), message)
        XCTAssertTrue(message.contains(#"Set(["admin", "user"])"#), message)
        XCTAssertTrue(message.contains("String.Type"), message)
        XCTAssertTrue(message.contains("<closure>"), message)
        XCTAssertTrue(message.contains(#"RichRenderedUser(id: "42")"#), message)
        XCTAssertTrue(message.contains("7"), message)
    }

    func testMatchersSupportOptionalCollectionAndComposedRules() {
        XCTAssertTrue(MockSynMatcher<String?>.`nil`.erase().matches(Optional<String>.none as Any))
        XCTAssertFalse(MockSynMatcher<String?>.`nil`.erase().matches(Optional<String>.some("value") as Any))
        XCTAssertFalse(MockSynMatcher<String?>.`nil`.erase().matches("value"))
        XCTAssertTrue(MockSynMatcher<String?>.notNil.erase().matches(Optional<String>.some("value") as Any))
        XCTAssertFalse(MockSynMatcher<String?>.notNil.erase().matches(Optional<String>.none as Any))

        XCTAssertTrue(MockSynMatcher<[Int]>.isEmpty.erase().matches([Int]() as Any))
        XCTAssertFalse(MockSynMatcher<[Int]>.isEmpty.erase().matches([1] as Any))
        XCTAssertTrue(MockSynMatcher<[Int]>.contains(2).erase().matches([1, 2, 3] as Any))
        XCTAssertFalse(MockSynMatcher<[Int]>.contains(4).erase().matches([1, 2, 3] as Any))
        XCTAssertTrue(MockSynMatcher<Set<String>>.contains("admin").erase().matches(Set(["admin"]) as Any))
        XCTAssertFalse(MockSynMatcher<Set<String>>.contains("guest").erase().matches(Set(["admin"]) as Any))
        XCTAssertTrue(MockSynMatcher<[String: Int]>.contains(key: "count").erase().matches(["count": 1] as Any))
        XCTAssertFalse(MockSynMatcher<[String: Int]>.contains(key: "missing").erase().matches(["count": 1] as Any))
        XCTAssertTrue(MockSynMatcher<[String: Int]>.contains(key: "count", value: 1).erase().matches(["count": 1] as Any))
        XCTAssertFalse(MockSynMatcher<[String: Int]>.contains(key: "count", value: 2).erase().matches(["count": 1] as Any))

        let positive = MockSynMatcher<Int>.matching { $0 > 0 }
        let even = MockSynMatcher<Int>.matching { $0.isMultiple(of: 2) }

        XCTAssertTrue(MockSynMatcher<Int>.all(positive, even).erase().matches(2))
        XCTAssertFalse(MockSynMatcher<Int>.all(positive, even).erase().matches(3))
        XCTAssertTrue(MockSynMatcher<Int>.all().erase().matches(3))
        XCTAssertTrue(MockSynMatcher<Int>.anyOf(.value(1), .value(2)).erase().matches(2))
        XCTAssertFalse(MockSynMatcher<Int>.anyOf(.value(1), .value(2)).erase().matches(3))
        XCTAssertFalse(MockSynMatcher<Int>.anyOf().erase().matches(1))
        XCTAssertTrue(MockSynMatcher<Int>.value(1).not.erase().matches(2))
        XCTAssertFalse(MockSynMatcher<Int>.value(1).not.erase().matches(1))
    }

    func testArgumentCaptorCapturesMatchingValues() {
        let captor = MockSynArgumentCaptor<String>()
        let matcher = captor.capture()

        XCTAssertNil(captor.value)
        XCTAssertEqual(captor.values, [])
        XCTAssertTrue(matcher.erase().matches("first"))
        XCTAssertTrue(matcher.erase().matches("second"))

        XCTAssertEqual(captor.values, ["first", "second"])
        XCTAssertEqual(captor.value, "second")
    }

    func testClosureCaptorCapturesClosures() {
        let captor = MockSynClosureCaptor<(String) -> String>()
        let matcher = captor.capture()
        let closure: (String) -> String = { "hello \($0)" }

        XCTAssertTrue(matcher.erase().matches(closure))

        XCTAssertEqual(captor.value?("Rafael"), "hello Rafael")
    }

    func testDefaultValueRegistryProvidesBuiltInDefaultsAndReset() {
        MockSynDefaultValueRegistry.register("custom", for: String.self)
        XCTAssertEqual(MockSynDefaultValueRegistry.value(for: String.self), "custom")

        MockSynDefaultValueRegistry.register(Optional<String>.none, for: String?.self)
        let customOptional: String?? = MockSynDefaultValueRegistry.value(for: String?.self)
        XCTAssertTrue(customOptional != nil)
        XCTAssertNil(customOptional!)

        MockSynDefaultValueRegistry.reset()

        let optional: String?? = MockSynDefaultValueRegistry.value(for: String?.self)
        let intOptional: Int?? = MockSynDefaultValueRegistry.value(for: Int?.self)
        let void: Void? = MockSynDefaultValueRegistry.value(for: Void.self)

        XCTAssertEqual(MockSynDefaultValueRegistry.value(for: String.self), "")
        XCTAssertEqual(MockSynDefaultValueRegistry.value(for: Int.self), 0)
        XCTAssertEqual(MockSynDefaultValueRegistry.value(for: Bool.self), false)
        XCTAssertEqual(MockSynDefaultValueRegistry.value(for: Double.self), 0.0)
        XCTAssertEqual(MockSynDefaultValueRegistry.value(for: Float.self), Float(0))
        XCTAssertNotNil(void)
        XCTAssertTrue(optional != nil)
        XCTAssertNil(optional!)
        XCTAssertTrue(intOptional != nil)
        XCTAssertNil(intOptional!)
        XCTAssertNil(MockSynDefaultValueRegistry.value(for: Date.self))
    }

    func testRuntimeUsesMatchingMatcherAndFallbacks() throws {
        let runtime = MockSynRuntime(kind: .mock, mode: .strict)

        MockSynStubBuilder1<Int, String>(
            runtime: runtime,
            member: "score(_:)",
            matchers: [MockSynMatcher<Int>.matching { $0 > 10 }.erase()]
        ).willReturn("high")

        XCTAssertEqual(runtime.resolve(member: "score(_:)", arguments: [11], returnType: String.self), "high")
        XCTAssertEqual(runtime.resolve(member: "score(_:)", arguments: [5], returnType: String.self, fallback: { "low" }), "low")
        XCTAssertEqual(runtime.resolve(member: "score(_:)", arguments: [], returnType: String.self, fallback: { "missing-argument" }), "missing-argument")
        XCTAssertEqual(runtime.resolve(member: "score(_:)", arguments: ["bad"], returnType: String.self, fallback: { "type-mismatch" }), "type-mismatch")

        XCTAssertThrowsError(
            try runtime.resolveThrowing(member: "missing()", arguments: [], returnType: String.self) {
                throw RuntimeStubError.failed
            }
        ) { error in
            XCTAssertEqual(error as? RuntimeStubError, .failed)
        }

        XCTAssertThrowsError(
            try runtime.resolveThrowing(member: "strictMissing()", arguments: [], returnType: String.self)
        ) { error in
            XCTAssertEqual(error as? MockSynRuntimeError, .missingStub(member: "strictMissing()"))
            XCTAssertEqual(String(describing: error), "MockSyn member strictMissing() is not configured")
        }
    }

    func testRuntimeBuildersSupportThrowingAndTwoArgumentRunClosures() throws {
        let runtime = MockSynRuntime(kind: .mock, mode: .strict)

        MockSynStubBuilder1<String, String>(
            runtime: runtime,
            member: "load(id:)",
            matchers: [MockSynMatcher<String>.any.erase()]
        ).willThrow(RuntimeStubError.failed)

        MockSynStubBuilder2<Int, Int, Int>(
            runtime: runtime,
            member: "sum(_:_:)",
            matchers: [MockSynMatcher<Int>.any.erase(), MockSynMatcher<Int>.any.erase()]
        ).willRun { lhs, rhs in
            lhs + rhs
        }

        MockSynStubBuilder2<Int, Int, Int>(
            runtime: runtime,
            member: "throwingSum(_:_:)",
            matchers: [MockSynMatcher<Int>.any.erase(), MockSynMatcher<Int>.any.erase()]
        ).willThrow(RuntimeStubError.failed)

        XCTAssertThrowsError(
            try runtime.resolveThrowing(member: "load(id:)", arguments: ["42"], returnType: String.self)
        ) { error in
            XCTAssertEqual(error as? RuntimeStubError, .failed)
        }
        XCTAssertEqual(runtime.resolve(member: "sum(_:_:)", arguments: [2, 3], returnType: Int.self), 5)
        XCTAssertThrowsError(
            try runtime.resolveThrowing(member: "throwingSum(_:_:)", arguments: [2, 3], returnType: Int.self)
        ) { error in
            XCTAssertEqual(error as? RuntimeStubError, .failed)
        }
    }

    func testRethrowingRuntimeAndBuildersUseNonThrowingStubsAndThrowingFallbacks() throws {
        let runtime = MockSynRuntime(kind: .spy, mode: .strict)

        MockSynRethrowingStubBuilder<String>(
            runtime: runtime,
            member: "title()"
        ).willReturn("stubbed")

        MockSynRethrowingStubBuilder1<String, String>(
            runtime: runtime,
            member: "format(_:)",
            matchers: [MockSynMatcher<String>.any.erase()]
        ).willRun { value in
            value.uppercased()
        }

        MockSynRethrowingStubBuilder2<Int, Int, Int>(
            runtime: runtime,
            member: "sum(_:_:)",
            matchers: [MockSynMatcher<Int>.any.erase(), MockSynMatcher<Int>.any.erase()]
        ).willRun { lhs, rhs in
            lhs + rhs
        }

        MockSynRethrowingStubBuilder2<Int, Int, Int>(
            runtime: runtime,
            member: "product(_:_:)",
            matchers: [MockSynMatcher<Int>.any.erase(), MockSynMatcher<Int>.any.erase()]
        ).willReturn(10, 20)

        XCTAssertEqual(try runtime.resolveRethrowing(member: "title()", arguments: [], returnType: String.self) {
            throw RuntimeStubError.failed
        }, "stubbed")
        XCTAssertEqual(try runtime.resolveRethrowing(member: "format(_:)", arguments: ["mock"], returnType: String.self) {
            throw RuntimeStubError.failed
        }, "MOCK")
        XCTAssertEqual(try runtime.resolveRethrowing(member: "sum(_:_:)", arguments: [2, 5], returnType: Int.self) {
            throw RuntimeStubError.failed
        }, 7)
        XCTAssertEqual(try runtime.resolveRethrowing(member: "product(_:_:)", arguments: [2, 5], returnType: Int.self) {
            throw RuntimeStubError.failed
        }, 10)
        XCTAssertEqual(try runtime.resolveRethrowing(member: "product(_:_:)", arguments: [2, 5], returnType: Int.self) {
            throw RuntimeStubError.failed
        }, 20)

        XCTAssertThrowsError(try runtime.resolveRethrowing(member: "missing()", arguments: [], returnType: String.self) {
            throw RuntimeStubError.failed
        }) { error in
            XCTAssertEqual(error as? RuntimeStubError, .failed)
        }

        MockSynRethrowingStubBuilder<Void>(
            runtime: runtime,
            member: "consume()"
        ).willRun {}
        try runtime.resolveVoidRethrowing(member: "consume()", arguments: []) {
            throw RuntimeStubError.failed
        }

        XCTAssertThrowsError(try runtime.resolveVoidRethrowing(member: "missingVoid()", arguments: []) {
            throw RuntimeStubError.failed
        }) { error in
            XCTAssertEqual(error as? RuntimeStubError, .failed)
        }
    }

    func testSubscriptSetterBuilderSupportsThrowingBehavior() {
        let runtime = MockSynRuntime(kind: .mock, mode: .strict)

        MockSynSubscriptSetterStubBuilder<String>(
            runtime: runtime,
            member: "subscript(key:).set",
            matchers: [MockSynMatcher<String>.any.erase(), MockSynMatcher<String>.any.erase()]
        ).willThrow(RuntimeStubError.failed)

        XCTAssertThrowsError(
            try runtime.resolveVoidThrowing(member: "subscript(key:).set", arguments: ["theme", "dark"])
        ) { error in
            XCTAssertEqual(error as? RuntimeStubError, .failed)
        }
    }

    func testRuntimeVerificationCountsArgumentsAndConfirmVerified() throws {
        let runtime = MockSynRuntime(kind: .mock, mode: .strict)

        runtime.resolveVoid(member: "save(_:)", arguments: ["first"])
        runtime.resolveVoid(member: "save(_:)", arguments: ["second"])
        runtime.resolveVoid(member: "refresh()", arguments: [])

        try MockSynVerification(runtime: runtime, member: "save(_:)", matchers: [
            MockSynMatcher<String>.value("first").erase(),
        ]).once()
        try MockSynVerification(runtime: runtime, member: "save(_:)", matchers: [
            MockSynMatcher<String>.any.erase(),
        ]).times(2)
        try MockSynVerification(runtime: runtime, member: "missing()", matchers: []).never()

        XCTAssertThrowsError(try runtime.confirmVerified()) { error in
            XCTAssertTrue(String(describing: error).contains("refresh()"))
        }

        try MockSynVerification(runtime: runtime, member: "refresh()", matchers: []).wasCalled(.once)
        try runtime.confirmVerified()
    }

    func testRuntimeVerificationSupportsAtLeastAtMostAndFailureDescriptions() throws {
        let runtime = MockSynRuntime(kind: .mock, mode: .strict)

        runtime.resolveVoid(member: "refresh()", arguments: [])
        runtime.resolveVoid(member: "refresh()", arguments: [])

        try MockSynVerification(runtime: runtime, member: "refresh()", matchers: []).atLeast(1)
        try MockSynVerification(runtime: runtime, member: "refresh()", matchers: []).atMost(2)

        XCTAssertThrowsError(
            try MockSynVerification(runtime: runtime, member: "refresh()", matchers: []).times(1)
        ) { error in
            XCTAssertEqual(
                String(describing: error),
                "Expected refresh() to be called exactly 1 time, but it was called 2 times"
            )
        }
    }

    func testRuntimeVerificationErrorDescriptionsCoverAllCountKinds() {
        XCTAssertEqual(
            String(describing: MockSynVerificationError.expected(member: "refresh()", count: .once, actual: 0)),
            "Expected refresh() to be called exactly 1 time, but it was called 0 times"
        )
        XCTAssertEqual(
            String(describing: MockSynVerificationError.expected(member: "refresh()", count: .never, actual: 1)),
            "Expected refresh() to be called 0 times, but it was called 1 time"
        )
        XCTAssertEqual(
            String(describing: MockSynVerificationError.expected(member: "refresh()", count: .atLeast(2), actual: 1)),
            "Expected refresh() to be called at least 2 times, but it was called 1 time"
        )
        XCTAssertEqual(
            String(describing: MockSynVerificationError.expected(member: "refresh()", count: .atMost(1), actual: 2)),
            "Expected refresh() to be called at most 1 time, but it was called 2 times"
        )
    }

    func testRuntimeVerificationSupportsOrderAcrossRuntimes() throws {
        let firstRuntime = MockSynRuntime(kind: .mock, mode: .strict)
        let secondRuntime = MockSynRuntime(kind: .mock, mode: .strict)

        firstRuntime.resolveVoid(member: "start()", arguments: [])
        secondRuntime.resolveVoid(member: "finish()", arguments: [])

        try MockSynVerifier.verifyOrder(
            MockSynVerification(runtime: firstRuntime, member: "start()", matchers: []),
            MockSynVerification(runtime: secondRuntime, member: "finish()", matchers: [])
        )

        XCTAssertThrowsError(
            try MockSynVerifier.verifyOrder(
                MockSynVerification(runtime: secondRuntime, member: "finish()", matchers: []),
                MockSynVerification(runtime: firstRuntime, member: "start()", matchers: [])
            )
        ) { error in
            XCTAssertTrue(String(describing: error).contains("Expected calls to happen in order"))
        }

        XCTAssertThrowsError(
            try MockSynVerifier.verifyOrder(MockSynVerification(runtime: firstRuntime, member: "missing()", matchers: []))
        ) { error in
            XCTAssertEqual(
                String(describing: error),
                "Expected missing() to be called at least 1 time, but it was called 0 times"
            )
        }
    }

    func testRuntimeDetectsUnnecessaryStubs() throws {
        let runtime = MockSynRuntime(kind: .mock, mode: .strict)

        MockSynStubBuilder<String>(runtime: runtime, member: "unused()").willReturn("unused")
        MockSynStubBuilder<String>(runtime: runtime, member: "used()").willReturn("used")

        XCTAssertEqual(runtime.resolve(member: "used()", arguments: [], returnType: String.self), "used")

        XCTAssertThrowsError(try runtime.checkUnnecessaryStubs()) { error in
            XCTAssertTrue(String(describing: error).contains("unused()"))
        }
    }

    func testRuntimeVerificationCanWaitForAsyncCalls() async throws {
        let runtime = MockSynRuntime(kind: .mock, mode: .strict)
        let verification = MockSynVerification(runtime: runtime, member: "finish()", matchers: [])

        Task {
            try? await Task.sleep(nanoseconds: 20_000_000)
            runtime.resolveVoid(member: "finish()", arguments: [])
        }

        try await verification.wasCalled(.once, timeout: 0.5)
    }

    func testRuntimeVerificationTimeoutFailsWhenCallNeverArrives() async {
        let runtime = MockSynRuntime(kind: .mock, mode: .strict)
        let verification = MockSynVerification(runtime: runtime, member: "finish()", matchers: [])

        do {
            try await verification.wasCalled(.once, timeout: 0.001, pollInterval: 0.001)
            XCTFail("Expected timeout verification to throw")
        } catch {
            XCTAssertEqual(
                String(describing: error),
                "Expected finish() to be called exactly 1 time, but it was called 0 times"
            )
        }
    }

    func testRuntimeVerificationTimeoutCanSucceedAfterDeadlineWhenFinalCountMatches() async throws {
        let runtime = MockSynRuntime(kind: .mock, mode: .strict)
        let verification = MockSynVerification(runtime: runtime, member: "finish()", matchers: [])

        try await verification.wasCalled(.never, timeout: 0)
    }

    func testStrictUnstubbedCrashHarness() {
        guard ProcessInfo.processInfo.environment["MOCKSYN_CRASH_CASE"] == "strict-unconfigured" else {
            return
        }

        let runtime = MockSynRuntime(kind: .mock, mode: .strict)
        _ = runtime.resolve(member: "missing()", arguments: [], returnType: String.self)
    }

    func testStrictUnstubbedNonVoidCallCrashesInSubprocess() throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
        process.arguments = [
            "xctest",
            "-XCTest",
            "MockSynTests.MockSynPublicAPITests/testStrictUnstubbedCrashHarness",
            Bundle(for: Self.self).bundlePath,
        ]
        process.environment = ProcessInfo.processInfo.environment.merging([
            "MOCKSYN_CRASH_CASE": "strict-unconfigured",
        ]) { _, new in new }
        process.standardOutput = Pipe()
        process.standardError = Pipe()

        try process.run()
        process.waitUntilExit()

        XCTAssertNotEqual(process.terminationStatus, 0)
    }

    func testConstructorFactoryUsesOriginalZeroArgumentConstructorByDefault() {
        let constructor = MockSynConstructor {
            ConstructedUser(id: "original", name: "Original")
        }

        XCTAssertEqual(constructor(), ConstructedUser(id: "original", name: "Original"))
    }

    func testConstructorFactoryCanReplaceAndRestoreZeroArgumentConstructor() {
        let constructor = MockSynConstructor {
            ConstructedUser(id: "original", name: "Original")
        }
        let interception = constructor.replace {
            ConstructedUser(id: "mock", name: "Mock")
        }

        XCTAssertEqual(constructor(), ConstructedUser(id: "mock", name: "Mock"))

        interception.restore()
        interception.restore()

        XCTAssertEqual(constructor(), ConstructedUser(id: "original", name: "Original"))
    }

    func testConstructorFactoryRestoresReplacementOnTokenDeinit() {
        let constructor = MockSynConstructor {
            ConstructedUser(id: "original", name: "Original")
        }

        do {
            let interception = constructor.replace {
                ConstructedUser(id: "scoped", name: "Scoped")
            }
            XCTAssertEqual(constructor(), ConstructedUser(id: "scoped", name: "Scoped"))
            _ = interception
        }

        XCTAssertEqual(constructor(), ConstructedUser(id: "original", name: "Original"))
    }

    func testConstructorFactoryForwardsOneArgumentToReplacement() {
        let constructor = MockSynConstructor1<String, ConstructedUser> { id in
            ConstructedUser(id: id, name: "Original")
        }
        let interception = constructor.replace { id in
            ConstructedUser(id: id, name: "Mock")
        }

        XCTAssertEqual(constructor("42"), ConstructedUser(id: "42", name: "Mock"))

        interception.restore()

        XCTAssertEqual(constructor("42"), ConstructedUser(id: "42", name: "Original"))
    }

    func testConstructorFactoryForwardsTwoArgumentsToReplacement() {
        let constructor = MockSynConstructor2<String, String, ConstructedUser> { id, name in
            ConstructedUser(id: id, name: name)
        }
        let interception = constructor.replace { id, name in
            ConstructedUser(id: "mock-\(id)", name: name.uppercased())
        }

        XCTAssertEqual(constructor("42", "Rafa"), ConstructedUser(id: "mock-42", name: "RAFA"))

        interception.restore()

        XCTAssertEqual(constructor("42", "Rafa"), ConstructedUser(id: "42", name: "Rafa"))
    }

    #if canImport(ObjectiveC)
    func testObjCInterceptionReplacesAndRestoresInstanceMethod() throws {
        let replacement: @convention(block) (AnyObject) -> NSString = { _ in "mock" }
        let interception = try MockSynObjCInterception.replaceInstanceMethod(
            on: ObjCLegacyService.self,
            selector: #selector(ObjCLegacyService.greeting),
            with: replacement
        )

        XCTAssertEqual(ObjCLegacyService().greeting(), "mock")

        interception.restore()
        interception.restore()

        XCTAssertEqual(ObjCLegacyService().greeting(), "real")
    }

    func testObjCInterceptionRestoresInstanceMethodOnDeinit() throws {
        do {
            let replacement: @convention(block) (AnyObject) -> NSString = { _ in "scoped" }
            let interception = try MockSynObjCInterception.replaceInstanceMethod(
                on: ObjCLegacyService.self,
                selector: #selector(ObjCLegacyService.greeting),
                with: replacement
            )
            XCTAssertEqual(ObjCLegacyService().greeting(), "scoped")
            _ = interception
        }

        XCTAssertEqual(ObjCLegacyService().greeting(), "real")
    }

    func testObjCInterceptionReplacesAndRestoresClassMethod() throws {
        let replacement: @convention(block) (AnyClass) -> NSString = { _ in "mock-class" }
        let interception = try MockSynObjCInterception.replaceClassMethod(
            on: ObjCLegacyService.self,
            selector: #selector(ObjCLegacyService.build),
            with: replacement
        )

        XCTAssertEqual(ObjCLegacyService.build(), "mock-class")

        interception.restore()

        XCTAssertEqual(ObjCLegacyService.build(), "real-class")
    }

    func testObjCInterceptionReportsMissingMethod() {
        XCTAssertThrowsError(try MockSynObjCInterception.replaceInstanceMethod(
            on: ObjCLegacyService.self,
            selector: NSSelectorFromString("missingSelector"),
            with: ({ _ in "unused" } as @convention(block) (AnyObject) -> NSString)
        )) { error in
            XCTAssertEqual(
                String(describing: error),
                "MockSyn could not find Objective-C instance method missingSelector on ObjCLegacyService."
            )
        }
    }

    func testObjCInterceptionReportsMissingClassMethod() {
        XCTAssertThrowsError(try MockSynObjCInterception.replaceClassMethod(
            on: ObjCLegacyService.self,
            selector: NSSelectorFromString("missingClassSelector"),
            with: ({ _ in "unused" } as @convention(block) (AnyClass) -> NSString)
        )) { error in
            XCTAssertEqual(
                String(describing: error),
                "MockSyn could not find Objective-C class method missingClassSelector on ObjCLegacyService."
            )
        }
    }
    #endif
}
