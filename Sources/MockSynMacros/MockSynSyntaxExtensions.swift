import Foundation
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

extension DeclModifierListSyntax {
    var containsStatic: Bool {
        contains { modifier in
            modifier.name.text == "static"
        }
    }

    var containsRequired: Bool {
        contains { modifier in
            modifier.name.text == "required"
        }
    }
}

extension AccessorBlockSyntax {
    func mockSynHasWritableAccessor(includingObservers: Bool = false) -> Bool {
        guard case .accessors(let accessors) = self.accessors else {
            return false
        }

        return accessors.contains { accessor in
            let specifier = accessor.accessorSpecifier.tokenKind
            if specifier == .keyword(.set) || specifier == .keyword(._modify) {
                return true
            }

            return includingObservers
                && (specifier == .keyword(.willSet) || specifier == .keyword(.didSet))
        }
    }

    var mockSynGetterEffectSpecifiers: String {
        guard case .accessors(let accessors) = self.accessors,
              let getter = accessors.first(where: { $0.accessorSpecifier.tokenKind == .keyword(.get) }) else {
            return ""
        }

        return getter.effectSpecifiers?.description.trimmedEffectSpecifiers ?? ""
    }
}

extension ReturnClauseSyntax? {
    var returnsValue: Bool {
        guard let type = self?.type.description.trimmedSource else {
            return false
        }

        return type != "Void" && type != "()"
    }
}

extension FunctionParameterClauseSyntax {
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

            return GeneratedParameter(
                label: label,
                localName: localName,
                matcherType: typedMatcher,
                isVariadic: parameter.ellipsis != nil
            )
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

struct GeneratedParameter {
    let label: String
    let localName: String
    let matcherType: String
    let isVariadic: Bool

    func matcherParameterSource(generatedName: String) -> String {
        let matcherType = matcherType.resolvingSelf(as: generatedName)
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

extension AttributeListSyntax {
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

extension GenericParameterClauseSyntax {
    var mockSynGenericArgumentClause: String {
        let arguments = parameters.map { parameter in
            parameter.name.text
        }.joined(separator: ", ")

        return "<\(arguments)>"
    }
}

extension String {
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
        switch (hasThrowingEffect, hasAsyncEffect) {
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

    var hasAsyncEffect: Bool {
        range(of: "async") != nil
    }

    var hasThrowingEffect: Bool {
        range(of: "throws") != nil
    }

    var hasRethrowsEffect: Bool {
        range(of: "rethrows") != nil
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

    func resolvingSelf(as generatedName: String) -> String {
        self == "Self" ? generatedName : self
    }

    var mockSynReturnDslSuffix: String {
        let tokens = trimmedSource
            .replacingOccurrences(of: "?", with: " Optional")
            .replacingOccurrences(of: "!", with: " Optional")
            .split { character in
                !character.isLetter && !character.isNumber
            }
            .map(String.init)

        let suffix = tokens
            .map { token in
                let first = token.first!
                return first.uppercased() + token.dropFirst()
            }
            .joined()

        return suffix
    }

    func resolvingParameterSelf(as generatedName: String) -> String {
        replacingOccurrences(of: ": Self", with: ": \(generatedName)")
    }

    func appendingModeParameter(defaultMode: String) -> String {
        let parameter = "mode: MockSynMode = \(defaultMode)"
        let content = dropFirst().dropLast().trimmingCharacters(in: .whitespacesAndNewlines)
        return content.isEmpty ? "(\(parameter))" : "(\(content), \(parameter))"
    }

    func spyInitializerParameterClause(wrappedTypeName: String, mode: String) -> String {
        let prefix = "wrapping __mockSynWrapped: \(wrappedTypeName)"
        let suffix = "mode: MockSynMode = \(mode)"
        let content = dropFirst().dropLast().trimmingCharacters(in: .whitespacesAndNewlines)
        return content.isEmpty ? "(\(prefix), \(suffix))" : "(\(prefix), \(content), \(suffix))"
    }

    var mockSynOperatorDslName: String {
        let aliases = ["==": "equalTo", "!=": "notEqualTo", "<": "lessThan", "<=": "lessThanOrEqualTo", ">": "greaterThan", ">=": "greaterThanOrEqualTo", "+": "plus", "-": "minus", "*": "multiply", "/": "divide", "%": "remainder"]
        if let alias = aliases[self] {
            return alias
        }

        let encoded = unicodeScalars
            .map { "u\(String($0.value, radix: 16))" }
            .joined(separator: "_")
        return "operator_\(encoded)"
    }
}
