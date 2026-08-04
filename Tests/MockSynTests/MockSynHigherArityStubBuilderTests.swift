import MockSyn
import XCTest

@Mocking
protocol StubBuilderCapabilityService {
    var title: String { get set }
    var readOnlyTitle: String { get }
    var throwingTitle: String { get throws }

    subscript(index: Int) -> String { get set }
    subscript(readOnly index: Bool) -> String { get }
    subscript(throwing index: String) -> String { get throws }

    func doubled(_ value: Int) -> Int
    func loaded(_ value: Int) throws -> Int
    func transformed(_ operation: @escaping () throws -> Int) rethrows -> Int

    func many(_ a: Int, _ b: Int, _ c: Int, _ d: Int, _ e: Int, _ f: Int, _ g: Int) -> Int
    func throwingMany(_ a: Int, _ b: Int, _ c: Int, _ d: Int, _ e: Int, _ f: Int, _ g: Int) throws -> Int
    func rethrowingMany(
        _ operation: @escaping () throws -> Int,
        _ b: Int,
        _ c: Int,
        _ d: Int,
        _ e: Int,
        _ f: Int,
        _ g: Int
    ) rethrows -> Int
}

final class MockSynHigherArityStubBuilderTests: XCTestCase {
    func testThrowingCapableBuildersRunTypedClosuresForAritiesThreeThroughSix() throws {
        let runtime = MockSynRuntime(kind: .mock, mode: .strict)

        MockSynStubBuilder3<Int, Int, Int, Int>(
            runtime: runtime,
            member: "three",
            matchers: intMatchers(count: 3)
        ).willRun { first, second, third in
            first + second + third
        }
        MockSynStubBuilder4<Int, Int, Int, Int, Int>(
            runtime: runtime,
            member: "four",
            matchers: intMatchers(count: 4)
        ).willRun { first, second, third, fourth in
            first + second + third + fourth
        }
        MockSynStubBuilder5<Int, Int, Int, Int, Int, Int>(
            runtime: runtime,
            member: "five",
            matchers: intMatchers(count: 5)
        ).willRun { first, second, third, fourth, fifth in
            first + second + third + fourth + fifth
        }
        MockSynStubBuilder6<Int, Int, Int, Int, Int, Int, Int>(
            runtime: runtime,
            member: "six",
            matchers: intMatchers(count: 6)
        ).willRun { first, second, third, fourth, fifth, sixth in
            first + second + third + fourth + fifth + sixth
        }
        MockSynStubBuilder3<Int, Int, Int, Int>(
            runtime: runtime,
            member: "throwingThree",
            matchers: intMatchers(count: 3)
        ).willRun { _, _, _ in
            throw RuntimeStubError.failed
        }

        XCTAssertEqual(try runtime.resolveThrowing(member: "three", arguments: [1, 2, 3], returnType: Int.self), 6)
        XCTAssertEqual(try runtime.resolveThrowing(member: "four", arguments: [1, 2, 3, 4], returnType: Int.self), 10)
        XCTAssertEqual(try runtime.resolveThrowing(member: "five", arguments: [1, 2, 3, 4, 5], returnType: Int.self), 15)
        XCTAssertEqual(try runtime.resolveThrowing(member: "six", arguments: [1, 2, 3, 4, 5, 6], returnType: Int.self), 21)
        XCTAssertThrowsError(
            try runtime.resolveThrowing(member: "throwingThree", arguments: [1, 2, 3], returnType: Int.self)
        ) { error in
            XCTAssertEqual(error as? RuntimeStubError, .failed)
        }
    }

    func testRethrowingBuildersRunTypedNonThrowingClosuresForAritiesThreeThroughSix() {
        let runtime = MockSynRuntime(kind: .mock, mode: .strict)

        MockSynRethrowingStubBuilder3<Int, Int, Int, Int>(
            runtime: runtime,
            member: "three",
            matchers: intMatchers(count: 3)
        ).willRun { first, second, third in
            first + second + third
        }
        MockSynRethrowingStubBuilder4<Int, Int, Int, Int, Int>(
            runtime: runtime,
            member: "four",
            matchers: intMatchers(count: 4)
        ).willRun { first, second, third, fourth in
            first + second + third + fourth
        }
        MockSynRethrowingStubBuilder5<Int, Int, Int, Int, Int, Int>(
            runtime: runtime,
            member: "five",
            matchers: intMatchers(count: 5)
        ).willRun { first, second, third, fourth, fifth in
            first + second + third + fourth + fifth
        }
        MockSynRethrowingStubBuilder6<Int, Int, Int, Int, Int, Int, Int>(
            runtime: runtime,
            member: "six",
            matchers: intMatchers(count: 6)
        ).willRun { first, second, third, fourth, fifth, sixth in
            first + second + third + fourth + fifth + sixth
        }

        XCTAssertEqual(runtime.resolve(member: "three", arguments: [1, 2, 3], returnType: Int.self), 6)
        XCTAssertEqual(runtime.resolve(member: "four", arguments: [1, 2, 3, 4], returnType: Int.self), 10)
        XCTAssertEqual(runtime.resolve(member: "five", arguments: [1, 2, 3, 4, 5], returnType: Int.self), 15)
        XCTAssertEqual(runtime.resolve(member: "six", arguments: [1, 2, 3, 4, 5, 6], returnType: Int.self), 21)
    }

