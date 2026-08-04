#if canImport(Combine)
import Combine

/// Publisher owned by generated doubles that directly conform to `ObservableObject`.
public final class MockSynObservableObjectPublisher: Publisher, @unchecked Sendable {
    public typealias Output = Void
    public typealias Failure = Never

    private let publisher = ObservableObjectPublisher()

    /// Creates an observable-object publisher for a generated test double.
    public init() {}

    public func receive<S>(subscriber: S) where S: Subscriber, Failure == S.Failure, Output == S.Input {
        publisher.receive(subscriber: subscriber)
    }

    /// Notifies all current subscribers that the generated double will change.
    public func send() {
        publisher.send()
    }
}
#endif
