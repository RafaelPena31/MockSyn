import Foundation
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

struct GeneratedFunction {
    let attributes: String
    let name: String
    let dslName: String
    let memberKey: String?
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

    func disambiguatingReturnType() -> GeneratedFunction {
        GeneratedFunction(
            attributes: attributes,
            name: name,
            dslName: "\(dslName)Returning\(returnType.mockSynReturnDslSuffix)",
            memberKey: "\(signatureName) -> \(returnType)",
            genericParameterClause: genericParameterClause,
            parameterClause: parameterClause,
            callArguments: callArguments,
            argumentValues: argumentValues,
            stubParameters: stubParameters,
            effectSpecifiers: effectSpecifiers,
            returnClause: returnClause,
            genericWhereClause: genericWhereClause,
            isStatic: isStatic,
            hasInoutParameter: hasInoutParameter,
            hasVariadicParameter: hasVariadicParameter,
            returnsValue: returnsValue
        )
    }

    func renamingDsl(to dslName: String) -> GeneratedFunction {
        GeneratedFunction(
            attributes: attributes,
            name: name,
            dslName: dslName,
            memberKey: memberKey,
            genericParameterClause: genericParameterClause,
            parameterClause: parameterClause,
            callArguments: callArguments,
            argumentValues: argumentValues,
            stubParameters: stubParameters,
            effectSpecifiers: effectSpecifiers,
            returnClause: returnClause,
            genericWhereClause: genericWhereClause,
            isStatic: isStatic,
            hasInoutParameter: hasInoutParameter,
            hasVariadicParameter: hasVariadicParameter,
            returnsValue: returnsValue
        )
    }

    func source(access: String, kind: MockSynPeerMacro.Kind, target: Target, generatedName: String) -> String {
        let declarationPrefix = target.kind == .class && !isStatic ? "override " : ""
        let staticPrefix = target.kind == .protocol && isStatic ? "static " : ""
        let body = bodySource(kind: kind)
        let parameterClause = parameterClause.resolvingParameterSelf(as: generatedName)
        let functionName = name.isNamedMember ? name : "\(name) "

        return """
          \(attributes)\(access) \(declarationPrefix)\(staticPrefix)func \(functionName)\(genericParameterClause)\(parameterClause)\(effectSpecifiers)\(returnClause)\(genericWhereClause) {
        \(body)
          }
        """
    }

