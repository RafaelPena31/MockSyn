import Foundation

/// Stub behavior configured through generated `given` APIs.
public struct MockSynStubBehavior<Return> {
    private let resolver: ([Any]) throws -> Return

    private init(resolver: @escaping ([Any]) throws -> Return) {
        self.resolver = resolver
    }

    /// Returns values sequentially. After the sequence is exhausted, the last value is reused.
    public static func returns(_ values: [Return]) -> MockSynStubBehavior<Return> {
        let sequence = MockSynReturnSequence(values: values)
        return MockSynStubBehavior { _ in
            sequence.next()
        }
    }

    /// Throws the configured error.
    public static func throwing(_ error: Error) -> MockSynStubBehavior<Return> {
        MockSynStubBehavior { _ in
            throw error
        }
    }

    /// Executes a custom closure.
    public static func runs(_ body: @escaping ([Any]) throws -> Return) -> MockSynStubBehavior<Return> {
        MockSynStubBehavior(resolver: body)
    }

    func erase() -> MockSynErasedStubBehavior {
        MockSynErasedStubBehavior { arguments in
            try resolver(arguments)
        }
    }
}

struct MockSynErasedStubBehavior {
    private let resolver: ([Any]) throws -> Any

    init(resolver: @escaping ([Any]) throws -> Any) {
        self.resolver = resolver
    }

    func resolve(_ arguments: [Any]) throws -> Any {
        try resolver(arguments)
    }
}

private final class MockSynReturnSequence<Return>: @unchecked Sendable {
    private var values: [Return]
    private var index = 0
    private let lock = NSRecursiveLock()

    init(values: [Return]) {
        self.values = values
    }

    func next() -> Return {
        lock.lock()
        defer { lock.unlock() }

        let last = values[values.count - 1]

        guard index < values.count else {
            return last
        }

        let value = values[index]
        index += 1
        return value
    }
}
