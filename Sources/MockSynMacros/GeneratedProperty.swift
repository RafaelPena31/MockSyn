import Foundation
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

struct GeneratedProperty {
    let attributes: String
    let name: String
    let type: String
    let isStatic: Bool
    let hasSetter: Bool
    let getterEffectSpecifiers: String

    func source(access: String, kind: MockSynPeerMacro.Kind, target: Target) -> String {
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
        let setterSource = hasSetter ? "\n    set {\n      __mockSyn.resolveVoid(member: \"\(name).set\", arguments: [newValue as Any])\n    }" : ""

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


extension GeneratedProperty {
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
            hasSetter: hasSetter,
            getterEffectSpecifiers: binding.accessorBlock?.mockSynGetterEffectSpecifiers ?? ""
        )
    }
}
