import MockSyn
import Foundation
import XCTest

private struct RuntimeResolutionDomainValue: Equatable {
    let value: String
}

private let runtimeFailureMarker = "MOCKSYN_FAILURE_REPORTED"

extension MockSynPublicAPITests {
    func testBuilderWillReturnResolvesOneAndMultipleValuesThenRepeatsLast() {
        let runtime = MockSynRuntime(kind: .mock, mode: .strict)

        MockSynNonThrowingStubBuilder<Int>(
            runtime: runtime,
            member: "singleBuilder()"
        ).willReturn(7)
        MockSynNonThrowingStubBuilder<Int>(
            runtime: runtime,
            member: "multipleBuilder()"
        ).willReturn(10, 20)

        XCTAssertEqual(runtime.resolve(member: "singleBuilder()", arguments: [], returnType: Int.self), 7)
        XCTAssertEqual(runtime.resolve(member: "singleBuilder()", arguments: [], returnType: Int.self), 7)
        XCTAssertEqual(runtime.resolve(member: "multipleBuilder()", arguments: [], returnType: Int.self), 10)
        XCTAssertEqual(runtime.resolve(member: "multipleBuilder()", arguments: [], returnType: Int.self), 20)
        XCTAssertEqual(runtime.resolve(member: "multipleBuilder()", arguments: [], returnType: Int.self), 20)
    }

    func testReturnBehaviorResolvesFirstAndRemainingValuesThenRepeatsLast() {
        let runtime = MockSynRuntime(kind: .mock, mode: .strict)

        runtime.registerStub(
            member: "single()",
            matchers: [],
            behavior: MockSynStubBehavior<Int>.returns(7)
        )
        runtime.registerStub(
            member: "multiple()",
            matchers: [],
            behavior: MockSynStubBehavior<Int>.returns(10, 20)
        )

        XCTAssertEqual(runtime.resolve(member: "single()", arguments: [], returnType: Int.self), 7)
        XCTAssertEqual(runtime.resolve(member: "single()", arguments: [], returnType: Int.self), 7)
        XCTAssertEqual(runtime.resolve(member: "multiple()", arguments: [], returnType: Int.self), 10)
        XCTAssertEqual(runtime.resolve(member: "multiple()", arguments: [], returnType: Int.self), 20)
        XCTAssertEqual(runtime.resolve(member: "multiple()", arguments: [], returnType: Int.self), 20)
    }

    func testArrayReturnBehaviorRemainsSourceCompatibleAndRepeatsLast() {
        let runtime = MockSynRuntime(kind: .mock, mode: .strict)
        runtime.registerStub(
            member: "arrayReturns()",
            matchers: [],
            behavior: MockSynStubBehavior<Int>.returns([10, 20])
        )

        XCTAssertEqual(runtime.resolve(member: "arrayReturns()", arguments: [], returnType: Int.self), 10)
        XCTAssertEqual(runtime.resolve(member: "arrayReturns()", arguments: [], returnType: Int.self), 20)
        XCTAssertEqual(runtime.resolve(member: "arrayReturns()", arguments: [], returnType: Int.self), 20)
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

    func testSubscriptSetterBuilderRunsNonThrowingBehavior() {
        let runtime = MockSynRuntime(kind: .mock, mode: .strict)
        var assignedValue: String?

        let builder: MockSynNonThrowingSubscriptSetterStubBuilder<String> = MockSynSubscriptSetterStubBuilder<String>(
            runtime: runtime,
            member: "subscript(key:).set",
            matchers: [MockSynMatcher<String>.any.erase(), MockSynMatcher<String>.any.erase()]
        )
        builder.willRun { value in
            assignedValue = value
        }

        runtime.resolveVoid(member: "subscript(key:).set", arguments: ["theme", "dark"])

        XCTAssertEqual(assignedValue, "dark")
    }

    func testStrictUnstubbedStringReturnsDefaultAndReportsFailure() {
        assertStrictUnstubbedResolution(
            member: "name(id:)",
            arguments: ["user-42"],
            returnType: String.self,
            expected: "",
            expectedArgument: #""user-42""#
        )
    }

    func testStrictUnstubbedIntReturnsDefaultAndReportsFailure() {
        assertStrictUnstubbedResolution(
            member: "attempts(for:)",
            arguments: ["sync"],
            returnType: Int.self,
            expected: 0,
            expectedArgument: #""sync""#
        )
    }

    func testStrictUnstubbedOptionalReturnsDefaultAndReportsFailure() {
        assertStrictUnstubbedResolution(
            member: "cachedName(id:)",
            arguments: [7],
            returnType: String?.self,
            expected: nil,
            expectedArgument: "7"
        )
    }

    func testStrictUnstubbedRegisteredDomainValueReturnsDefaultAndReportsFailure() {
        let defaultValue = RuntimeResolutionDomainValue(value: "registered")
        MockSynDefaultValueRegistry.register(defaultValue, for: RuntimeResolutionDomainValue.self)
        defer { MockSynDefaultValueRegistry.reset() }

        assertStrictUnstubbedResolution(
            member: "profile(id:)",
            arguments: [42],
            returnType: RuntimeResolutionDomainValue.self,
            expected: defaultValue,
            expectedArgument: "42"
        )
    }

    func testStrictUnstubbedDomainValueFatalErrorHarness() {
        guard ProcessInfo.processInfo.environment["MOCKSYN_CRASH_CASE"] == "strict-unconfigured-domain" else {
            return
        }

        MockSynFailureReporter.setHandler { _ in
            FileHandle.standardError.write(Data("\(runtimeFailureMarker)\n".utf8))
        }

        let runtime = MockSynRuntime(kind: .mock, mode: .strict)
        let _: RuntimeResolutionDomainValue = runtime.resolve(
            member: "profile(id:)",
            arguments: [42],
            returnType: RuntimeResolutionDomainValue.self
        )
    }

    func testStrictUnstubbedDomainWithoutRegisteredDefaultHasActionableFatalError() throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
        process.arguments = [
            "xctest",
            "-XCTest",
            "MockSynTests.MockSynPublicAPITests/testStrictUnstubbedDomainValueFatalErrorHarness",
            Bundle(for: Self.self).bundlePath,
        ]
        process.environment = ProcessInfo.processInfo.environment.merging([
            "MOCKSYN_CRASH_CASE": "strict-unconfigured-domain",
        ]) { _, new in new }
        process.standardOutput = Pipe()
        let standardError = Pipe()
        process.standardError = standardError

        try process.run()
        process.waitUntilExit()

        let errorOutput = String(
            decoding: standardError.fileHandleForReading.readDataToEndOfFile(),
            as: UTF8.self
        )
        let markerCount = errorOutput.components(separatedBy: runtimeFailureMarker).count - 1
        XCTAssertNotEqual(process.terminationStatus, 0)
        XCTAssertTrue(errorOutput.contains("willReturn"), errorOutput)
        XCTAssertTrue(errorOutput.contains("MockSynDefaultValueRegistry.register"), errorOutput)
        XCTAssertEqual(markerCount, 1, errorOutput)
    }