    private func bodySource(kind: MockSynPeerMacro.Kind) -> String {
        if isStatic {
            let arguments = "[\(argumentValues)]"

            if effectSpecifiers.hasRethrowsEffect {
                if returnsValue {
                    return "    return __mockSynStatic.resolve(member: \"\(memberName)\", arguments: \(arguments), returnType: \(returnType).self)"
                }

                return "    __mockSynStatic.resolveVoid(member: \"\(memberName)\", arguments: \(arguments))"
            }

            if effectSpecifiers.range(of: "throws") != nil {
                if returnsValue {
                    return "    return try __mockSynStatic.resolveThrowing(member: \"\(memberName)\", arguments: \(arguments), returnType: \(returnType).self)"
                }

                return "    try __mockSynStatic.resolveVoidThrowing(member: \"\(memberName)\", arguments: \(arguments))"
            }

            if returnsValue {
                return "    return __mockSynStatic.resolve(member: \"\(memberName)\", arguments: \(arguments), returnType: \(returnType).self)"
            }

            return "    __mockSynStatic.resolveVoid(member: \"\(memberName)\", arguments: \(arguments))"
        }

        if kind == .spy, !isStatic, hasInoutParameter {
            let callPrefix = effectSpecifiers.callPrefix
            let call = "__mockSynWrapped.\(name)(\(callArguments))"
            let recording = "    __mockSyn.record(member: \"\(memberName)\", arguments: [\(argumentValues)])"
            let delegation = returnsValue ? "    return \(callPrefix)\(call)" : "    \(callPrefix)\(call)"
            return "\(recording)\n\(delegation)"
        }

        if effectSpecifiers.hasRethrowsEffect, kind == .spy {
            let callPrefix = effectSpecifiers.callPrefix
            let fallback = "{ \(callPrefix)self.__mockSynWrapped.\(name)(\(callArguments)) }"
            if returnsValue {
                return "    return \(callPrefix)__mockSyn.resolveRethrowing(member: \"\(memberName)\", arguments: [\(argumentValues)], returnType: \(returnType).self, fallback: \(fallback))"
            }

            return "    \(callPrefix)__mockSyn.resolveVoidRethrowing(member: \"\(memberName)\", arguments: [\(argumentValues)], fallback: \(fallback))"
        }

        let arguments = "[\(argumentValues)]"

        if effectSpecifiers.hasRethrowsEffect {
            if returnsValue {
                return "    return __mockSyn.resolve(member: \"\(memberName)\", arguments: \(arguments), returnType: \(returnType).self)"
            }

            return "    __mockSyn.resolveVoid(member: \"\(memberName)\", arguments: \(arguments))"
        }

        if effectSpecifiers.range(of: "async") != nil, kind == .spy && !isStatic && !hasVariadicParameter {
            let callPrefix = effectSpecifiers.callPrefix
            let call = "__mockSynWrapped.\(name)(\(callArguments))"
            return "    \(callPrefix)\(call)"
        }

        let fallback = spyFallback(kind: kind)

        if effectSpecifiers.range(of: "throws") != nil {
            if returnsValue {
                return "    return try __mockSyn.resolveThrowing(member: \"\(memberName)\", arguments: \(arguments), returnType: \(returnType).self\(fallback))"
            }

            return "    try __mockSyn.resolveVoidThrowing(member: \"\(memberName)\", arguments: \(arguments)\(fallback))"
        }

        if returnsValue {
            return "    return __mockSyn.resolve(member: \"\(memberName)\", arguments: \(arguments), returnType: \(returnType).self\(fallback))"
        }

        return "    __mockSyn.resolveVoid(member: \"\(memberName)\", arguments: \(arguments)\(fallback))"
    }

    private func spyFallback(kind: MockSynPeerMacro.Kind) -> String {
        guard kind == .spy, !isStatic else {
            return ""
        }

        if hasVariadicParameter {
            guard effectSpecifiers.hasAsyncEffect == false,
                  let variadicFallback = variadicSpyFallback else {
                return ""
            }

            return ", fallback: {\n\(variadicFallback)\n    }"
        }

        return ", fallback: { \(effectSpecifiers.callPrefix)self.__mockSynWrapped.\(name)(\(callArguments)) }"
    }

    private var variadicSpyFallback: String? {
        let variadicParameters = stubParameters.filter(\.isVariadic)
        guard variadicParameters.count == 1, let variadicParameter = variadicParameters.first else {
            return nil
        }

        let cases = (0...8).map { count in
            let call = "self.__mockSynWrapped.\(name)(\(delegatedCallArguments(variadicParameter: variadicParameter, count: count)))"
            let statement = returnsValue ? "return \(effectSpecifiers.callPrefix)\(call)" : "\(effectSpecifiers.callPrefix)\(call)"
            return """
                  case \(count):
                    \(statement)
            """
        }.joined(separator: "\n")

        return """
                  switch \(variadicParameter.localName).count {
        \(cases)
                  default:
                    fatalError("MockSyn spy cannot delegate variadic member \(signatureName) with more than 8 values")
                  }
        """
    }

    private func delegatedCallArguments(variadicParameter: GeneratedParameter, count: Int) -> String {
        stubParameters.flatMap { parameter -> [String] in
            if parameter.isVariadic {
                return variadicDelegatedArguments(parameter: parameter, count: count)
            }

            guard parameter.label != "_" else {
                return [parameter.localName]
            }

            return ["\(parameter.label): \(parameter.localName)"]
        }.joined(separator: ", ")
    }

