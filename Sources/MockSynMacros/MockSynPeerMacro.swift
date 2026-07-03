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
            guard protocolDeclaration.hasOnlySimpleInheritedTypes else {
                context.diagnose(Diagnostic(
                    node: Syntax(attribute),
                    message: MockSynDiagnostic.unsupportedProtocolInheritance
                ))
                return []
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
            guard members.isValid else {
                return []
            }

            return try expand(
                attribute: attribute,
                target: Target(
                    kind: .protocol,
                    name: protocolDeclaration.name.text,
                    access: protocolDeclaration.modifiers.mockSynAccess,
                    attributes: protocolDeclaration.attributes.mockSynForwardedAttributes,
                    genericParameterClause: genericConfiguration.genericParameterClause,
                    genericArgumentClause: "",
                    genericWhereClause: genericConfiguration.genericWhereClause,
                    associatedTypes: associatedTypes,
                    spyWrappedTypeName: genericConfiguration.spyWrappedTypeName,
                    members: members.generatedMembers
                )
            )
        }

        if let classDeclaration = declaration.as(ClassDeclSyntax.self) {
            if let finalModifier = classDeclaration.modifiers.finalModifier {
                let fixIt = FixIt(
                    message: MockSynFixItMessage.removeFinal,
                    changes: [
                        .replaceText(
                            range: finalModifier.name.position..<finalModifier.name.endPosition,
                            with: "",
                            in: Syntax(classDeclaration.root)
                        )
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
                    access: classDeclaration.modifiers.mockSynAccess,
                    attributes: classDeclaration.attributes.mockSynForwardedAttributes,
                    genericParameterClause: classDeclaration.genericParameterClause?.description.trimmedSource ?? "",
                    genericArgumentClause: classDeclaration.genericParameterClause?.mockSynGenericArgumentClause ?? "",
                    genericWhereClause: classDeclaration.genericWhereClause?.description.trimmedReturnClause ?? "",
                    associatedTypes: [],
                    spyWrappedTypeName: nil,
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
        let associatedTypeSource = target.associatedTypeSource(access: access)
        let staticRuntimeSource = target.staticRuntimeSource(access: access, kind: kind, mode: mode)
        let memberSource = target.members
            .map { $0.source(access: access, options: options, kind: kind, target: target) }
            .joined(separator: "\n\n")
        let generatedMembers = memberSource.isEmpty ? "" : "\n\n\(memberSource)"
        let stubbingSource = target.stubbingSource(access: access)
        let staticStubbingSource = target.staticStubbingSource(access: access)

        let declarationSource: String
        if kind == .spy {
            declarationSource = """
            #if MOCKSYN_ENABLE
            \(target.attributes)\(access) final class \(generatedName)\(target.genericParameterClause): \(target.inheritedTypeName)\(target.genericWhereClause) {
            \(associatedTypeSource)\
            \(staticRuntimeSource)\
              \(access) let __mockSyn: MockSynRuntime
              \(access) let __mockSynWrapped: \(target.wrappedTypeName)

              \(access) init(wrapping __mockSynWrapped: \(target.wrappedTypeName), mode: MockSynMode = \(mode)) {
                self.__mockSyn = MockSynRuntime(kind: \(kind.runtimeKind), mode: mode)
                self.__mockSynWrapped = __mockSynWrapped\(superInitLine)
              }\(staticStubbingSource)\(stubbingSource)\(generatedMembers)
            }
            #endif
            """
        } else {
            declarationSource = """
            #if MOCKSYN_ENABLE
            \(target.attributes)\(access) final class \(generatedName)\(target.genericParameterClause): \(target.inheritedTypeName)\(target.genericWhereClause) {
            \(associatedTypeSource)\
            \(staticRuntimeSource)\
              \(access) let __mockSyn: MockSynRuntime

              \(access) init(mode: MockSynMode = \(mode)) {
                self.__mockSyn = MockSynRuntime(kind: \(kind.runtimeKind), mode: mode)\(superInitLine)
              }\(staticStubbingSource)\(stubbingSource)\(generatedMembers)
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
    let attributes: String
    let genericParameterClause: String
    let genericArgumentClause: String
    let genericWhereClause: String
    let associatedTypes: [AssociatedTypeBinding]
    let spyWrappedTypeName: String?
    let members: [GeneratedMember]

    var inheritedTypeName: String {
        switch kind {
        case .protocol:
            return name
        case .class:
            return "\(name)\(genericArgumentClause)"
        }
    }

    var wrappedTypeName: String {
        switch kind {
        case .protocol:
            return spyWrappedTypeName ?? "any \(name)"
        case .class:
            return inheritedTypeName
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

    var hasStaticMembers: Bool {
        members.contains { $0.isStatic }
    }

    func associatedTypeSource(access: String) -> String {
        guard !associatedTypes.isEmpty else {
            return ""
        }

        let typealiasAccess = access == "private" ? "fileprivate" : access
        return associatedTypes
            .map { "  \(typealiasAccess) typealias \($0.name) = \($0.name)" }
            .joined(separator: "\n") + "\n"
    }

    func staticRuntimeSource(access: String, kind: MockSynPeerMacro.Kind, mode: String) -> String {
        guard hasStaticMembers else {
            return ""
        }

        return "  \(access) static let __mockSynStatic = MockSynRuntime(kind: \(kind.runtimeKind), mode: \(mode))\n"
    }

    func staticStubbingSource(access: String) -> String {
        let stubbingMemberSources = members
            .compactMap { $0.staticStubbingSource(access: access) }
            .joined(separator: "\n\n")
        let verificationMemberSources = members
            .compactMap { $0.staticVerificationSource(access: access) }
            .joined(separator: "\n\n")

        guard !stubbingMemberSources.isEmpty || !verificationMemberSources.isEmpty else {
            return ""
        }

        return """

          \(access) static var given: __MockSynStaticGiven {
            __MockSynStaticGiven(__mockSyn: __mockSynStatic)
          }

          \(access) static var when: __MockSynStaticGiven {
            given
          }

          \(access) static var verify: __MockSynStaticVerify {
            __MockSynStaticVerify(__mockSyn: __mockSynStatic)
          }

          \(access) static func confirmStaticVerified() throws {
            try __mockSynStatic.confirmVerified()
          }

          \(access) static func checkUnnecessaryStaticStubs() throws {
            try __mockSynStatic.checkUnnecessaryStubs()
          }

          \(access) static func resetStatic(_ scope: MockSynResetScope = .all) {
            __mockSynStatic.reset(scope)
          }

          \(access) struct __MockSynStaticGiven {
            \(access) let __mockSyn: MockSynRuntime

        \(stubbingMemberSources)
          }

          \(access) struct __MockSynStaticVerify {
            \(access) let __mockSyn: MockSynRuntime

        \(verificationMemberSources)
          }
        """
    }

    func stubbingSource(access: String) -> String {
        let stubbingMemberSources = members
            .compactMap { $0.stubbingSource(access: access) }
            .joined(separator: "\n\n")
        let verificationMemberSources = members
            .compactMap { $0.verificationSource(access: access) }
            .joined(separator: "\n\n")

        guard !stubbingMemberSources.isEmpty || !verificationMemberSources.isEmpty else {
            return ""
        }

        return """

          \(access) var given: __MockSynGiven {
            __MockSynGiven(__mockSyn: __mockSyn)
          }

          \(access) var when: __MockSynGiven {
            given
          }

          \(access) var verify: __MockSynVerify {
            __MockSynVerify(__mockSyn: __mockSyn)
          }

          \(access) func confirmVerified() throws {
            try __mockSyn.confirmVerified()
          }

          \(access) func checkUnnecessaryStubs() throws {
            try __mockSyn.checkUnnecessaryStubs()
          }

          \(access) func reset(_ scope: MockSynResetScope = .all) {
            __mockSyn.reset(scope)
          }

          \(access) struct __MockSynGiven {
            \(access) let __mockSyn: MockSynRuntime

        \(stubbingMemberSources)
          }

          \(access) struct __MockSynVerify {
            \(access) let __mockSyn: MockSynRuntime

        \(verificationMemberSources)
          }
        """
    }
}

private enum TargetKind {
    case `protocol`
    case `class`
}

private struct ProtocolGenericConfiguration {
    let genericParameterClause: String
    let genericWhereClause: String
    let spyWrappedTypeName: String?

    init(
        protocolName: String,
        associatedTypes: [AssociatedTypeBinding],
        kind: MockSynPeerMacro.Kind
    ) {
        var genericParameters = associatedTypes.map(\.genericParameterSource)
        var whereRequirements = associatedTypes.flatMap(\.whereRequirements)
        let wrappedTypeName: String?

        if kind == .spy, !associatedTypes.isEmpty {
            wrappedTypeName = "__MockSynWrapped"
            genericParameters.append("__MockSynWrapped: \(protocolName)")
            whereRequirements.append(contentsOf: associatedTypes.map { "__MockSynWrapped.\($0.name) == \($0.name)" })
        } else {
            wrappedTypeName = nil
        }

        self.genericParameterClause = genericParameters.isEmpty ? "" : "<\(genericParameters.joined(separator: ", "))>"
        self.genericWhereClause = whereRequirements.isEmpty ? "" : " where \(whereRequirements.joined(separator: ", "))"
        self.spyWrappedTypeName = wrappedTypeName
    }
}

private struct AssociatedTypeBinding {
    let name: String
    let genericParameterSource: String
    let whereRequirements: [String]
}

private extension ProtocolDeclSyntax {
    var associatedTypeBindings: [AssociatedTypeBinding] {
        memberBlock.members.compactMap { item in
            guard let associatedType = item.decl.as(AssociatedTypeDeclSyntax.self) else {
                return nil
            }

            let name = associatedType.name.text
            let inheritedTypes = associatedType.inheritanceClause?.inheritedTypes.map {
                $0.type.description.trimmedSource
            } ?? []
            let genericParameterSource = inheritedTypes.isEmpty
                ? name
                : "\(name): \(inheritedTypes.joined(separator: " & "))"
            let whereRequirements = associatedType.genericWhereClause?.requirements.map {
                $0.description.trimmedSource
            } ?? []

            return AssociatedTypeBinding(
                name: name,
                genericParameterSource: genericParameterSource,
                whereRequirements: whereRequirements
            )
        }
    }
}

private enum GeneratedMember {
    case initializer(GeneratedInitializer)
    case function(GeneratedFunction)
    case property(GeneratedProperty)
    case subscriptMember(GeneratedSubscript)

    var isStatic: Bool {
        switch self {
        case .initializer, .subscriptMember:
            return false
        case .function(let function):
            return function.isStatic
        case .property(let property):
            return property.isStatic
        }
    }

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

    func stubbingSource(access: String) -> String? {
        switch self {
        case .initializer:
            return nil
        case .function(let function):
            return function.stubbingSource(access: access)
        case .property(let property):
            return property.stubbingSource(access: access)
        case .subscriptMember(let subscriptMember):
            return subscriptMember.stubbingSource(access: access)
        }
    }

    func staticStubbingSource(access: String) -> String? {
        switch self {
        case .initializer, .subscriptMember:
            return nil
        case .function(let function):
            return function.staticStubbingSource(access: access)
        case .property(let property):
            return property.staticStubbingSource(access: access)
        }
    }

    func verificationSource(access: String) -> String? {
        switch self {
        case .initializer:
            return nil
        case .function(let function):
            return function.verificationSource(access: access)
        case .property(let property):
            return property.verificationSource(access: access)
        case .subscriptMember(let subscriptMember):
            return subscriptMember.verificationSource(access: access)
        }
    }

    func staticVerificationSource(access: String) -> String? {
        switch self {
        case .initializer, .subscriptMember:
            return nil
        case .function(let function):
            return function.staticVerificationSource(access: access)
        case .property(let property):
            return property.staticVerificationSource(access: access)
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
    let attributes: String
    let name: String
    let genericParameterClause: String
    let parameterClause: String
    let callArguments: String
    let argumentValues: String
    let stubParameters: [GeneratedParameter]
    let effectSpecifiers: String
    let returnClause: String
    let genericWhereClause: String
    let isStatic: Bool
    let hasInoutParameter: Bool
    let hasVariadicParameter: Bool
    let returnsValue: Bool

    func source(access: String, kind: MockSynPeerMacro.Kind, target: Target) -> String {
        let declarationPrefix = target.kind == .class && !isStatic ? "override " : ""
        let staticPrefix = target.kind == .protocol && isStatic ? "static " : ""
        let body = bodySource(kind: kind)

        return """
          \(attributes)\(access) \(declarationPrefix)\(staticPrefix)func \(name)\(genericParameterClause)\(parameterClause)\(effectSpecifiers)\(returnClause)\(genericWhereClause) {
        \(body)
          }
        """
    }

    private func bodySource(kind: MockSynPeerMacro.Kind) -> String {
        if isStatic {
            let arguments = "[\(argumentValues)]"

            if effectSpecifiers.range(of: "throws") != nil {
                if returnsValue {
                    return "    return try __mockSynStatic.resolveThrowing(member: \"\(signatureName)\", arguments: \(arguments), returnType: \(returnType).self)"
                }

                return "    try __mockSynStatic.resolveVoidThrowing(member: \"\(signatureName)\", arguments: \(arguments))"
            }

            if returnsValue {
                return "    return __mockSynStatic.resolve(member: \"\(signatureName)\", arguments: \(arguments), returnType: \(returnType).self)"
            }

            return "    __mockSynStatic.resolveVoid(member: \"\(signatureName)\", arguments: \(arguments))"
        }

        if kind == .spy, !isStatic, hasInoutParameter {
            let callPrefix = effectSpecifiers.callPrefix
            let call = "__mockSynWrapped.\(name)(\(callArguments))"
            let recording = "    __mockSyn.record(member: \"\(signatureName)\", arguments: [\(argumentValues)])"
            let delegation = returnsValue ? "    return \(callPrefix)\(call)" : "    \(callPrefix)\(call)"
            return "\(recording)\n\(delegation)"
        }

        if effectSpecifiers.range(of: "async") != nil, kind == .spy && !isStatic && !hasVariadicParameter {
            let callPrefix = effectSpecifiers.callPrefix
            let call = "__mockSynWrapped.\(name)(\(callArguments))"
            return "    \(callPrefix)\(call)"
        }

        let arguments = "[\(argumentValues)]"
        let fallback = spyFallback(kind: kind)

        if effectSpecifiers.range(of: "throws") != nil {
            if returnsValue {
                return "    return try __mockSyn.resolveThrowing(member: \"\(signatureName)\", arguments: \(arguments), returnType: \(returnType).self\(fallback))"
            }

            return "    try __mockSyn.resolveVoidThrowing(member: \"\(signatureName)\", arguments: \(arguments)\(fallback))"
        }

        if returnsValue {
            return "    return __mockSyn.resolve(member: \"\(signatureName)\", arguments: \(arguments), returnType: \(returnType).self\(fallback))"
        }

        return "    __mockSyn.resolveVoid(member: \"\(signatureName)\", arguments: \(arguments)\(fallback))"
    }

    private func spyFallback(kind: MockSynPeerMacro.Kind) -> String {
        guard kind == .spy, !isStatic, !hasVariadicParameter else {
            return ""
        }

        return ", fallback: { \(effectSpecifiers.callPrefix)self.__mockSynWrapped.\(name)(\(callArguments)) }"
    }

    private var signatureName: String {
        "\(name)\(parameterClause.signatureSuffix)"
    }

    private var returnType: String {
        returnClause.returnTypeName
    }

    func stubbingSource(access: String) -> String? {
        guard !isStatic else {
            return nil
        }

        return functionStubbingSource(access: access)
    }

    func staticStubbingSource(access: String) -> String? {
        guard isStatic else {
            return nil
        }

        return functionStubbingSource(access: access)
    }

    private func functionStubbingSource(access: String) -> String {
        let matcherList = stubParameters.map { $0.matcherExpression }.joined(separator: ", ")
        let matchers = matcherList.isEmpty ? "[]" : "[\(matcherList)]"

        return """
            \(access) func \(name)\(genericParameterClause)\(stubParameterClause) -> \(stubBuilderType)\(genericWhereClause) {
              \(stubBuilderType)(runtime: __mockSyn, member: "\(signatureName)", matchers: \(matchers))
            }
        """
    }

    func verificationSource(access: String) -> String? {
        guard !isStatic else {
            return nil
        }

        return functionVerificationSource(access: access)
    }

    func staticVerificationSource(access: String) -> String? {
        guard isStatic else {
            return nil
        }

        return functionVerificationSource(access: access)
    }

    private func functionVerificationSource(access: String) -> String {
        let matcherList = stubParameters.map { $0.matcherExpression }.joined(separator: ", ")
        let matchers = matcherList.isEmpty ? "[]" : "[\(matcherList)]"

        return """
            \(access) func \(name)\(genericParameterClause)\(stubParameterClause) -> MockSynVerification\(genericWhereClause) {
              MockSynVerification(runtime: __mockSyn, member: "\(signatureName)", matchers: \(matchers))
            }
        """
    }

    private var stubParameterClause: String {
        "(\(stubParameters.map { $0.matcherParameterSource }.joined(separator: ", ")))"
    }

    private var stubBuilderType: String {
        guard stubParameters.count == 1, let parameter = stubParameters.first else {
            if stubParameters.count == 2 {
                let firstParameter = stubParameters[0]
                let secondParameter = stubParameters[1]
                return "MockSynStubBuilder2<\(firstParameter.matcherType), \(secondParameter.matcherType), \(returnType)>"
            }

            return "MockSynStubBuilder<\(returnType)>"
        }

        return "MockSynStubBuilder1<\(parameter.matcherType), \(returnType)>"
    }
}

private struct GeneratedProperty {
    let attributes: String
    let name: String
    let type: String
    let isStatic: Bool
    let hasSetter: Bool

    func source(access: String, kind: MockSynPeerMacro.Kind, target: Target) -> String {
        let declarationPrefix = target.kind == .class && !isStatic ? "override " : ""
        let staticPrefix = target.kind == .protocol && isStatic ? "static " : ""
        if isStatic {
            let getterBody = "__mockSynStatic.resolve(member: \"\(name).get\", arguments: [], returnType: \(type).self)"
            let setterSource = hasSetter ? "\n    set {\n      __mockSynStatic.resolveVoid(member: \"\(name).set\", arguments: [newValue as Any])\n    }" : ""

            return """
              \(attributes)\(access) \(staticPrefix)var \(name): \(type) {
                get {
                  \(getterBody)
                }\(setterSource)
              }
            """
        }

        let fallback = kind == .spy && !isStatic ? ", fallback: { self.__mockSynWrapped.\(name) }" : ""
        let getterBody = "__mockSyn.resolve(member: \"\(name).get\", arguments: [], returnType: \(type).self\(fallback))"
        let setterSource = hasSetter ? "\n    set {\n      __mockSyn.resolveVoid(member: \"\(name).set\", arguments: [newValue as Any])\n    }" : ""

        return """
          \(attributes)\(access) \(declarationPrefix)\(staticPrefix)var \(name): \(type) {
            get {
              \(getterBody)
            }\(setterSource)
          }
        """
    }

    func stubbingSource(access: String) -> String? {
        guard !isStatic else {
            return nil
        }

        return propertyStubbingSource(access: access)
    }

    func staticStubbingSource(access: String) -> String? {
        guard isStatic else {
            return nil
        }

        return propertyStubbingSource(access: access)
    }

    private func propertyStubbingSource(access: String) -> String {
        return """
            \(access) var \(name): MockSynPropertyStubber<\(type)> {
              MockSynPropertyStubber(runtime: __mockSyn, getMember: "\(name).get", setMember: "\(name).set")
            }
        """
    }

    func verificationSource(access: String) -> String? {
        guard !isStatic else {
            return nil
        }

        return propertyVerificationSource(access: access)
    }

    func staticVerificationSource(access: String) -> String? {
        guard isStatic else {
            return nil
        }

        return propertyVerificationSource(access: access)
    }

    private func propertyVerificationSource(access: String) -> String {
        return """
            \(access) var \(name): MockSynPropertyVerification<\(type)> {
              MockSynPropertyVerification(runtime: __mockSyn, getMember: "\(name).get", setMember: "\(name).set")
            }
        """
    }
}

private struct GeneratedSubscript {
    let attributes: String
    let parameterClause: String
    let callArguments: String
    let argumentValues: String
    let stubParameters: [GeneratedParameter]
    let returnClause: String
    let hasSetter: Bool

    func source(access: String, kind: MockSynPeerMacro.Kind, target: Target) -> String {
        let declarationPrefix = target.kind == .class ? "override " : ""
        let arguments = "[\(argumentValues)]"
        let fallback = kind == .spy ? ", fallback: { self.__mockSynWrapped[\(callArguments)] }" : ""
        let getterBody = "__mockSyn.resolve(member: \"\(signatureName).get\", arguments: \(arguments), returnType: \(returnType).self\(fallback))"
        let setterSource = hasSetter ? "\n    set {\n      __mockSyn.resolveVoid(member: \"\(signatureName).set\", arguments: \(setArguments))\n    }" : ""

        return """
          \(attributes)\(access) \(declarationPrefix)subscript\(parameterClause)\(returnClause) {
            get {
              \(getterBody)
            }\(setterSource)
          }
        """
    }

    func stubbingSource(access: String) -> String? {
        let matcherList = stubParameters.map { $0.matcherExpression }.joined(separator: ", ")

        return """
            \(access) func `subscript`\(stubParameterClause) -> MockSynSubscriptStubber<\(returnType)> {
              MockSynSubscriptStubber(runtime: __mockSyn, getMember: "\(signatureName).get", setMember: "\(signatureName).set", indexMatchers: [\(matcherList)])
            }
        """
    }

    func verificationSource(access: String) -> String? {
        let matcherList = stubParameters.map { $0.matcherExpression }.joined(separator: ", ")

        return """
            \(access) func `subscript`\(stubParameterClause) -> MockSynSubscriptVerification<\(returnType)> {
              MockSynSubscriptVerification(runtime: __mockSyn, getMember: "\(signatureName).get", setMember: "\(signatureName).set", indexMatchers: [\(matcherList)])
            }
        """
    }

    private var signatureName: String {
        "subscript\(parameterClause.signatureSuffix)"
    }

    private var returnType: String {
        returnClause.returnTypeName
    }

    private var setArguments: String {
        "[\(argumentValues), newValue as Any]"
    }

    private var stubParameterClause: String {
        "(\(stubParameters.map { $0.matcherParameterSource }.joined(separator: ", ")))"
    }
}

private struct MemberGenerationResult {
    let generatedMembers: [GeneratedMember]
    let isValid: Bool
}

private extension ProtocolDeclSyntax {
    var hasOnlySimpleInheritedTypes: Bool {
        guard let inheritedTypes = inheritanceClause?.inheritedTypes else {
            return true
        }

        return inheritedTypes.allSatisfy { inheritedType in
            inheritedType.type.as(IdentifierTypeSyntax.self) != nil
        }
    }
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
                    attributes: function.attributes.mockSynForwardedAttributes,
                    name: function.name.text,
                    genericParameterClause: function.genericParameterClause?.description.trimmedSource ?? "",
                    parameterClause: function.signature.parameterClause.description.trimmedSource,
                    callArguments: function.signature.parameterClause.callArguments,
                    argumentValues: function.signature.parameterClause.argumentValues,
                    stubParameters: function.signature.parameterClause.generatedParameters,
                    effectSpecifiers: function.signature.effectSpecifiers?.description.trimmedEffectSpecifiers ?? "",
                    returnClause: function.signature.returnClause?.description.trimmedReturnClause ?? "",
                    genericWhereClause: function.genericWhereClause?.description.trimmedReturnClause ?? "",
                    isStatic: function.modifiers.containsStatic,
                    hasInoutParameter: function.signature.parameterClause.hasInoutParameter,
                    hasVariadicParameter: function.signature.parameterClause.hasVariadicParameter,
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
                    attributes: subscriptDeclaration.attributes.mockSynForwardedAttributes,
                    parameterClause: subscriptDeclaration.parameterClause.description.trimmedSource,
                    callArguments: subscriptDeclaration.parameterClause.subscriptCallArguments,
                    argumentValues: subscriptDeclaration.parameterClause.argumentValues,
                    stubParameters: subscriptDeclaration.parameterClause.generatedParameters,
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
            attributes: declaration.attributes.mockSynForwardedAttributes,
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
            let argument = parameter.type.description.range(of: "inout") != nil ? "&\(localName)" : localName
            guard parameter.firstName.text != "_" else {
                return argument
            }

            return "\(parameter.firstName.text): \(argument)"
        }.joined(separator: ", ")
    }

    var argumentValues: String {
        parameters.map { parameter in
            let localName = parameter.secondName?.text ?? parameter.firstName.text
            return "\(localName) as Any"
        }.joined(separator: ", ")
    }

    var generatedParameters: [GeneratedParameter] {
        parameters.map { parameter in
            let localName = parameter.secondName?.text ?? parameter.firstName.text
            let label = parameter.firstName.text
            let matcherType = parameter.type.description
                .trimmedSource
                .replacingOccurrences(of: "inout ", with: "")
                .replacingOccurrences(of: "@escaping ", with: "")
            let typedMatcher = parameter.ellipsis == nil ? matcherType : "[\(matcherType)]"

            return GeneratedParameter(label: label, localName: localName, matcherType: typedMatcher)
        }
    }

    var hasVariadicParameter: Bool {
        parameters.contains { parameter in
            parameter.ellipsis != nil
        }
    }

    var hasInoutParameter: Bool {
        parameters.contains { parameter in
            parameter.type.description.range(of: "inout") != nil
        }
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

private struct GeneratedParameter {
    let label: String
    let localName: String
    let matcherType: String

    var matcherParameterSource: String {
        if label == "_" {
            return "_ \(localName): MockSynMatcher<\(matcherType)>"
        }

        if label != localName {
            return "\(label) \(localName): MockSynMatcher<\(matcherType)>"
        }

        return "\(label): MockSynMatcher<\(matcherType)>"
    }

    var matcherExpression: String {
        "\(localName).erase()"
    }
}

private extension AttributeListSyntax {
    var mockSynForwardedAttributes: String {
        let attributes = compactMap { element -> String? in
            let attribute = element.as(AttributeSyntax.self)!
            let attributeName = attribute.attributeName.description.trimmedSource
            guard attributeName.hasSuffix("Actor") else {
                return nil
            }

            return attribute.description.trimmedSource
        }

        return attributes.isEmpty ? "" : "\(attributes.joined(separator: " ")) "
    }
}

private extension GenericParameterClauseSyntax {
    var mockSynGenericArgumentClause: String {
        let arguments = parameters.map { parameter in
            parameter.name.text
        }.joined(separator: ", ")

        return "<\(arguments)>"
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

    var returnTypeName: String {
        let trimmed = trimmedSource
        guard trimmed.hasPrefix("->") else {
            return "Void"
        }

        return String(trimmed.dropFirst(2)).trimmedSource
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
