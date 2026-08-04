import Foundation
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

struct MemberGenerationResult {
    let generatedMembers: [GeneratedMember]
    let isValid: Bool
}

enum MemberGenerator {
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
                let isNamedMember = function.name.text.isNamedMember
                guard isNamedMember || targetKind == .protocol else {
                    context.diagnose(Diagnostic(node: Syntax(attribute), message: MockSynDiagnostic.unsupportedOperatorRequirement))
                    isValid = false
                    continue
                }

                if targetKind == .class, function.modifiers.containsStatic {
                    context.diagnose(Diagnostic(node: Syntax(attribute), message: MockSynDiagnostic.unsupportedConcreteStaticMember))
                    isValid = false
                    continue
                }

                if targetKind == .class,
                   let finalModifier = function.modifiers.finalModifier {
                    diagnoseFinalMember(finalModifier, attribute: attribute, context: context)
                    isValid = false
                    continue
                }

                let generatedFunction = GeneratedFunction(
                    attributes: function.attributes.mockSynForwardedAttributes,
                    name: function.name.text,
                    dslName: isNamedMember ? function.name.text : function.name.text.mockSynOperatorDslName,
                    memberKey: nil,
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
                )
                generatedMembers.append(.function(generatedFunction))
                if generatedFunction.stubParameters.count > 6 {
                    let supportsWillThrow = generatedFunction.effectSpecifiers.hasThrowingEffect
                        && !generatedFunction.effectSpecifiers.hasRethrowsEffect
                    context.diagnose(Diagnostic(
                        node: Syntax(function),
                        message: MockSynDiagnostic.typedWillRunUnavailable(
                            member: generatedFunction.signatureName,
                            parameterCount: generatedFunction.stubParameters.count,
                            supportsWillThrow: supportsWillThrow
                        )
                    ))
                }
                continue
            }

            if let property = item.decl.as(VariableDeclSyntax.self) {
                if targetKind == .class, property.modifiers.containsStatic {
                    context.diagnose(Diagnostic(node: Syntax(attribute), message: MockSynDiagnostic.unsupportedConcreteStaticMember))
                    isValid = false
                    continue
                }

                if targetKind == .class,
                   let finalModifier = property.modifiers.finalModifier {
                    diagnoseFinalMember(finalModifier, attribute: attribute, context: context)
                    isValid = false
                    continue
                }

                guard let generatedProperty = GeneratedProperty(property, targetKind: targetKind) else {
                    continue
                }

                generatedMembers.append(.property(generatedProperty))
                continue
            }

            if let subscriptDeclaration = item.decl.as(SubscriptDeclSyntax.self) {
                generatedMembers.append(.subscriptMember(GeneratedSubscript(
                    attributes: subscriptDeclaration.attributes.mockSynForwardedAttributes,
                    genericParameterClause: subscriptDeclaration.genericParameterClause?.description.trimmedSource ?? "",
                    parameterClause: subscriptDeclaration.parameterClause.description.trimmedSource,
                    callArguments: subscriptDeclaration.parameterClause.subscriptCallArguments,
                    argumentValues: subscriptDeclaration.parameterClause.argumentValues,
                    stubParameters: subscriptDeclaration.parameterClause.generatedParameters,
                    returnClause: subscriptDeclaration.returnClause.description.trimmedReturnClause,
                    genericWhereClause: subscriptDeclaration.genericWhereClause?.description.trimmedReturnClause ?? "",
                    hasSetter: subscriptDeclaration.accessorBlock?.mockSynHasWritableAccessor == true,
                    getterEffectSpecifiers: subscriptDeclaration.accessorBlock?.mockSynGetterEffectSpecifiers ?? ""
                )))
                continue
            }

            if let initializer = item.decl.as(InitializerDeclSyntax.self),
               (targetKind == .class || doubleKind != .spy) {
                if targetKind == .class, initializer.signature.parameterClause.hasVariadicParameter {
                    context.diagnose(Diagnostic(node: Syntax(attribute), message: MockSynDiagnostic.unsupportedVariadicClassInitializer))
                    isValid = false
                    continue
                }

                if targetKind == .class, doubleKind == .spy, initializer.modifiers.containsRequired {
                    context.diagnose(Diagnostic(node: Syntax(attribute), message: MockSynDiagnostic.unsupportedRequiredClassSpyInitializer))
                    isValid = false
                    continue
                }

                generatedMembers.append(.initializer(GeneratedInitializer(
                    optionalMark: initializer.optionalMark?.text ?? "",
                    parameterClause: initializer.signature.parameterClause.description.trimmedSource,
                    callArguments: initializer.signature.parameterClause.callArguments,
                    effectSpecifiers: initializer.signature.effectSpecifiers?.description.trimmedEffectSpecifiers ?? "",
                    isRequired: initializer.modifiers.containsRequired
                )))
                continue
            }
        }

        return MemberGenerationResult(generatedMembers: generatedMembers, isValid: isValid)
    }

    private static func diagnoseFinalMember(
        _ finalModifier: DeclModifierSyntax,
        attribute: AttributeSyntax,
        context: some MacroExpansionContext
    ) {
        let fixIt = FixIt(
            message: MockSynFixItMessage.removeFinal,
            changes: [
                .replaceText(
                    range: finalModifier.name.position..<finalModifier.name.endPosition,
                    with: "",
                    in: Syntax(finalModifier.root)
                )
            ]
        )
        context.diagnose(Diagnostic(
            node: Syntax(attribute),
            message: MockSynDiagnostic.finalClassMember,
            fixIts: [fixIt]
        ))
    }
}