    func testRelaxedUnstubbedDomainValueReporterHarness() {
        guard ProcessInfo.processInfo.environment["MOCKSYN_CRASH_CASE"] == "relaxed-unconfigured-domain" else {
            return
        }

        MockSynFailureReporter.setHandler { _ in
            FileHandle.standardError.write(Data("\(runtimeFailureMarker)\n".utf8))
        }

        let runtime = MockSynRuntime(kind: .mock, mode: .relaxed)
        let _: RuntimeResolutionDomainValue = runtime.resolve(
            member: "profile(id:)",
            arguments: [42],
            returnType: RuntimeResolutionDomainValue.self
        )
    }

    func testRelaxedUnstubbedDomainReportsExactlyOnceBeforeFatalError() throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
        process.arguments = [
            "xctest",
            "-XCTest",
            "MockSynTests.MockSynPublicAPITests/testRelaxedUnstubbedDomainValueReporterHarness",
            Bundle(for: Self.self).bundlePath,
        ]
        process.environment = ProcessInfo.processInfo.environment.merging([
            "MOCKSYN_CRASH_CASE": "relaxed-unconfigured-domain",
        ]) { _, new in new }
        process.standardOutput = Pipe()
        let standardError = Pipe()
        process.standardError = standardError

        try process.run()
        process.waitUntilExit()

        let errorOutput = String(
            decoding: standardError.fileHandleForReading.readDataToEndOfFile(),
            as: UTF8.self
        )
        let markerCount = errorOutput.components(separatedBy: runtimeFailureMarker).count - 1

        XCTAssertNotEqual(process.terminationStatus, 0)
        XCTAssertEqual(markerCount, 1, errorOutput)
    }

    private func assertStrictUnstubbedResolution<Return: Equatable>(
        member: String,
        arguments: [Any],
        returnType: Return.Type,
        expected: Return,
        expectedArgument: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let recorder = FailureRecorder()
        let runtime = MockSynRuntime(kind: .mock, mode: .strict)

        MockSynFailureReporter.setHandler { failure in
            recorder.record(failure)
        }
        defer { MockSynFailureReporter.reset() }

        let value = runtime.resolve(member: member, arguments: arguments, returnType: returnType)

        XCTAssertEqual(value, expected, file: file, line: line)
        XCTAssertEqual(recorder.failures.count, 1, file: file, line: line)
        XCTAssertTrue(recorder.failures[0].message.contains(member), file: file, line: line)
        XCTAssertTrue(recorder.failures[0].message.contains(expectedArgument), file: file, line: line)
    }
}
