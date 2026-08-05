/// Access level used by MockSyn macros when emitting generated test doubles.
public enum MockSynAccess: Equatable, Sendable {
    /// Inherits the effective access level visible at the annotated declaration.
    ///
    /// SwiftSyntax 509 cannot expose access written only on a surrounding
    /// extension; Swift 5.9 consumers must choose an explicit access in that case.
    case inherited

    /// Emits an `internal` generated type.
    case `internal`

    /// Emits a `public` generated type.
    case `public`

    /// Emits a `package` generated type.
    case `package`

    /// Emits a `fileprivate` generated type.
    case `fileprivate`

    /// Emits a `private` generated type.
    case `private`

    /// Source spelling used when representing this macro option.
    ///
    /// The macro resolves `inherited` to the declaration access visible in the
    /// expansion context before emitting the generated type.
    public var generatedSourceName: String {
        switch self {
        case .inherited:
            return "inherited"
        case .internal:
            return "internal"
        case .public:
            return "public"
        case .package:
            return "package"
        case .fileprivate:
            return "fileprivate"
        case .private:
            return "private"
        }
    }
}
