import MockSyn
import Foundation
import XCTest

private enum RuntimeStubError: Error, Equatable {
    case failed
}

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
}
