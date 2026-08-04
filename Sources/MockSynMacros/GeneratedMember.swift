import Foundation
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

enum GeneratedMember {
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
        target: Target,
        generatedName: String
    ) -> String {
        switch self {
        case .initializer(let initializer):
            return initializer.source(access: access, options: options, kind: kind, target: target)
        case .function(let function):
            return function.source(access: access, kind: kind, target: target, generatedName: generatedName)
        case .property(let property):
            return property.source(access: access, kind: kind, target: target)
        case .subscriptMember(let subscriptMember):
            return subscriptMember.source(access: access, kind: kind, target: target)
        }
    }

    func stubbingSource(access: String, targetKind: TargetKind, generatedName: String) -> String? {
        switch self {
        case .initializer:
            return nil
        case .function(let function):
            return function.stubbingSource(access: access, targetKind: targetKind, generatedName: generatedName)
        case .property(let property):
            return property.stubbingSource(access: access, targetKind: targetKind)
        case .subscriptMember(let subscriptMember):
            return subscriptMember.stubbingSource(access: access, targetKind: targetKind)
        }
    }

    func staticStubbingSource(access: String, targetKind: TargetKind, generatedName: String) -> String? {
        switch self {
        case .initializer, .subscriptMember:
            return nil
        case .function(let function):
            return function.staticStubbingSource(access: access, targetKind: targetKind, generatedName: generatedName)
        case .property(let property):
            return property.staticStubbingSource(access: access, targetKind: targetKind)
        }
    }

    func verificationSource(access: String, targetKind: TargetKind, generatedName: String) -> String? {
        switch self {
        case .initializer:
            return nil
        case .function(let function):
            return function.verificationSource(access: access, targetKind: targetKind, generatedName: generatedName)
        case .property(let property):
            return property.verificationSource(access: access, targetKind: targetKind)
        case .subscriptMember(let subscriptMember):
            return subscriptMember.verificationSource(access: access, targetKind: targetKind)
        }
    }

    func staticVerificationSource(access: String, targetKind: TargetKind, generatedName: String) -> String? {
        switch self {
        case .initializer, .subscriptMember:
            return nil
        case .function(let function):
            return function.staticVerificationSource(access: access, targetKind: targetKind, generatedName: generatedName)
        case .property(let property):
            return property.staticVerificationSource(access: access, targetKind: targetKind)
        }
    }
}

extension Array where Element == GeneratedMember {
    func mockSynDisambiguatingReturnTypeOverloads() -> [GeneratedMember] {
        let functions = compactMap { member -> GeneratedFunction? in
            guard case .function(let function) = member else {
                return nil
            }

            return function
        }
        var returnTypesBySignature: [String: Set<String>] = [:]
        for function in functions {
            let key = "\(function.isStatic)|\(function.signatureName)"
            if var returnTypes = returnTypesBySignature[key] {
                returnTypes.insert(function.returnType)
                returnTypesBySignature[key] = returnTypes
            } else {
                returnTypesBySignature[key] = [function.returnType]
            }
        }

        var duplicateReturnSignatures = Set<String>()
        for (key, returnTypes) in returnTypesBySignature where returnTypes.count > 1 {
            duplicateReturnSignatures.insert(key)
        }

        guard !duplicateReturnSignatures.isEmpty else {
            return self
        }

        let disambiguatedMembers: [GeneratedMember] = map { member in
            guard case .function(let function) = member else {
                return member
            }

            let key = "\(function.isStatic)|\(function.signatureName)"
            guard duplicateReturnSignatures.contains(key) else {
                return member
            }

            return .function(function.disambiguatingReturnType())
        }

        return disambiguatedMembers.mockSynResolvingReturnDslCollisions()
    }

    private func mockSynResolvingReturnDslCollisions() -> [GeneratedMember] {
        let functions = compactMap { member -> GeneratedFunction? in
            guard case .function(let function) = member, function.memberKey != nil else {
                return nil
            }

            return function
        }

        var countsByDslSignature: [String: Int] = [:]
        for function in functions {
            let dslCollisionKey = function.dslCollisionKey
            if let count = countsByDslSignature[dslCollisionKey] {
                countsByDslSignature[dslCollisionKey] = count + 1
            } else {
                countsByDslSignature[dslCollisionKey] = 1
            }
        }

        guard countsByDslSignature.values.contains(where: { $0 > 1 }) else {
            return self
        }

        var seenByDslSignature: [String: Int] = [:]
        return map { member in
            guard case .function(let function) = member, function.memberKey != nil else {
                return member
            }

            let dslCollisionKey = function.dslCollisionKey
            guard countsByDslSignature[dslCollisionKey]! > 1 else {
                return member
            }

            let seenCount: Int
            if let count = seenByDslSignature[dslCollisionKey] {
                seenCount = count + 1
            } else {
                seenCount = 1
            }
            seenByDslSignature[dslCollisionKey] = seenCount
            guard seenCount > 1 else {
                return member
            }

            return .function(function.renamingDsl(to: "\(function.dslName)Overload\(seenCount)"))
        }
    }
}
