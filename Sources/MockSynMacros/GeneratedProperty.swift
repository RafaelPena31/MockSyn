import Foundation
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

struct GeneratedProperty {
    let attributes: String
    let access: MockSynGeneratedAccess
    let name: String
    let type: String
    let isStatic: Bool
    let hasSetter: Bool
    let getterEffectSpecifiers: String

    func source(access: String, kind: MockSynPeerMacro.Kind, target: Target) -> String {
        let access = resolvedAccess(generatedAccess: access, targetKind: target.kind)
        let declarationPrefix = target.kind == .class && !isStatic ? "override " : ""
        let staticPrefix = target.kind == .protocol && isStatic ? "static " : ""
        if isStatic {
            let getterBody = staticGetterBody
            let setterSource = hasSetter ? "\n    set {\n      __mockSynStatic.resolveVoid(member: \"\(name).set\", arguments: [newValue as Any])\n    }" : ""

            return """
              \(attributes)\(access) \(staticPrefix)var \(name): \(type) {
                get\(getterEffectSpecifiers) {
                  \(getterBody)
                }\(setterSource)
              }
            """
        }

        let getterBody = getterBody(kind: kind)
        let changeNotification = target.isObservableObject ? "      __mockSyn.notifyChange()\n" : ""
        let setterSource = hasSetter ? "\n    set {\n\(changeNotification)      __mockSyn.resolveVoid(member: \"\(name).set\", arguments: [newValue as Any])\n    }" : ""

        return """
          \(attributes)\(access) \(declarationPrefix)\(staticPrefix)var \(name): \(type) {
            get\(getterEffectSpecifiers) {
              \(getterBody)
            }\(setterSource)
          }
        """
    }

    private var staticGetterBody: String {
        if getterEffectSpecifiers.hasThrowingEffect {
            return "try __mockSynStatic.resolveThrowing(member: \"\(name).get\", arguments: [], returnType: \(type).self)"
        }

        return "__mockSynStatic.resolve(member: \"\(name).get\", arguments: [], returnType: \(type).self)"
    }

    private func getterBody(kind: MockSynPeerMacro.Kind) -> String {
        if kind == .spy, getterEffectSpecifiers.hasAsyncEffect {
            let recording = "__mockSyn.record(member: \"\(name).get\", arguments: [])"
            let delegation = "return \(getterEffectSpecifiers.callPrefix)self.__mockSynWrapped.\(name)"
            return "\(recording)\n      \(delegation)"
        }

        let fallback = kind == .spy ? ", fallback: { \(getterEffectSpecifiers.callPrefix)self.__mockSynWrapped.\(name) }" : ""
        if getterEffectSpecifiers.hasThrowingEffect {
            return "try __mockSyn.resolveThrowing(member: \"\(name).get\", arguments: [], returnType: \(type).self\(fallback))"
        }

        return "__mockSyn.resolve(member: \"\(name).get\", arguments: [], returnType: \(type).self\(fallback))"
    }

    func stubbingSource(access: String, targetKind: TargetKind) -> String? {
        guard !isStatic else {
            return nil
        }

        return propertyStubbingSource(access: resolvedAccess(generatedAccess: access, targetKind: targetKind))
    }

    func staticStubbingSource(access: String, targetKind: TargetKind) -> String? {
        guard isStatic else {
            return nil
        }

        return propertyStubbingSource(access: resolvedAccess(generatedAccess: access, targetKind: targetKind))
    }

    private func propertyStubbingSource(access: String) -> String {
        if hasSetter {
            return """
                \(access) var \(name): MockSynNonThrowingPropertyStubber<\(type)> {
                  MockSynNonThrowingPropertyStubber(runtime: __mockSyn, getMember: "\(name).get", setMember: "\(name).set")
                }
            """
        }

        let stubberType = getterEffectSpecifiers.hasThrowingEffect
            ? "MockSynPropertyStubber"
            : "MockSynNonThrowingReadOnlyPropertyStubber"
        return """
            \(access) var \(name): \(stubberType)<\(type)> {
              \(stubberType)(runtime: __mockSyn, getMember: "\(name).get")
            }
        """
    }

    func verificationSource(access: String, targetKind: TargetKind) -> String? {
        guard !isStatic else {
            return nil
        }

        return propertyVerificationSource(access: resolvedAccess(generatedAccess: access, targetKind: targetKind))
    }

    func staticVerificationSource(access: String, targetKind: TargetKind) -> String? {
        guard isStatic else {
            return nil
        }

        return propertyVerificationSource(access: resolvedAccess(generatedAccess: access, targetKind: targetKind))
    }

    private func propertyVerificationSource(access: String) -> String {
        guard hasSetter else {
            return """
                \(access) var \(name): MockSynReadOnlyPropertyVerification<\(type)> {
                  MockSynReadOnlyPropertyVerification(runtime: __mockSyn, getMember: "\(name).get")
                }
            """
        }

        return """
            \(access) var \(name): MockSynPropertyVerification<\(type)> {
              MockSynPropertyVerification(runtime: __mockSyn, getMember: "\(name).get", setMember: "\(name).set")
            }
        """
    }

    private func resolvedAccess(generatedAccess: String, targetKind: TargetKind) -> String {
        targetKind == .class ? access.sourceName : generatedAccess
    }
}


extension GeneratedProperty {
    init?(_ declaration: VariableDeclSyntax, targetKind: TargetKind) {
        guard let binding = declaration.bindings.first,
              let pattern = binding.pattern.as(IdentifierPatternSyntax.self),
              let type = binding.typeAnnotation?.type.description.trimmedSource else {
            return nil
        }
        let hasAccessibleSetter = targetKind != .class || !declaration.modifiers.hasRestrictedSetter
        let hasSetter = hasAccessibleSetter && (
            binding.accessorBlock?.mockSynHasWritableAccessor(includingObservers: targetKind == .class) == true
                || (binding.accessorBlock == nil && targetKind == .class && declaration.bindingSpecifier.text == "var")
        )

        self.init(
            attributes: declaration.attributes.mockSynForwardedAttributes,
            access: declaration.modifiers.mockSynAccess,
            name: pattern.identifier.text,
            type: type,
            isStatic: declaration.modifiers.containsStatic,
            hasSetter: hasSetter,
            getterEffectSpecifiers: binding.accessorBlock?.mockSynGetterEffectSpecifiers ?? ""
        )
    }
}
