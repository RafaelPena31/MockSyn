import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

public struct MockingMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        try MockSynPeerMacro(kind: .mock).expand(attribute: node, declaration: declaration, context: context)
    }
}

public struct StubbingMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        try MockSynPeerMacro(kind: .stub).expand(attribute: node, declaration: declaration, context: context)
    }
}

public struct SpyingMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        try MockSynPeerMacro(kind: .spy).expand(attribute: node, declaration: declaration, context: context)
    }
}

private struct MockSynPeerMacro {
    enum Kind: Equatable {
        case mock
        case stub
        case spy

        var suffix: String {
            switch self {
            case .mock:
                return "Mock"
            case .stub:
                return "Stub"
            case .spy:
                return "Spy"
            }
        }

        var allowedAffix: String {
            suffix
        }

        var macroName: String {
            switch self {
            case .mock:
                return "Mocking"
            case .stub:
                return "Stubbing"
            case .spy:
                return "Spying"
            }
        }

        var runtimeKind: String {
            switch self {
            case .mock:
                return ".mock"
            case .stub:
                return ".stub"
            case .spy:
                return ".spy"
            }
        }

        var defaultMode: MockSynGeneratedMode {
            switch self {
            case .mock, .spy:
                return .strict
            case .stub:
                return .relaxed
            }
        }
    }

    let kind: Kind

    func expand(
        attribute: AttributeSyntax,
        declaration: some DeclSyntaxProtocol,
        context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        if let protocolDeclaration = declaration.as(ProtocolDeclSyntax.self) {
            return try expand(
                attribute: attribute,
                target: .protocol(name: protocolDeclaration.name.text, access: protocolDeclaration.modifiers.mockSynAccess)
            )
        }

        if let classDeclaration = declaration.as(ClassDeclSyntax.self) {
            if classDeclaration.modifiers.containsFinal {
                context.diagnose(Diagnostic(node: Syntax(attribute), message: MockSynDiagnostic.finalClass))
                return []
            }

            return try expand(
                attribute: attribute,
                target: .class(name: classDeclaration.name.text, access: classDeclaration.modifiers.mockSynAccess)
            )
        }

        context.diagnose(Diagnostic(
            node: Syntax(attribute),
            message: MockSynDiagnostic.unsupportedDeclaration(macroName: kind.macroName)
        ))
        return []
    }

    private func expand(
        attribute: AttributeSyntax,
        target: Target
    ) throws -> [DeclSyntax] {
        let options = try MockSynMacroOptions.parse(
            from: attribute,
            defaultAccess: .internal,
            defaultMode: kind.defaultMode
        )

        guard options.access <= target.access else {
            throw MockSynDiagnostic.publicAccessOnInternalDeclaration
        }

        let generatedName = options.name ?? "\(target.name)\(kind.suffix)"
        guard generatedName.hasPrefix(kind.allowedAffix) || generatedName.hasSuffix(kind.allowedAffix) else {
            throw MockSynDiagnostic.invalidGeneratedName(macroName: kind.macroName, affix: kind.allowedAffix)
        }

        let access = options.access.sourceName
        let mode = options.mode.sourceName
        let superInitLine = target.superInitCall.map { "\n    \($0)" } ?? ""

        let declarationSource: String
        if kind == .spy {
            declarationSource = """
            #if MOCKSYN_ENABLE
            \(access) final class \(generatedName): \(target.name) {
              \(access) let __mockSyn: MockSynRuntime
              \(access) let __mockSynWrapped: \(target.wrappedTypeName)

              \(access) init(wrapping __mockSynWrapped: \(target.wrappedTypeName), mode: MockSynMode = \(mode)) {
                self.__mockSyn = MockSynRuntime(kind: \(kind.runtimeKind), mode: mode)
                self.__mockSynWrapped = __mockSynWrapped\(superInitLine)
              }
            }
            #endif
            """
        } else {
            declarationSource = """
            #if MOCKSYN_ENABLE
            \(access) final class \(generatedName): \(target.name) {
              \(access) let __mockSyn: MockSynRuntime

              \(access) init(mode: MockSynMode = \(mode)) {
                self.__mockSyn = MockSynRuntime(kind: \(kind.runtimeKind), mode: mode)\(superInitLine)
              }
            }
            #endif
            """
        }

        return [DeclSyntax(stringLiteral: declarationSource)]
    }
}

private enum Target {
    case `protocol`(name: String, access: MockSynGeneratedAccess)
    case `class`(name: String, access: MockSynGeneratedAccess)

    var name: String {
        switch self {
        case .protocol(let name, _), .class(let name, _):
            return name
        }
    }

    var access: MockSynGeneratedAccess {
        switch self {
        case .protocol(_, let access), .class(_, let access):
            return access
        }
    }

    var wrappedTypeName: String {
        switch self {
        case .protocol(let name, _):
            return "any \(name)"
        case .class(let name, _):
            return name
        }
    }

    var superInitCall: String? {
        switch self {
        case .protocol:
            return nil
        case .class:
            return "super.init()"
        }
    }
}
