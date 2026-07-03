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

    static let finalClass = MockSynDiagnostic(
        id: "finalClass",
        message: "MockSyn cannot mock a pure Swift final class directly. Extract a protocol and apply @Mocking to the protocol."
    )

    static let invalidAccess = MockSynDiagnostic(
        id: "invalidAccess",
        message: "MockSyn access must be one of: internal, public, package, fileprivate, private"
    )

    static let invalidMode = MockSynDiagnostic(
        id: "invalidMode",
        message: "MockSyn mode must be one of: strict, relaxed"
    )

    static let publicAccessOnInternalDeclaration = MockSynDiagnostic(
        id: "publicAccessOnInternalDeclaration",
        message: "MockSyn cannot generate a public double for an internal declaration"
    )

    static let unsupportedProtocolInheritance = MockSynDiagnostic(
        id: "unsupportedProtocolInheritance",
        message: "MockSyn supports protocol inheritance only with simple protocol names. Extract complex inherited constraints into a dedicated protocol."
    )

    static let unsupportedOperatorRequirement = MockSynDiagnostic(
        id: "unsupportedOperatorRequirement",
        message: "MockSyn cannot generate operator requirements yet. Wrap the operator behind a named method."
    )

    static let unsupportedAssociatedType = MockSynDiagnostic(
        id: "unsupportedAssociatedType",
        message: "MockSyn cannot generate protocols with associated types yet. Use a type-erased protocol or concrete wrapper."
    )

    private init(id: String, message: String) {
        self.message = message
        self.diagnosticID = MessageID(domain: "MockSyn", id: id)
        self.severity = .error
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
