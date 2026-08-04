#if canImport(Combine)
import Combine
import Foundation

/// Publisher owned by generated doubles that directly conform to `ObservableObject`.
///
/// The `@unchecked Sendable` conformance is protected by a recursive lock that
/// serializes access to the underlying publisher while allowing synchronous
/// subscriber callbacks to reenter `send()` or `receive(subscriber:)`.
public final class MockSynObservableObjectPublisher: Publisher, @unchecked Sendable {
    public typealias Output = Void
    public typealias Failure = Never

    private let lock = NSRecursiveLock()
    private let publisher = ObservableObjectPublisher()

    /// Creates an observable-object publisher for a generated test double.
    public init() {}

    public func receive<S>(subscriber: S) where S: Subscriber, Failure == S.Failure, Output == S.Input {
        lock.lock()
        defer { lock.unlock() }

        publisher.receive(subscriber: subscriber)
    }

    /// Notifies all current subscribers that the generated double will change.
    public func send() {
        lock.lock()
        defer { lock.unlock() }

        publisher.send()
    }
}
#endif
