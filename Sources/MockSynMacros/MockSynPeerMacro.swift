import Foundation
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

struct MockSynPeerMacro {
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
            let lexicalExtensionAccess = lexicalExtensionAccess(
                declaration: protocolDeclaration,
                context: context
            )
            let inheritedTypes = protocolDeclaration.mockSynInheritedTypesWithUngeneratedRequirements
            if !inheritedTypes.isEmpty {
                context.diagnose(Diagnostic(
                    node: Syntax(attribute),
                    message: MockSynDiagnostic.inheritedProtocolRequirementsNotGenerated(
                        macroName: kind.macroName,
                        inheritedTypes: inheritedTypes
                    )
                ))
            }

            let associatedTypes = protocolDeclaration.associatedTypeBindings
            let genericConfiguration = ProtocolGenericConfiguration(
                protocolName: protocolDeclaration.name.text,
                associatedTypes: associatedTypes,
                kind: kind
            )
            let members = MemberGenerator.members(
                from: protocolDeclaration.memberBlock.members,
                targetKind: .protocol,
                doubleKind: kind,
                attribute: attribute,
                context: context
            )

            return try expand(
                attribute: attribute,
                target: Target(
                    kind: .protocol,
                    name: protocolDeclaration.name.text,
                    access: effectiveAccess(
                        declarationModifiers: protocolDeclaration.modifiers,
                        lexicalExtensionAccess: lexicalExtensionAccess
                    ),
                    lexicalExtensionAccess: lexicalExtensionAccess,
                    attributes: protocolDeclaration.attributes.mockSynForwardedAttributes,
                    genericParameterClause: genericConfiguration.genericParameterClause,
                    genericArgumentClause: "",
                    genericWhereClause: genericConfiguration.genericWhereClause,
                    associatedTypes: associatedTypes,
                    spyWrappedTypeName: genericConfiguration.spyWrappedTypeName,
                    isObservableObject: protocolDeclaration.mockSynDirectlyInheritsObservableObject,
                    members: members.generatedMembers
                )
            )
        }

        if let classDeclaration = declaration.as(ClassDeclSyntax.self) {
            let lexicalExtensionAccess = lexicalExtensionAccess(
                declaration: classDeclaration,
                context: context
            )
            if classDeclaration.modifiers.finalModifier != nil {
                var replacement = classDeclaration
                replacement.modifiers = classDeclaration.modifiers.removingFinal
                if let leadingTrivia = classDeclaration.modifiers.leadingTriviaRemovedWithFinal {
                    replacement.classKeyword.leadingTrivia = leadingTrivia
                }
                let fixIt = FixIt(
                    message: MockSynFixItMessage.removeFinal,
                    changes: [
                        .replace(oldNode: Syntax(classDeclaration), newNode: Syntax(replacement))
                    ]
                )
                context.diagnose(Diagnostic(
                    node: Syntax(attribute),
                    message: MockSynDiagnostic.finalClass,
                    fixIts: [fixIt]
                ))
                return []
            }

            let members = MemberGenerator.members(
                from: classDeclaration.memberBlock.members,
                targetKind: .class,
                doubleKind: kind,
                attribute: attribute,
                context: context
            )
            guard members.isValid else {
                return []
            }

            return try expand(
                attribute: attribute,
                target: Target(
                    kind: .class,
                    name: classDeclaration.name.text,
                    access: effectiveAccess(
                        declarationModifiers: classDeclaration.modifiers,
                        lexicalExtensionAccess: lexicalExtensionAccess
                    ),
                    lexicalExtensionAccess: lexicalExtensionAccess,
                    attributes: classDeclaration.attributes.mockSynForwardedAttributes,
                    genericParameterClause: classDeclaration.genericParameterClause?.description.trimmedSource ?? "",
                    genericArgumentClause: classDeclaration.genericParameterClause?.mockSynGenericArgumentClause ?? "",
                    genericWhereClause: classDeclaration.genericWhereClause?.description.trimmedReturnClause ?? "",
                    associatedTypes: [],
                    spyWrappedTypeName: nil,
                    isObservableObject: false,
                    members: members.generatedMembers
                )
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
            defaultMode: kind.defaultMode
        )
        let resolvedAccess = options.access.resolved(for: target.access)

        guard resolvedAccess <= target.access else {
            throw MockSynDiagnostic.cannotWidenAccess(
                requested: resolvedAccess,
                declaration: target.access
            )
        }

        let generatedName = options.name ?? "\(target.name)\(kind.suffix)"
        guard generatedName.hasPrefix(kind.allowedAffix) || generatedName.hasSuffix(kind.allowedAffix) else {
            throw MockSynDiagnostic.invalidGeneratedName(macroName: kind.macroName, affix: kind.allowedAffix)
        }

        let access = resolvedAccess.sourceName
        let declarationAccess = target.lexicalExtensionAccess == resolvedAccess ? "" : "\(access) "
        let memberAccess = resolvedAccess.generatedMemberSourceName
        let mode = options.mode.sourceName
        let associatedTypeSource = target.associatedTypeSource(access: memberAccess)
        let observableObjectPublisherSource = target.observableObjectPublisherSource(access: memberAccess)
        let staticRuntimeSource = target.staticRuntimeSource(access: memberAccess, kind: kind, mode: mode)
        let memberSource = target.members
            .map { $0.source(access: memberAccess, options: options, kind: kind, target: target, generatedName: generatedName) }
            .joined(separator: "\n\n")
        let stubbingSource = target.stubbingSource(access: memberAccess, generatedName: generatedName)
        let staticStubbingSource = target.staticStubbingSource(access: memberAccess, generatedName: generatedName)
        let initializerSource = target.primaryInitializerSource(access: memberAccess, kind: kind, mode: mode)
        let generatedMembers = memberSource.isEmpty
            ? ""
            : "\(initializerSource.isEmpty ? "" : "\n\n")\(memberSource)"

        let declarationSource: String
        if kind == .spy {
            declarationSource = """
            #if MOCKSYN_ENABLE
            \(target.attributes)\(declarationAccess)final class \(generatedName)\(target.genericParameterClause): \(target.inheritedTypeName)\(target.genericWhereClause) {
            \(associatedTypeSource)\
            \(staticRuntimeSource)\
            \(observableObjectPublisherSource)\
              \(memberAccess) let __mockSyn: MockSynRuntime
              \(memberAccess) let __mockSynWrapped: \(target.wrappedTypeName)

            \(initializerSource)\(staticStubbingSource)\(stubbingSource)\(generatedMembers)
            }
            #endif
            """
        } else {
            declarationSource = """
            #if MOCKSYN_ENABLE
            \(target.attributes)\(declarationAccess)final class \(generatedName)\(target.genericParameterClause): \(target.inheritedTypeName)\(target.genericWhereClause) {
            \(associatedTypeSource)\
            \(staticRuntimeSource)\
            \(observableObjectPublisherSource)\
              \(memberAccess) let __mockSyn: MockSynRuntime

            \(initializerSource)\(staticStubbingSource)\(stubbingSource)\(generatedMembers)
            }
            #endif
            """
        }

        return [DeclSyntax(stringLiteral: declarationSource)]
    }

    private func effectiveAccess(
        declarationModifiers: DeclModifierListSyntax,
        lexicalExtensionAccess: MockSynGeneratedAccess?
    ) -> MockSynGeneratedAccess {
        if let explicitAccess = declarationModifiers.mockSynExplicitAccess {
            return explicitAccess
        }

        return lexicalExtensionAccess ?? .internal
    }

    private func lexicalExtensionAccess(
        declaration: some DeclSyntaxProtocol,
        context: some MacroExpansionContext
    ) -> MockSynGeneratedAccess? {
        if let parentAccess = MockSynLexicalAccess.extensionAccess(of: Syntax(declaration)) {
            return parentAccess
        }

        #if canImport(SwiftSyntax600)
        return MockSynLexicalAccess.extensionAccess(in: context.lexicalContext)
        #else
        return nil
        #endif
    }
}
