import MockSyn
import Foundation
import XCTest
#if canImport(ObjectiveC)
import ObjectiveC.runtime
#endif

enum RuntimeStubError: Error, Equatable {
    case failed
}

struct ConstructedUser: Equatable {
    let id: String
    let name: String
}

struct RichRenderedUser: CustomDebugStringConvertible {
    let id: String

    var debugDescription: String {
        "RichRenderedUser(id: \"\(id)\")"
    }
}

final class ManualFakeService: MockSynFake {
    let __mockSyn = MockSynRuntime(kind: .fake, mode: .relaxed)

    func load(id: String) -> String {
        mockSynRecord(member: "load(id:)", arguments: [id])
        return "fake-\(id)"
    }

    func verifyLoad(id matcher: MockSynMatcher<String>) -> MockSynVerification {
        mockSynVerification(member: "load(id:)", matchers: [matcher.erase()])
    }
}

final class FailureRecorder: @unchecked Sendable {
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
}

final class AdapterFailureRecorder: @unchecked Sendable {
    private let lock = NSRecursiveLock()
    private var storedFailure: (message: String, file: String, line: UInt)?

    var failure: (message: String, file: String, line: UInt)? {
        lock.lock()
        defer { lock.unlock() }

        return storedFailure
    }

    func record(message: String, file: String, line: UInt) {
        lock.lock()
        defer { lock.unlock() }

        storedFailure = (message, file, line)
    }
}

#if canImport(ObjectiveC)
@objcMembers
final class ObjCLegacyService: NSObject {
    dynamic func greeting() -> NSString {
        "real"
    }

    dynamic class func build() -> NSString {
        "real-class"
    }
}
#endif

final class MockSynPublicAPITests: XCTestCase {
}
