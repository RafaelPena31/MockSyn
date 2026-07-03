import Foundation

/// Captures arguments matched during stubbing or verification.
public final class MockSynArgumentCaptor<Value>: @unchecked Sendable {
    private let lock = NSRecursiveLock()
    private var capturedValues: [Value] = []

    public init() {
    }

    /// All captured values in call order.
    public var values: [Value] {
        lock.lock()
        defer { lock.unlock() }

        return capturedValues
    }

    /// The most recently captured value.
    public var value: Value? {
        lock.lock()
        defer { lock.unlock() }

        return capturedValues.last
    }

    /// Returns a matcher that captures every matched value.
    public func capture() -> MockSynMatcher<Value> {
        MockSynMatcher.matching { [weak self] value in
            self?.append(value)
            return true
        }
    }

    private func append(_ value: Value) {
        lock.lock()
        defer { lock.unlock() }

        capturedValues.append(value)
    }
}

/// Captor specialization for closure arguments.
public typealias MockSynClosureCaptor<Closure> = MockSynArgumentCaptor<Closure>
