import Foundation

final class MockSynInvocation: @unchecked Sendable {
    let member: String
    let arguments: [Any]
    let sequence: UInt64
    var isVerified = false

    init(member: String, arguments: [Any], sequence: UInt64) {
        self.member = member
        self.arguments = arguments
        self.sequence = sequence
    }
}

enum MockSynInvocationClock {
    private static let lock = NSRecursiveLock()
    private static var current: UInt64 = 0

    static func next() -> UInt64 {
        lock.lock()
        defer { lock.unlock() }

        current += 1
        return current
    }
}
