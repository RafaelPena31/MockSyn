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
            let members = MemberGenerator.members(
                from: protocolDeclaration.memberBlock.members,
                targetKind: .protocol,
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
                    kind: .protocol,
                    name: protocolDeclaration.name.text,
                    access: protocolDeclaration.modifiers.mockSynAccess,
                    members: members.generatedMembers
                )
            )
        }

        if let classDeclaration = declaration.as(ClassDeclSyntax.self) {
            if classDeclaration.modifiers.containsFinal {
                context.diagnose(Diagnostic(node: Syntax(attribute), message: MockSynDiagnostic.finalClass))
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
                    access: classDeclaration.modifiers.mockSynAccess,
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
        let memberSource = target.members
            .map { $0.source(access: access, options: options, kind: kind, target: target) }
            .joined(separator: "\n\n")
        let generatedMembers = memberSource.isEmpty ? "" : "\n\n\(memberSource)"

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
              }\(generatedMembers)
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
              }\(generatedMembers)
            }
            #endif
            """
        }

        return [DeclSyntax(stringLiteral: declarationSource)]
    }
}

private struct Target {
    let kind: TargetKind
    let name: String
    let access: MockSynGeneratedAccess
    let members: [GeneratedMember]

    var wrappedTypeName: String {
        switch kind {
        case .protocol:
            return "any \(name)"
        case .class:
            return name
        }
    }

    var superInitCall: String? {
        switch kind {
        case .protocol:
            return nil
        case .class:
            return "super.init()"
        }
    }
}

private enum TargetKind {
    case `protocol`
    case `class`
}

private enum GeneratedMember {
    case initializer(GeneratedInitializer)
    case function(GeneratedFunction)
    case property(GeneratedProperty)
    case subscriptMember(GeneratedSubscript)

    func source(
        access: String,
        options: MockSynMacroOptions,
        kind: MockSynPeerMacro.Kind,
        target: Target
    ) -> String {
        switch self {
        case .initializer(let initializer):
            return initializer.source(access: access, options: options, kind: kind)
        case .function(let function):
            return function.source(access: access, kind: kind, target: target)
        case .property(let property):
            return property.source(access: access, kind: kind, target: target)
        case .subscriptMember(let subscriptMember):
            return subscriptMember.source(access: access, kind: kind, target: target)
        }
    }
}

private struct GeneratedInitializer {
    let parameterClause: String

    func source(access: String, options: MockSynMacroOptions, kind: MockSynPeerMacro.Kind) -> String {
        return """
          \(access) init\(parameterClause) {
            self.__mockSyn = MockSynRuntime(kind: \(kind.runtimeKind), mode: \(options.mode.sourceName))
          }
        """
    }
}

private struct GeneratedFunction {
    let name: String
    let parameterClause: String
    let callArguments: String
    let effectSpecifiers: String
    let returnClause: String
    let isStatic: Bool
    let returnsValue: Bool

    func source(access: String, kind: MockSynPeerMacro.Kind, target: Target) -> String {
        let declarationPrefix = target.kind == .class && !isStatic ? "override " : ""
        let staticPrefix = target.kind == .protocol && isStatic ? "static " : ""
        let body = bodySource(kind: kind)

        guard !body.isEmpty else {
            return """
              \(access) \(declarationPrefix)\(staticPrefix)func \(name)\(parameterClause)\(effectSpecifiers)\(returnClause) {
              }
            """
        }

        return """
          \(access) \(declarationPrefix)\(staticPrefix)func \(name)\(parameterClause)\(effectSpecifiers)\(returnClause) {
        \(body)
          }
        """
    }

    private func bodySource(kind: MockSynPeerMacro.Kind) -> String {
        if kind == .spy && !isStatic {
            let callPrefix = effectSpecifiers.callPrefix
            let call = "__mockSynWrapped.\(name)(\(callArguments))"
            return "    \(callPrefix)\(call)"
        }

        guard returnsValue else {
            return ""
        }

        return "    fatalError(\"MockSyn member \(signatureName) is not configured\")"
    }

    private var signatureName: String {
        "\(name)\(parameterClause.signatureSuffix)"
    }
}

private struct GeneratedProperty {
    let name: String
    let type: String
    let isStatic: Bool
    let hasSetter: Bool

    func source(access: String, kind: MockSynPeerMacro.Kind, target: Target) -> String {
        let declarationPrefix = target.kind == .class && !isStatic ? "override " : ""
        let staticPrefix = target.kind == .protocol && isStatic ? "static " : ""
        let getterBody = kind == .spy && !isStatic
            ? "__mockSynWrapped.\(name)"
            : "fatalError(\"MockSyn member \(name) is not configured\")"
        let setterSource = hasSetter ? "\n    set {\n    }" : ""

        return """
          \(access) \(declarationPrefix)\(staticPrefix)var \(name): \(type) {
            get {
              \(getterBody)
            }\(setterSource)
          }
        """
    }
}

private struct GeneratedSubscript {
    let parameterClause: String
    let callArguments: String
    let returnClause: String
    let hasSetter: Bool

    func source(access: String, kind: MockSynPeerMacro.Kind, target: Target) -> String {
        let declarationPrefix = target.kind == .class ? "override " : ""
        let getterBody = kind == .spy && target.kind == .protocol
            ? "__mockSynWrapped[\(callArguments)]"
            : "fatalError(\"MockSyn member subscript\(parameterClause.signatureSuffix) is not configured\")"
        let setterSource = hasSetter ? "\n    set {\n    }" : ""

        return """
          \(access) \(declarationPrefix)subscript\(parameterClause)\(returnClause) {
            get {
              \(getterBody)
            }\(setterSource)
          }
        """
    }
}

private struct MemberGenerationResult {
    let generatedMembers: [GeneratedMember]
    let isValid: Bool
}

private enum MemberGenerator {
    static func members(
        from memberBlock: MemberBlockItemListSyntax,
        targetKind: TargetKind,
        doubleKind: MockSynPeerMacro.Kind,
        attribute: AttributeSyntax,
        context: some MacroExpansionContext
    ) -> MemberGenerationResult {
        var generatedMembers: [GeneratedMember] = []
        var isValid = true

        for item in memberBlock {
            if let function = item.decl.as(FunctionDeclSyntax.self) {
                guard function.name.text.isNamedMember else {
                    context.diagnose(Diagnostic(node: Syntax(attribute), message: MockSynDiagnostic.unsupportedOperatorRequirement))
                    isValid = false
                    continue
                }

                generatedMembers.append(.function(GeneratedFunction(
                    name: function.name.text,
                    parameterClause: function.signature.parameterClause.description.trimmedSource,
                    callArguments: function.signature.parameterClause.callArguments,
                    effectSpecifiers: function.signature.effectSpecifiers?.description.trimmedEffectSpecifiers ?? "",
                    returnClause: function.signature.returnClause?.description.trimmedReturnClause ?? "",
                    isStatic: function.modifiers.containsStatic,
                    returnsValue: function.signature.returnClause.returnsValue
                )))
                continue
            }

            if let property = item.decl.as(VariableDeclSyntax.self),
               let generatedProperty = GeneratedProperty(property, targetKind: targetKind) {
                generatedMembers.append(.property(generatedProperty))
                continue
            }

            if let subscriptDeclaration = item.decl.as(SubscriptDeclSyntax.self) {
                generatedMembers.append(.subscriptMember(GeneratedSubscript(
                    parameterClause: subscriptDeclaration.parameterClause.description.trimmedSource,
                    callArguments: subscriptDeclaration.parameterClause.subscriptCallArguments,
                    returnClause: subscriptDeclaration.returnClause.description.trimmedReturnClause,
                    hasSetter: subscriptDeclaration.accessorBlock?.description.range(of: "set") != nil
                )))
                continue
            }

            if targetKind == .protocol,
               let initializer = item.decl.as(InitializerDeclSyntax.self),
               doubleKind != .spy {
                generatedMembers.append(.initializer(GeneratedInitializer(
                    parameterClause: initializer.signature.parameterClause.description.trimmedSource
                )))
                continue
            }
        }

        return MemberGenerationResult(generatedMembers: generatedMembers, isValid: isValid)
    }
}

private extension GeneratedProperty {
    init?(_ declaration: VariableDeclSyntax, targetKind: TargetKind) {
        guard let binding = declaration.bindings.first,
              let pattern = binding.pattern.as(IdentifierPatternSyntax.self),
              let type = binding.typeAnnotation?.type.description.trimmedSource else {
            return nil
        }
        let hasSetter = binding.accessorBlock?.description.range(of: "set") != nil
            || (binding.accessorBlock == nil && targetKind == .class && declaration.bindingSpecifier.text == "var")

        self.init(
            name: pattern.identifier.text,
            type: type,
            isStatic: declaration.modifiers.containsStatic,
            hasSetter: hasSetter
        )
    }
}

private extension DeclModifierListSyntax {
    var containsStatic: Bool {
        contains { modifier in
            modifier.name.text == "static"
        }
    }
}

private extension ReturnClauseSyntax? {
    var returnsValue: Bool {
        guard let type = self?.type.description.trimmedSource else {
            return false
        }

        return type != "Void" && type != "()"
    }
}

private extension FunctionParameterClauseSyntax {
    var callArguments: String {
        parameters.map { parameter in
            let localName = parameter.secondName?.text ?? parameter.firstName.text
            guard parameter.firstName.text != "_" else {
                return localName
            }

            return "\(parameter.firstName.text): \(localName)"
        }.joined(separator: ", ")
    }

    var subscriptCallArguments: String {
        parameters.map { parameter in
            guard let localName = parameter.secondName?.text else {
                return parameter.firstName.text
            }

            guard parameter.firstName.text != "_" else {
                return localName
            }

            return "\(parameter.firstName.text): \(localName)"
        }.joined(separator: ", ")
    }
}

private extension String {
    var trimmedSource: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var trimmedEffectSpecifiers: String {
        " \(trimmedSource)"
    }

    var trimmedReturnClause: String {
        " \(trimmedSource)"
    }

    var callPrefix: String {
        let hasAsync = range(of: "async") != nil
        let hasThrowing = range(of: "throws") != nil

        switch (hasThrowing, hasAsync) {
        case (true, true):
            return "try await "
        case (true, false):
            return "try "
        case (false, true):
            return "await "
        case (false, false):
            return ""
        }
    }

    var signatureSuffix: String {
        let parameters = dropFirst().dropLast()
        guard !parameters.isEmpty else {
            return "()"
        }

        let labels = parameters
            .split(separator: ",")
            .map { parameter -> String in
                let trimmedParameter = String(parameter).trimmedSource
                let firstToken = String(trimmedParameter.split(separator: " ").first!)
                let label = String(firstToken.split(separator: ":").first!)
                return "\(label):"
            }
            .joined()

        return "(\(labels))"
    }

    var isNamedMember: Bool {
        let firstCharacter = self[startIndex]
        return firstCharacter == "_" || firstCharacter.isLetter
    }
}
