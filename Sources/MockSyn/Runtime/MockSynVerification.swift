import Foundation

/// Expected number of invocations for a verification.
public enum MockSynVerificationCount: Equatable {
    case once
    case never
    case times(Int)
    case atLeast(Int)
    case atMost(Int)

    func matches(_ actual: Int) -> Bool {
        switch self {
        case .once:
            return actual == 1
        case .never:
            return actual == 0
        case .times(let expected):
            return actual == expected
        case .atLeast(let minimum):
            return actual >= minimum
        case .atMost(let maximum):
            return actual <= maximum
        }
    }

    var description: String {
        switch self {
        case .once:
            return "exactly 1 time"
        case .never:
            return "0 times"
        case .times(let expected):
            return "exactly \(expected) \(Self.timeLabel(for: expected))"
        case .atLeast(let minimum):
            return "at least \(minimum) \(Self.timeLabel(for: minimum))"
        case .atMost(let maximum):
            return "at most \(maximum) \(Self.timeLabel(for: maximum))"
        }
    }

    private static func timeLabel(for count: Int) -> String {
        count == 1 ? "time" : "times"
    }
}

/// Errors produced by MockSyn verification APIs.
public enum MockSynVerificationError: Error, CustomStringConvertible {
    case expected(member: String, count: MockSynVerificationCount, actual: Int)
    case unverifiedInvocations([String])
    case unnecessaryStubs([String])
    case order([String])

    public var description: String {
        switch self {
        case .expected(let member, let count, let actual):
            return "Expected \(member) to be called \(count.description), but it was called \(actual) \(Self.timeLabel(for: actual))"
        case .unverifiedInvocations(let members):
            return "Unverified MockSyn invocations: \(members.joined(separator: ", "))"
        case .unnecessaryStubs(let members):
            return "Unnecessary MockSyn stubs: \(members.joined(separator: ", "))"
        case .order(let members):
            return "Expected calls to happen in order: \(members.joined(separator: " -> "))"
        }
    }

    private static func timeLabel(for count: Int) -> String {
        count == 1 ? "time" : "times"
    }
}

/// Verification query returned by generated `verify` APIs.
public struct MockSynVerification {
    private let runtime: MockSynRuntime
    private let member: String
    private let matchers: [MockSynAnyMatcher]

    public init(runtime: MockSynRuntime, member: String, matchers: [MockSynAnyMatcher]) {
        self.runtime = runtime
        self.member = member
        self.matchers = matchers
    }

    /// Verifies the call count for this member.
    public func wasCalled(_ count: MockSynVerificationCount = .atLeast(1)) throws {
        try runtime.verify(member: member, matchers: matchers, count: count)
    }

    /// Waits until the call count matches, or fails after the timeout expires.
    public func wasCalled(
        _ count: MockSynVerificationCount = .atLeast(1),
        timeout: TimeInterval,
        pollInterval: TimeInterval = 0.01
    ) async throws {
        let deadline = Date().addingTimeInterval(timeout)

        while Date() < deadline {
            if count.matches(runtime.invocationCount(member: member, matchers: matchers)) {
                try wasCalled(count)
                return
            }

            try await Task.sleep(nanoseconds: UInt64(max(pollInterval, 0.001) * 1_000_000_000))
        }

        try wasCalled(count)
    }

    /// Verifies the member was called once.
    public func once() throws {
        try wasCalled(.once)
    }

    /// Verifies the member was never called.
    public func never() throws {
        try wasCalled(.never)
    }

    /// Verifies the member was called an exact number of times.
    public func times(_ count: Int) throws {
        try wasCalled(.times(count))
    }

    /// Verifies the member was called at least the given number of times.
    public func atLeast(_ count: Int) throws {
        try wasCalled(.atLeast(count))
    }

    /// Verifies the member was called at most the given number of times.
    public func atMost(_ count: Int) throws {
        try wasCalled(.atMost(count))
    }

    func firstInvocationSequence() throws -> UInt64 {
        try runtime.firstInvocationSequence(member: member, matchers: matchers)
    }

    var memberName: String {
        member
    }
}

/// Verification entrypoint for generated property APIs.
public struct MockSynPropertyVerification<Value> {
    private let runtime: MockSynRuntime
    private let getMember: String
    private let setMember: String

    public init(runtime: MockSynRuntime, getMember: String, setMember: String) {
        self.runtime = runtime
        self.getMember = getMember
        self.setMember = setMember
    }

    /// Verifies property getter calls.
    public var get: MockSynVerification {
        MockSynVerification(runtime: runtime, member: getMember, matchers: [])
    }

    /// Verifies property setter calls for a matching assigned value.
    public func set(_ matcher: MockSynMatcher<Value>) -> MockSynVerification {
        MockSynVerification(runtime: runtime, member: setMember, matchers: [matcher.erase()])
    }
}

/// Verification entrypoint for generated subscript APIs.
public struct MockSynSubscriptVerification<Value> {
    private let runtime: MockSynRuntime
    private let getMember: String
    private let setMember: String
    private let indexMatchers: [MockSynAnyMatcher]

    public init(
        runtime: MockSynRuntime,
        getMember: String,
        setMember: String,
        indexMatchers: [MockSynAnyMatcher]
    ) {
        self.runtime = runtime
        self.getMember = getMember
        self.setMember = setMember
        self.indexMatchers = indexMatchers
    }

    /// Verifies subscript getter calls for matching indexes.
    public var get: MockSynVerification {
        MockSynVerification(runtime: runtime, member: getMember, matchers: indexMatchers)
    }

    /// Verifies subscript setter calls for matching indexes and assigned value.
    public func set(_ matcher: MockSynMatcher<Value>) -> MockSynVerification {
        MockSynVerification(runtime: runtime, member: setMember, matchers: indexMatchers + [matcher.erase()])
    }
}

/// Cross-mock verification helpers.
public enum MockSynVerifier {
    /// Verifies that the first matching invocation for each query happened in the provided order.
    public static func verifyOrder(_ verifications: MockSynVerification...) throws {
        try verifyOrder(verifications)
    }

    /// Verifies that the first matching invocation for each query happened in the provided order.
    public static func verifyOrder(_ verifications: [MockSynVerification]) throws {
        var previousSequence: UInt64 = 0
        var members: [String] = []

        for verification in verifications {
            let sequence = try verification.firstInvocationSequence()
            members.append(verification.memberName)

            guard sequence > previousSequence else {
                let error = MockSynVerificationError.order(members)
                MockSynFailureReporter.report(error)
                throw error
            }

            previousSequence = sequence
        }
    }
}
