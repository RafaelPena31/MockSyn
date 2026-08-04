import MockSyn
import Foundation
import XCTest

extension MockSynPublicAPITests {
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
                """
                Expected refresh() to be called exactly 1 time, but it was called 2 times
                Recorded calls:
                - refresh()()
                - refresh()()
                """
            )
        }
    }

    func testVerificationThrownErrorIncludesRenderedRecordedCalls() {
        let runtime = MockSynRuntime(kind: .mock, mode: .strict)
        runtime.resolveVoid(member: "save(_:)", arguments: ["received"])

        XCTAssertThrowsError(
            try MockSynVerification(
                runtime: runtime,
                member: "save(_:)",
                matchers: [MockSynMatcher<String>.value("expected").erase()]
            ).once()
        ) { error in
            XCTAssertEqual(
                String(describing: error),
                """
                Expected save(_:) to be called exactly 1 time, but it was called 0 times
                Recorded calls:
                - save(_:)("received")
                """
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

    func testOrderedVerificationIncludesRenderedCallsWhenArgumentsDoNotMatch() {
        let recorder = FailureRecorder()
        let runtime = MockSynRuntime(kind: .mock, mode: .strict)
        MockSynFailureReporter.setHandler { failure in
            recorder.record(failure)
        }
        defer { MockSynFailureReporter.reset() }

        runtime.resolveVoid(member: "save(_:)", arguments: ["received"])

        var thrownDescription: String?
        XCTAssertThrowsError(
            try MockSynVerifier.verifyOrder(
                MockSynVerification(
                    runtime: runtime,
                    member: "save(_:)",
                    matchers: [MockSynMatcher<String>.value("expected").erase()]
                )
            )
        ) { error in
            thrownDescription = String(describing: error)
            XCTAssertEqual(
                thrownDescription,
                """
                Expected save(_:) to be called at least 1 time, but it was called 0 times
                Recorded calls:
                - save(_:)("received")
                """
            )
        }

        XCTAssertEqual(recorder.failures.last?.message, thrownDescription)
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
}
