import MockSyn
import Foundation
import XCTest

extension MockSynPublicAPITests {
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
