import Foundation

final class MockSynInvocation: @unchecked Sendable {
    let member: String
    let arguments: [Any]
    let sequence: MockSynInvocationSequence
    var isVerified = false

    init(member: String, arguments: [Any], sequence: MockSynInvocationSequence) {
        self.member = member
        self.arguments = arguments
        self.sequence = sequence
    }
}

struct MockSynInvocationSequence: Comparable, Sendable {
    let epoch: UInt64
    let ordinal: UInt64

    static func < (lhs: MockSynInvocationSequence, rhs: MockSynInvocationSequence) -> Bool {
        if lhs.epoch != rhs.epoch {
            return lhs.epoch < rhs.epoch
        }

        return lhs.ordinal < rhs.ordinal
    }
}

enum MockSynInvocationClock {
    private static let lock = NSRecursiveLock()
    #if compiler(>=6.0)
    private nonisolated(unsafe) static var epoch: UInt64 = 0
    private nonisolated(unsafe) static var ordinal: UInt64 = 0
    #else
    private static var epoch: UInt64 = 0
    private static var ordinal: UInt64 = 0
    #endif

    static func next() -> MockSynInvocationSequence {
        lock.lock()
        defer { lock.unlock() }

        ordinal += 1
        return MockSynInvocationSequence(epoch: epoch, ordinal: ordinal)
    }

    static func reset() {
        lock.lock()
        defer { lock.unlock() }

        epoch += 1
        ordinal = 0
    }
}
