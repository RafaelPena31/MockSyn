import MockSyn
import Foundation
import XCTest

extension MockSynPublicAPITests {
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

    func testStrictUnstubbedNonThrowingResolutionReportsReceivedCallOnce() {
        let recorder = FailureRecorder()
        let runtime = MockSynRuntime(kind: .mock, mode: .strict)

        MockSynFailureReporter.setHandler { failure in
            recorder.record(failure)
        }
        defer { MockSynFailureReporter.reset() }

        let value = runtime.resolve(
            member: "lookup(id:)",
            arguments: ["missing-user"],
            returnType: String.self
        )

        XCTAssertEqual(value, "")
        XCTAssertEqual(recorder.failures.count, 1)
        XCTAssertTrue(recorder.failures[0].message.contains("lookup(id:)"))
        XCTAssertTrue(recorder.failures[0].message.contains(#""missing-user""#))
    }

    func testNonThrowingResolutionForwardsCallerFileAndLine() {
        let recorder = FailureRecorder()
        let runtime = MockSynRuntime(kind: .mock, mode: .strict)

        MockSynFailureReporter.setHandler { failure in
            recorder.record(failure)
        }
        defer { MockSynFailureReporter.reset() }

        let value = runtime.resolve(
            member: "lookup(id:)",
            arguments: ["missing-user"],
            returnType: String.self,
            file: "CallerResolution.swift",
            line: 314
        )

        XCTAssertEqual(value, "")
        XCTAssertEqual(recorder.failures.count, 1)
        XCTAssertEqual(recorder.failures[0].file.description, "CallerResolution.swift")
        XCTAssertEqual(recorder.failures[0].line, 314)
    }

    func testRelaxedUnstubbedNonThrowingResolutionDoesNotReport() {
        let recorder = FailureRecorder()
        let runtime = MockSynRuntime(kind: .mock, mode: .relaxed)

        MockSynFailureReporter.setHandler { failure in
            recorder.record(failure)
        }
        defer { MockSynFailureReporter.reset() }

        let value = runtime.resolve(member: "lookup(id:)", arguments: ["missing"], returnType: String.self)

        XCTAssertEqual(value, "")
        XCTAssertTrue(recorder.failures.isEmpty)
    }

    func testStrictUnstubbedVoidResolutionDoesNotReport() {
        let recorder = FailureRecorder()
        let runtime = MockSynRuntime(kind: .mock, mode: .strict)

        MockSynFailureReporter.setHandler { failure in
            recorder.record(failure)
        }
        defer { MockSynFailureReporter.reset() }

        runtime.resolveVoid(
            member: "refresh()",
            arguments: [],
            file: "VoidCaller.swift",
            line: 315
        )

        XCTAssertTrue(recorder.failures.isEmpty)
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

        var thrownDescription: String?
        XCTAssertThrowsError(
            try MockSynVerification(
                runtime: runtime,
                member: "save(_:)",
                matchers: [MockSynMatcher<String>.value("expected").erase()]
            ).once(file: "ForwardedFile.swift", line: 123)
        ) { error in
            thrownDescription = String(describing: error)
        }

        XCTAssertEqual(recorder.failures.last.map { "\($0.file)" }, "ForwardedFile.swift")
        XCTAssertEqual(recorder.failures.last?.line, 123)
        XCTAssertEqual(recorder.failures.last?.message, thrownDescription)
        XCTAssertEqual(
            recorder.failures.last?.message.components(separatedBy: "Recorded calls:").count,
            2
        )
        XCTAssertTrue(thrownDescription?.contains(#"save(_:)("received")"#) == true)
    }
}
