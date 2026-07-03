import MockSyn
import XCTest

@Mocking(access: .fileprivate)
fileprivate protocol MockSynPerformanceSingleMethod {
    func load(id: String) -> String
}

@Mocking(access: .fileprivate)
fileprivate protocol MockSynPerformanceTwentyMethods {
    func method1() -> Int
    func method2() -> Int
    func method3() -> Int
    func method4() -> Int
    func method5() -> Int
    func method6() -> Int
    func method7() -> Int
    func method8() -> Int
    func method9() -> Int
    func method10() -> Int
    func method11() -> Int
    func method12() -> Int
    func method13() -> Int
    func method14() -> Int
    func method15() -> Int
    func method16() -> Int
    func method17() -> Int
    func method18() -> Int
    func method19() -> Int
    func method20() -> Int
}

@Mocking(access: .fileprivate)
fileprivate protocol MockSynPerformanceAsyncThrowing {
    func fetch() async throws -> String
}

@Mocking(access: .fileprivate)
fileprivate protocol MockSynPerformanceProperties {
    var name: String { get set }
    var count: Int { get }
}

@Mocking(access: .fileprivate)
fileprivate protocol MockSynPerformanceGeneric {
    func map<Value>(_ value: Value) -> Value
}

final class MockSynPerformanceTests: XCTestCase {
    func testMockSynPerformanceGeneratedStubbedCalls() throws {
        try skipUnlessBenchmarksEnabled()
        let mock = MockSynPerformanceSingleMethodMock()
        mock.given.load(id: .value("user")).willReturn("Rafael")

        measure {
            for _ in 0..<1_000 {
                _ = mock.load(id: "user")
            }
        }
    }

    func testMockSynPerformanceRuntimeRecording() throws {
        try skipUnlessBenchmarksEnabled()
        let runtime = MockSynRuntime(kind: .mock, mode: .relaxed)

        measure {
            for index in 0..<1_000 {
                runtime.resolveVoid(member: "record(_:)", arguments: [index])
            }
        }
    }

    func testMockSynPerformanceVerification() throws {
        try skipUnlessBenchmarksEnabled()
        let runtime = MockSynRuntime(kind: .mock, mode: .relaxed)

        for index in 0..<1_000 {
            runtime.resolveVoid(member: "record(_:)", arguments: [index])
        }

        measure {
            try! MockSynVerification(
                runtime: runtime,
                member: "record(_:)",
                matchers: [MockSynMatcher<Int>.any.erase()]
            ).times(1_000)
        }
    }

    func testMockSynPerformanceGeneratedFixtureSmoke() throws {
        try skipUnlessBenchmarksEnabled()
        let twenty = MockSynPerformanceTwentyMethodsMock(mode: .relaxed)
        let properties = MockSynPerformancePropertiesMock(mode: .relaxed)
        let generic = MockSynPerformanceGenericMock(mode: .relaxed)
        let asyncThrowing = MockSynPerformanceAsyncThrowingMock(mode: .relaxed)

        measure {
            _ = twenty.method1()
            _ = twenty.method20()
            properties.name = "updated"
            _ = properties.count
            _ = generic.map("value")
            _ = asyncThrowing
        }
    }

    private func skipUnlessBenchmarksEnabled() throws {
        try XCTSkipUnless(
            ProcessInfo.processInfo.environment["MOCKSYN_RUN_BENCHMARKS"] == "1",
            "Set MOCKSYN_RUN_BENCHMARKS=1 or run tools/benchmark.sh --run."
        )
    }
}
