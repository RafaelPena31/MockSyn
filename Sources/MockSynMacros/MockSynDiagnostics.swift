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

    static let publicAccessOnInternalDeclaration = MockSynDiagnostic(
        id: "publicAccessOnInternalDeclaration",
        message: "MockSyn cannot generate a public double for an internal declaration"
    )

    private init(id: String, message: String) {
        self.message = message
        self.diagnosticID = MessageID(domain: "MockSyn", id: id)
        self.severity = .error
    }
}
