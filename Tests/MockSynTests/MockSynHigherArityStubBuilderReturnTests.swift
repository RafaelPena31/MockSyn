@testable import MockSyn
import XCTest

final class MockSynHigherArityStubBuilderReturnTests: XCTestCase {
    func testThrowingBuildersReturnSequentialValuesForAritiesThreeThroughSix() throws {
        let runtime = MockSynRuntime(kind: .mock, mode: .strict)

        MockSynStubBuilder3<Int, Int, Int, Int>(
            runtime: runtime,
            member: "three",
            matchers: intMatchers(count: 3)
        ).willReturn(3, 13)
        MockSynStubBuilder4<Int, Int, Int, Int, Int>(
            runtime: runtime,
            member: "four",
            matchers: intMatchers(count: 4)
        ).willReturn(4, 14)
        MockSynStubBuilder5<Int, Int, Int, Int, Int, Int>(
            runtime: runtime,
            member: "five",
            matchers: intMatchers(count: 5)
        ).willReturn(5, 15)
        MockSynStubBuilder6<Int, Int, Int, Int, Int, Int, Int>(
            runtime: runtime,
            member: "six",
            matchers: intMatchers(count: 6)
        ).willReturn(6, 16)

        XCTAssertEqual(try resolveThrowing(runtime, member: "three", arguments: [1, 2, 3]), 3)
        XCTAssertEqual(try resolveThrowing(runtime, member: "three", arguments: [1, 2, 3]), 13)
        XCTAssertEqual(try resolveThrowing(runtime, member: "four", arguments: [1, 2, 3, 4]), 4)
        XCTAssertEqual(try resolveThrowing(runtime, member: "four", arguments: [1, 2, 3, 4]), 14)
        XCTAssertEqual(try resolveThrowing(runtime, member: "five", arguments: [1, 2, 3, 4, 5]), 5)
        XCTAssertEqual(try resolveThrowing(runtime, member: "five", arguments: [1, 2, 3, 4, 5]), 15)
        XCTAssertEqual(try resolveThrowing(runtime, member: "six", arguments: [1, 2, 3, 4, 5, 6]), 6)
        XCTAssertEqual(try resolveThrowing(runtime, member: "six", arguments: [1, 2, 3, 4, 5, 6]), 16)
    }

    func testThrowingBuildersThrowForAritiesThreeThroughSix() {
        let runtime = MockSynRuntime(kind: .mock, mode: .strict)

        MockSynStubBuilder3<Int, Int, Int, Int>(
            runtime: runtime,
            member: "three",
            matchers: intMatchers(count: 3)
        ).willThrow(HigherArityReturnError.configured)
        MockSynStubBuilder4<Int, Int, Int, Int, Int>(
            runtime: runtime,
            member: "four",
            matchers: intMatchers(count: 4)
        ).willThrow(HigherArityReturnError.configured)
        MockSynStubBuilder5<Int, Int, Int, Int, Int, Int>(
            runtime: runtime,
            member: "five",
            matchers: intMatchers(count: 5)
        ).willThrow(HigherArityReturnError.configured)
        MockSynStubBuilder6<Int, Int, Int, Int, Int, Int, Int>(
            runtime: runtime,
            member: "six",
            matchers: intMatchers(count: 6)
        ).willThrow(HigherArityReturnError.configured)

        assertConfiguredError(runtime, member: "three", arguments: [1, 2, 3])
        assertConfiguredError(runtime, member: "four", arguments: [1, 2, 3, 4])
        assertConfiguredError(runtime, member: "five", arguments: [1, 2, 3, 4, 5])
        assertConfiguredError(runtime, member: "six", arguments: [1, 2, 3, 4, 5, 6])
    }