    func testGeneratedBuildersMatchMemberCapabilities() {
        let mock = StubBuilderCapabilityServiceMock()

        let nonThrowing: MockSynNonThrowingStubBuilder1<Int, Int> = mock.given.doubled(.any)
        let throwing: MockSynStubBuilder1<Int, Int> = mock.given.loaded(.any)
        let rethrowing: MockSynRethrowingStubBuilder1<() throws -> Int, Int> = mock.given.transformed(.any)
        let property: MockSynNonThrowingPropertyStubber<String> = mock.given.title
        let readOnlyProperty: MockSynNonThrowingReadOnlyPropertyStubber<String> = mock.given.readOnlyTitle
        let throwingProperty: MockSynPropertyStubber<String> = mock.given.throwingTitle
        let subscriptBuilder: MockSynNonThrowingSubscriptStubber<String> = mock.given.subscript(index: .any)
        let readOnlySubscript: MockSynNonThrowingReadOnlySubscriptStubber<String> = mock.given.subscript(readOnly: .any)
        let throwingSubscript: MockSynSubscriptStubber<String> = mock.given.subscript(throwing: .any)
        let readOnlyPropertyVerification: MockSynReadOnlyPropertyVerification<String> = mock.verify.readOnlyTitle
        let throwingPropertyVerification: MockSynReadOnlyPropertyVerification<String> = mock.verify.throwingTitle
        let readOnlySubscriptVerification: MockSynReadOnlySubscriptVerification<String> = mock.verify.subscript(readOnly: .any)
        let throwingSubscriptVerification: MockSynReadOnlySubscriptVerification<String> = mock.verify.subscript(throwing: .any)
        let propertySetter: MockSynNonThrowingStubBuilder1<String, Void> = property.set(.any)
        let subscriptSetter: MockSynNonThrowingSubscriptSetterStubBuilder<String> = subscriptBuilder.set(.any)

        nonThrowing.willRun { $0 * 2 }
        throwing.willThrow(RuntimeStubError.failed)
        rethrowing.willRun { operation in (try? operation()) ?? 0 }
        property.get.willReturn("stubbed")
        propertySetter.willRun { _ in }
        readOnlyProperty.get.willReturn("read-only")
        throwingProperty.get.willThrow(RuntimeStubError.failed)
        subscriptBuilder.get.willReturn("stubbed")
        subscriptSetter.willRun { _ in }
        readOnlySubscript.get.willReturn("read-only")
        throwingSubscript.get.willThrow(RuntimeStubError.failed)
        _ = readOnlyPropertyVerification.get
        _ = throwingPropertyVerification.get
        _ = readOnlySubscriptVerification.get
        _ = throwingSubscriptVerification.get

        XCTAssertEqual(mock.doubled(4), 8)
    }

    func testGeneratedMethodsAboveSixParametersUseReturnOnlyBuilders() throws {
        let mock = StubBuilderCapabilityServiceMock()

        let nonThrowing: MockSynNonThrowingStubBuilderReturnOnly<Int> = mock.given.many(.any, .any, .any, .any, .any, .any, .any)
        let throwingReturn: MockSynStubBuilderReturnOnly<Int> = mock.given.throwingMany(.any, .any, .any, .any, .any, .any, .any)
        let rethrowing: MockSynRethrowingStubBuilderReturnOnly<Int> = mock.given.rethrowingMany(.any, .any, .any, .any, .any, .any, .any)

        nonThrowing.willReturn(7)
        throwingReturn.willReturn(8)
        rethrowing.willReturn(9)

        XCTAssertEqual(mock.many(1, 2, 3, 4, 5, 6, 7), 7)
        XCTAssertEqual(try mock.throwingMany(1, 2, 3, 4, 5, 6, 7), 8)
        XCTAssertEqual(mock.rethrowingMany({ 1 }, 2, 3, 4, 5, 6, 7), 9)

        let throwingMock = StubBuilderCapabilityServiceMock()
        let throwing: MockSynStubBuilderReturnOnly<Int> = throwingMock.given.throwingMany(.any, .any, .any, .any, .any, .any, .any)
        throwing.willThrow(RuntimeStubError.failed)
        XCTAssertThrowsError(try throwingMock.throwingMany(1, 2, 3, 4, 5, 6, 7))
    }

    private func intMatchers(count: Int) -> [MockSynAnyMatcher] {
        (0..<count).map { _ in MockSynMatcher<Int>.any.erase() }
    }
}
