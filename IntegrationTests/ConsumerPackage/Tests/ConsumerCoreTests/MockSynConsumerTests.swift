import ConsumerCore
import ExternalContracts
import Foundation
import MockSyn
import XCTest

final class ConsumerFailureRecorder: @unchecked Sendable {
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

    func reset() {
        lock.lock()
        defer { lock.unlock() }
        storedFailures.removeAll()
    }
}

final class MockSynConsumerTests: XCTestCase {
    override func setUp() {
        super.setUp()
        MockSynRuntime.resetAllGlobalState()
    }

    override func tearDown() {
        MockSynRuntime.resetAllGlobalState()
        super.tearDown()
    }

    func testPublicGeneratedMockIsUsableAcrossModuleBoundary() throws {
        let mock = PublicUserLoadingMock()
        mock.given.loadUser(id: .value("public-user")).willReturn("Rafael")

        XCTAssertEqual(mock.loadUser(id: "public-user"), "Rafael")
        try mock.verify.loadUser(id: .value("public-user")).once()
    }

    func testStrictNonThrowingCallRecoversAndReportsReceivedArgument() {
        let recorder = ConsumerFailureRecorder()
        MockSynFailureReporter.setHandler { failure in
            recorder.record(failure)
        }

        let value = PublicUserLoadingMock().loadUser(id: "missing-user")

        XCTAssertEqual(value, "")
        XCTAssertEqual(recorder.failures.count, 1)
        XCTAssertTrue(recorder.failures[0].message.contains("loadUser(id:)"))
        XCTAssertTrue(recorder.failures[0].message.contains(#""missing-user""#))
    }

    func testVerificationErrorAndReporterShareRichRecordedCalls() {
        let recorder = ConsumerFailureRecorder()
        MockSynFailureReporter.setHandler { failure in
            recorder.record(failure)
        }
        let mock = PublicUserLoadingMock()
        mock.given.loadUser(id: .any).willReturn("found")
        _ = mock.loadUser(id: "received-user")

        XCTAssertThrowsError(try mock.verify.loadUser(id: .value("expected-user")).once()) { error in
            guard let verificationError = error as? MockSynVerificationError else {
                return XCTFail("Expected MockSynVerificationError, received \(error)")
            }

            let description = verificationError.description
            XCTAssertTrue(description.contains("Recorded calls:"))
            XCTAssertTrue(description.contains(#""received-user""#))
            XCTAssertEqual(recorder.failures.last?.message, description)
        }
    }

    func testGlobalResetClearsGeneratedStaticRuntime() throws {
        PublicBuildInformationMock.given.revision().willReturn(42)
        XCTAssertEqual(PublicBuildInformationMock.revision(), 42)
        try PublicBuildInformationMock.verify.revision().once()

        MockSynRuntime.resetAllGlobalState()

        try PublicBuildInformationMock.verify.revision().never()
        let recorder = ConsumerFailureRecorder()
        MockSynFailureReporter.setHandler { failure in
            recorder.record(failure)
        }
        XCTAssertEqual(PublicBuildInformationMock.revision(), 0)
        XCTAssertEqual(recorder.failures.count, 1)
    }

    func testMirroredMockConformsToCompiledExternalProtocol() throws {
        let mock = MirroredExternalUserLoadingMock()
        mock.given.loadUser(id: .any).willReturn("external-user")

        let externalService: any ExternalUserLoading = mock

        XCTAssertEqual(externalService.loadUser(id: "external-id"), "external-user")
        try mock.verify.loadUser(id: .value("external-id")).once()
    }
}
