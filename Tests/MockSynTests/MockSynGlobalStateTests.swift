import Foundation
import MockSyn
import XCTest

private struct GlobalResetDefault: Equatable {
    let value: String
}

final class MockSynGlobalStateTests: XCTestCase {
    override func setUp() {
        super.setUp()
        MockSynRuntime.resetAllGlobalState()
    }

    override func tearDown() {
        MockSynRuntime.resetAllGlobalState()
        super.tearDown()
    }

    func testResetAllGlobalStateClearsStaticRuntimesDefaultsReporterAndClock() throws {
        #if MOCKSYN_ENABLE
        let recorder = FailureRecorder()
        let instanceRuntime = MockSynRuntime(kind: .mock, mode: .strict)

        StaticFactoryServiceMock.given.make(id: .any).willReturn("factory")
        StaticThrowingServiceMock.given.fetch().willReturn("throwing")
        MockSynStubBuilder<String>(runtime: instanceRuntime, member: "instance()")
            .willReturn("instance")
        MockSynDefaultValueRegistry.register(
            GlobalResetDefault(value: "registered"),
            for: GlobalResetDefault.self
        )
        MockSynFailureReporter.setHandler { recorder.record($0) }

        instanceRuntime.resolveVoid(member: "beforeFirst()", arguments: [])
        instanceRuntime.resolveVoid(member: "beforeSecond()", arguments: [])
        XCTAssertEqual(StaticFactoryServiceMock.make(id: "id"), "factory")
        XCTAssertEqual(try StaticThrowingServiceMock.fetch(), "throwing")
        MockSynFailureReporter.report(MockSynFailure(message: "before reset"))

        MockSynRuntime.resetAllGlobalState()

        try StaticFactoryServiceMock.verify.make(id: .any).never()
        try StaticThrowingServiceMock.verify.fetch().never()
        XCTAssertNil(MockSynDefaultValueRegistry.value(for: GlobalResetDefault.self))

        MockSynFailureReporter.report(MockSynFailure(message: "after reset"))
        XCTAssertEqual(recorder.failures.map(\.message), ["before reset"])

        XCTAssertEqual(
            instanceRuntime.resolve(member: "instance()", arguments: [], returnType: String.self),
            "instance"
        )
        StaticFactoryServiceMock.ping()

        XCTAssertThrowsError(
            try MockSynVerifier.verifyOrder(
                MockSynVerification(runtime: instanceRuntime, member: "beforeSecond()", matchers: []),
                StaticFactoryServiceMock.verify.ping()
            )
        )

        XCTAssertEqual(StaticFactoryServiceMock.make(id: "id"), "")
        XCTAssertThrowsError(try StaticThrowingServiceMock.fetch())
        #else
        XCTFail("MOCKSYN_ENABLE must be active for generated test doubles")
        #endif
    }

    func testGlobalRuntimeRegistryDoesNotRetainReleasedRuntime() {
        weak var weakRuntime: MockSynRuntime?

        do {
            let runtime = MockSynRuntime.global(kind: .mock, mode: .strict)
            weakRuntime = runtime
            XCTAssertNotNil(weakRuntime)
        }

        XCTAssertNil(weakRuntime)
    }
}
