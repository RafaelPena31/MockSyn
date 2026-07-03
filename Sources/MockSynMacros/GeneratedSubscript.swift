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

    func source(access: String, kind: MockSynPeerMacro.Kind, target: Target) -> String {
        let declarationPrefix = target.kind == .class ? "override " : ""
        let arguments = "[\(argumentValues)]"
        let fallback = kind == .spy ? ", fallback: { self.__mockSynWrapped[\(callArguments)] }" : ""
        let getterBody = "__mockSyn.resolve(member: \"\(signatureName).get\", arguments: \(arguments), returnType: \(returnType).self\(fallback))"
        let setterSource = hasSetter ? "\n    set {\n      __mockSyn.resolveVoid(member: \"\(signatureName).set\", arguments: \(setArguments))\n    }" : ""

        return """
          \(attributes)\(access) \(declarationPrefix)subscript\(genericParameterClause)\(parameterClause)\(returnClause)\(genericWhereClause) {
            get {
              \(getterBody)
            }\(setterSource)
          }
        """
    }

    func stubbingSource(access: String) -> String? {
        let matcherList = stubParameters.map { $0.matcherExpression }.joined(separator: ", ")

        return """
            \(access) func `subscript`\(genericParameterClause)\(stubParameterClause) -> MockSynSubscriptStubber<\(returnType)>\(genericWhereClause) {
              MockSynSubscriptStubber(runtime: __mockSyn, getMember: "\(signatureName).get", setMember: "\(signatureName).set", indexMatchers: [\(matcherList)])
            }
        """
    }

    func verificationSource(access: String) -> String? {
        let matcherList = stubParameters.map { $0.matcherExpression }.joined(separator: ", ")

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
