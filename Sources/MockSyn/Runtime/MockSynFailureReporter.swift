import Foundation

/// Runtime failure captured before MockSyn throws or crashes.
public struct MockSynFailure: Sendable {
    /// Human-readable failure message.
    public let message: String

    /// Source file associated with the runtime reporting point.
    public let file: StaticString

    /// Source line associated with the runtime reporting point.
    public let line: UInt

    public init(message: String, file: StaticString = #fileID, line: UInt = #line) {
        self.message = message
        self.file = file
        self.line = line
    }
}

/// Lightweight process-wide failure reporting channel used by MockSyn runtime errors.
public enum MockSynFailureReporter {
    private static let lock = NSRecursiveLock()
    #if compiler(>=6.0)
    private nonisolated(unsafe) static var handler: (@Sendable (MockSynFailure) -> Void)?
    #else
    private static var handler: (@Sendable (MockSynFailure) -> Void)?
    #endif

    /// Installs a custom failure handler. Passing `nil` disables reporting.
    public static func setHandler(_ newHandler: (@Sendable (MockSynFailure) -> Void)?) {
        lock.lock()
        defer { lock.unlock() }

        handler = newHandler
    }

    /// Adapts runtime failures to an XCTest-style failure closure.
    public static func useXCTest(_ recordFailure: @escaping @Sendable (String, StaticString, UInt) -> Void) {
        setHandler { failure in
            recordFailure(failure.message, failure.file, failure.line)
        }
    }

    /// Adapts runtime failures to a Swift Testing-style issue recording closure.
    public static func useSwiftTesting(_ recordIssue: @escaping @Sendable (String, StaticString, UInt) -> Void) {
        setHandler { failure in
            recordIssue(failure.message, failure.file, failure.line)
        }
    }

    /// Restores the default no-op reporter.
    public static func reset() {
        setHandler(nil)
    }

    /// Reports an error through the configured handler.
    public static func report(_ error: some CustomStringConvertible, file: StaticString = #fileID, line: UInt = #line) {
        report(MockSynFailure(message: String(describing: error), file: file, line: line))
    }

    /// Reports a concrete failure through the configured handler.
    public static func report(_ failure: MockSynFailure) {
        lock.lock()
        let currentHandler = handler
        lock.unlock()

        currentHandler?(failure)
    }
}
