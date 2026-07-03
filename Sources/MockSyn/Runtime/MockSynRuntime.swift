/// Minimal runtime state shared by generated MockSyn test doubles.
///
/// Later feature blocks extend this type with invocation storage, stubbing, and verification.
public final class MockSynRuntime: @unchecked Sendable {
    /// The generated double kind.
    public let kind: MockSynDoubleKind

    /// The default behavior for unstubbed calls.
    public let mode: MockSynMode

    /// Creates runtime state for a generated test double.
    public init(kind: MockSynDoubleKind, mode: MockSynMode) {
        self.kind = kind
        self.mode = mode
    }
}