    func testNonThrowingBuildersReturnValuesForAritiesThreeThroughSix() {
        let runtime = MockSynRuntime(kind: .mock, mode: .strict)

        MockSynNonThrowingStubBuilder3<Int, Int, Int, Int>(
            runtime: runtime,
            member: "three",
            matchers: intMatchers(count: 3)
        ).willReturn(3)
        MockSynNonThrowingStubBuilder4<Int, Int, Int, Int, Int>(
            runtime: runtime,
            member: "four",
            matchers: intMatchers(count: 4)
        ).willReturn(4)
        MockSynNonThrowingStubBuilder5<Int, Int, Int, Int, Int, Int>(
            runtime: runtime,
            member: "five",
            matchers: intMatchers(count: 5)
        ).willReturn(5)
        MockSynNonThrowingStubBuilder6<Int, Int, Int, Int, Int, Int, Int>(
            runtime: runtime,
            member: "six",
            matchers: intMatchers(count: 6)
        ).willReturn(6)

        XCTAssertEqual(runtime.resolve(member: "three", arguments: [1, 2, 3], returnType: Int.self), 3)
        XCTAssertEqual(runtime.resolve(member: "four", arguments: [1, 2, 3, 4], returnType: Int.self), 4)
        XCTAssertEqual(runtime.resolve(member: "five", arguments: [1, 2, 3, 4, 5], returnType: Int.self), 5)
        XCTAssertEqual(runtime.resolve(member: "six", arguments: [1, 2, 3, 4, 5, 6], returnType: Int.self), 6)
    }

    func testNonThrowingTwoArgumentBuilderRunsTypedClosure() {
        let runtime = MockSynRuntime(kind: .mock, mode: .strict)
        MockSynNonThrowingStubBuilder2<Int, Int, Int>(
            runtime: runtime,
            member: "sum",
            matchers: intMatchers(count: 2)
        ).willRun(+)

        XCTAssertEqual(runtime.resolve(member: "sum", arguments: [4, 5], returnType: Int.self), 9)
    }

    func testRethrowingBuildersReturnValuesForAritiesThreeThroughSix() {
        let runtime = MockSynRuntime(kind: .mock, mode: .strict)

        MockSynRethrowingStubBuilder3<Int, Int, Int, Int>(
            runtime: runtime,
            member: "three",
            matchers: intMatchers(count: 3)
        ).willReturn(3)
        MockSynRethrowingStubBuilder4<Int, Int, Int, Int, Int>(
            runtime: runtime,
            member: "four",
            matchers: intMatchers(count: 4)
        ).willReturn(4)
        MockSynRethrowingStubBuilder5<Int, Int, Int, Int, Int, Int>(
            runtime: runtime,
            member: "five",
            matchers: intMatchers(count: 5)
        ).willReturn(5)
        MockSynRethrowingStubBuilder6<Int, Int, Int, Int, Int, Int, Int>(
            runtime: runtime,
            member: "six",
            matchers: intMatchers(count: 6)
        ).willReturn(6)

        XCTAssertEqual(runtime.resolve(member: "three", arguments: [1, 2, 3], returnType: Int.self), 3)
        XCTAssertEqual(runtime.resolve(member: "four", arguments: [1, 2, 3, 4], returnType: Int.self), 4)
        XCTAssertEqual(runtime.resolve(member: "five", arguments: [1, 2, 3, 4, 5], returnType: Int.self), 5)
        XCTAssertEqual(runtime.resolve(member: "six", arguments: [1, 2, 3, 4, 5, 6], returnType: Int.self), 6)
    }

    private func intMatchers(count: Int) -> [MockSynAnyMatcher] {
        (0..<count).map { _ in MockSynMatcher<Int>.any.erase() }
    }

    private func resolveThrowing(
        _ runtime: MockSynRuntime,
        member: String,
        arguments: [Any]
    ) throws -> Int {
        try runtime.resolveThrowing(member: member, arguments: arguments, returnType: Int.self)
    }

    private func assertConfiguredError(
        _ runtime: MockSynRuntime,
        member: String,
        arguments: [Any],
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertThrowsError(
            try resolveThrowing(runtime, member: member, arguments: arguments),
            file: file,
            line: line
        ) { error in
            XCTAssertEqual(error as? HigherArityReturnError, .configured, file: file, line: line)
        }
    }
}

private enum HigherArityReturnError: Error, Equatable {
    case configured
}