    private func variadicDelegatedArguments(parameter: GeneratedParameter, count: Int) -> [String] {
        guard count > 0 else {
            return []
        }

        return (0..<count).map { index in
            let value = "\(parameter.localName)[\(index)]"
            if index == 0, parameter.label != "_" {
                return "\(parameter.label): \(value)"
            }

            return value
        }
    }

    var signatureName: String {
        "\(name)\(parameterClause.signatureSuffix)"
    }

    var returnType: String {
        returnClause.returnTypeName
    }

    var dslCollisionKey: String {
        let parameters = stubParameters
            .map { "\($0.label):\($0.localName):\($0.matcherType)" }
            .joined(separator: "|")
        return "\(isStatic)|\(dslName)|\(genericParameterClause)|\(parameters)|\(genericWhereClause)"
    }

    private var memberName: String {
        memberKey ?? signatureName
    }

    func stubbingSource(access: String, generatedName: String) -> String? {
        guard !isStatic else {
            return nil
        }

        return functionStubbingSource(access: access, generatedName: generatedName)
    }

    func staticStubbingSource(access: String, generatedName: String) -> String? {
        guard isStatic else {
            return nil
        }

        return functionStubbingSource(access: access, generatedName: generatedName)
    }

    private func functionStubbingSource(access: String, generatedName: String) -> String {
        let matcherList = stubParameters.map { $0.matcherExpression }.joined(separator: ", ")
        let matchers = matcherList.isEmpty ? "[]" : "[\(matcherList)]"
        let stubParameterClause = stubParameterClause(generatedName: generatedName)
        let stubBuilderType = stubBuilderType(generatedName: generatedName)

        return """
            \(access) func \(dslName)\(genericParameterClause)\(stubParameterClause) -> \(stubBuilderType)\(genericWhereClause) {
              \(stubBuilderType)(runtime: __mockSyn, member: "\(memberName)", matchers: \(matchers))
            }
        """
    }

    func verificationSource(access: String, generatedName: String) -> String? {
        guard !isStatic else {
            return nil
        }

        return functionVerificationSource(access: access, generatedName: generatedName)
    }

    func staticVerificationSource(access: String, generatedName: String) -> String? {
        guard isStatic else {
            return nil
        }

        return functionVerificationSource(access: access, generatedName: generatedName)
    }

    private func functionVerificationSource(access: String, generatedName: String) -> String {
        let matcherList = stubParameters.map { $0.matcherExpression }.joined(separator: ", ")
        let matchers = matcherList.isEmpty ? "[]" : "[\(matcherList)]"
        let stubParameterClause = stubParameterClause(generatedName: generatedName)

        return """
            \(access) func \(dslName)\(genericParameterClause)\(stubParameterClause) -> MockSynVerification\(genericWhereClause) {
              MockSynVerification(runtime: __mockSyn, member: "\(memberName)", matchers: \(matchers))
            }
        """
    }

    private func stubParameterClause(generatedName: String) -> String {
        "(\(stubParameters.map { $0.matcherParameterSource(generatedName: generatedName) }.joined(separator: ", ")))"
    }

    private func stubBuilderType(generatedName: String) -> String {
        let returnType = returnType.resolvingSelf(as: generatedName)
        let builderBase = effectSpecifiers.hasRethrowsEffect ? "MockSynRethrowingStubBuilder" : "MockSynStubBuilder"
        guard stubParameters.count == 1, let parameter = stubParameters.first else {
            if stubParameters.count == 2 {
                let firstParameter = stubParameters[0]
                let secondParameter = stubParameters[1]
                return "\(builderBase)2<\(firstParameter.matcherType.resolvingSelf(as: generatedName)), \(secondParameter.matcherType.resolvingSelf(as: generatedName)), \(returnType)>"
            }

            return "\(builderBase)<\(returnType)>"
        }

        return "\(builderBase)1<\(parameter.matcherType.resolvingSelf(as: generatedName)), \(returnType)>"
    }
}
