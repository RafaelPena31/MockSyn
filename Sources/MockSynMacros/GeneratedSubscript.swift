import Foundation
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

struct GeneratedSubscript {
    let attributes: String
    let genericParameterClause: String
    let parameterClause: String
    let callArguments: String
    let argumentValues: String
    let stubParameters: [GeneratedParameter]
    let returnClause: String
    let genericWhereClause: String
    let hasSetter: Bool
    let getterEffectSpecifiers: String

    func source(access: String, kind: MockSynPeerMacro.Kind, target: Target) -> String {
        let declarationPrefix = target.kind == .class ? "override " : ""
        let arguments = "[\(argumentValues)]"
        let callPrefix = getterEffectSpecifiers.callPrefix
        let fallback = kind == .spy ? ", fallback: { \(callPrefix)self.__mockSynWrapped[\(callArguments)] }" : ""
        let getterBody: String
        if kind == .spy, getterEffectSpecifiers.hasAsyncEffect {
            let recording = "__mockSyn.record(member: \"\(signatureName).get\", arguments: \(arguments))"
            let delegation = "return \(callPrefix)self.__mockSynWrapped[\(callArguments)]"
            getterBody = "\(recording)\n      \(delegation)"
        } else if getterEffectSpecifiers.hasThrowingEffect {
            getterBody = "try __mockSyn.resolveThrowing(member: \"\(signatureName).get\", arguments: \(arguments), returnType: \(returnType).self\(fallback))"
        } else {
            getterBody = "__mockSyn.resolve(member: \"\(signatureName).get\", arguments: \(arguments), returnType: \(returnType).self\(fallback))"
        }
        let setterSource = hasSetter ? "\n    set {\n      __mockSyn.resolveVoid(member: \"\(signatureName).set\", arguments: \(setArguments))\n    }" : ""

        return """
          \(attributes)\(access) \(declarationPrefix)subscript\(genericParameterClause)\(parameterClause)\(returnClause)\(genericWhereClause) {
            get\(getterEffectSpecifiers) {
              \(getterBody)
            }\(setterSource)
          }
        """
    }

    func stubbingSource(access: String) -> String? {
        let matcherList = stubParameters.map { $0.matcherExpression }.joined(separator: ", ")
        if hasSetter {
            return """
                \(access) func `subscript`\(genericParameterClause)\(stubParameterClause) -> MockSynNonThrowingSubscriptStubber<\(returnType)>\(genericWhereClause) {
                  MockSynNonThrowingSubscriptStubber(runtime: __mockSyn, getMember: "\(signatureName).get", setMember: "\(signatureName).set", indexMatchers: [\(matcherList)])
                }
            """
        }

        let stubberType = getterEffectSpecifiers.hasThrowingEffect
            ? "MockSynSubscriptStubber"
            : "MockSynNonThrowingReadOnlySubscriptStubber"

        return """
            \(access) func `subscript`\(genericParameterClause)\(stubParameterClause) -> \(stubberType)<\(returnType)>\(genericWhereClause) {
              \(stubberType)(runtime: __mockSyn, getMember: "\(signatureName).get", indexMatchers: [\(matcherList)])
            }
        """
    }

    func verificationSource(access: String) -> String? {
        let matcherList = stubParameters.map { $0.matcherExpression }.joined(separator: ", ")
        guard hasSetter else {
            return """
                \(access) func `subscript`\(genericParameterClause)\(stubParameterClause) -> MockSynReadOnlySubscriptVerification<\(returnType)>\(genericWhereClause) {
                  MockSynReadOnlySubscriptVerification(runtime: __mockSyn, getMember: "\(signatureName).get", indexMatchers: [\(matcherList)])
                }
            """
        }

        return """
            \(access) func `subscript`\(genericParameterClause)\(stubParameterClause) -> MockSynSubscriptVerification<\(returnType)>\(genericWhereClause) {
              MockSynSubscriptVerification(runtime: __mockSyn, getMember: "\(signatureName).get", setMember: "\(signatureName).set", indexMatchers: [\(matcherList)])
            }
        """
    }

    private var signatureName: String {
        "subscript\(genericParameterClause)\(parameterClause.signatureSuffix)\(genericWhereClause)"
    }

    private var returnType: String {
        returnClause.returnTypeName
    }

    private var setArguments: String {
        "[\(argumentValues), newValue as Any]"
    }

    private var stubParameterClause: String {
        "(\(stubParameters.map { $0.matcherParameterSource(generatedName: "Self") }.joined(separator: ", ")))"
    }
}
