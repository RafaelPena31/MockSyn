import SwiftDiagnostics

struct MockSynDiagnostic: DiagnosticMessage, Error {
    let message: String
    let diagnosticID: MessageID
    let severity: DiagnosticSeverity

    static func unsupportedDeclaration(macroName: String) -> MockSynDiagnostic {
        MockSynDiagnostic(
            id: "unsupportedDeclaration",
            message: "@\(macroName) can only be applied to protocols or supported classes"
        )
    }

    static func invalidGeneratedName(macroName: String, affix: String) -> MockSynDiagnostic {
        MockSynDiagnostic(
            id: "invalidGeneratedName",
            message: "MockSyn generated name for @\(macroName) must start with \(affix) or end with \(affix)"
        )
    }

    static func inheritedProtocolRequirementsNotGenerated(
        macroName: String,
        inheritedTypes: [String]
    ) -> MockSynDiagnostic {
        MockSynDiagnostic(
            id: "inheritedProtocolRequirementsNotGenerated",
            message: "@\(macroName) does not generate requirements inherited from \(inheritedTypes.joined(separator: ", ")). Redeclare required members in the annotated protocol body or use a local mirror protocol.",
            severity: .warning
        )
    }

    static let finalClass = MockSynDiagnostic(
        id: "finalClass",
        message: "MockSyn cannot mock a pure Swift final class directly. Extract a protocol and apply @Mocking to the protocol."
    )

    static let finalClassMember = MockSynDiagnostic(
        id: "finalClassMember",
        message: "MockSyn cannot mock final class members by subclass generation. Remove 'final' from the member or extract a protocol."
    )

    static let invalidAccess = MockSynDiagnostic(
        id: "invalidAccess",
        message: "MockSyn access must be one of: inherited, internal, public, package, fileprivate, private"
    )

    static let invalidMode = MockSynDiagnostic(
        id: "invalidMode",
        message: "MockSyn mode must be one of: strict, relaxed"
    )

    static func cannotWidenAccess(
        requested: MockSynGeneratedAccess,
        declaration: MockSynGeneratedAccess
    ) -> MockSynDiagnostic {
        MockSynDiagnostic(
            id: "cannotWidenAccess",
            message: "MockSyn cannot generate \(requested.sourceName) access for a declaration with \(declaration.sourceName) access"
        )
    }

    static let unsupportedOperatorRequirement = MockSynDiagnostic(
        id: "unsupportedOperatorRequirement",
        message: "MockSyn cannot generate class operator members. Move the operator behind a protocol requirement."
    )

    static let unsupportedConcreteStaticMember = MockSynDiagnostic(
        id: "unsupportedConcreteStaticMember",
        message: "MockSyn cannot intercept concrete static class members. Move the static member behind a protocol requirement or use Objective-C interception for Objective-C class methods."
    )

    static let unsupportedRequiredClassSpyInitializer = MockSynDiagnostic(
        id: "unsupportedRequiredClassSpyInitializer",
        message: "MockSyn cannot mirror required class initializers for spies because class spies need a wrapped instance. Prefer a protocol spy or remove the required initializer."
    )

    static let unsupportedVariadicClassInitializer = MockSynDiagnostic(
        id: "unsupportedVariadicClassInitializer",
        message: "MockSyn cannot mirror variadic class initializers because Swift cannot forward captured variadic arrays to super.init."
    )

    static let privateClassInitializers = MockSynDiagnostic(
        id: "privateClassInitializers",
        message: "MockSyn cannot subclass a class whose declared initializers are all private. Add an internal or broader initializer, or mock a protocol instead."
    )

    static func typedWillRunUnavailable(
        member: String,
        parameterCount: Int,
        supportsWillThrow: Bool
    ) -> MockSynDiagnostic {
        let alternative = supportsWillThrow ? "willReturn or willThrow" : "willReturn"
        return MockSynDiagnostic(
            id: "typedWillRunUnavailable",
            message: "MockSyn typed willRun supports up to 6 parameters; '\(member)' has \(parameterCount). Configure it with \(alternative) instead.",
            severity: .warning
        )
    }

    private init(id: String, message: String, severity: DiagnosticSeverity = .error) {
        self.message = message
        self.diagnosticID = MessageID(domain: "MockSyn", id: id)
        self.severity = severity
    }
}

struct MockSynFixItMessage: FixItMessage {
    let message: String
    let fixItID: MessageID

    static let removeFinal = MockSynFixItMessage(
        id: "removeFinal",
        message: "Remove 'final'"
    )

    private init(id: String, message: String) {
        self.message = message
        self.fixItID = MessageID(domain: "MockSyn", id: id)
    }
}
