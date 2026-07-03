import SwiftSyntax

enum MockSynGeneratedAccess: String, Comparable {
    case `private`
    case `fileprivate`
    case `internal`
    case `package`
    case `public`

    static func < (lhs: MockSynGeneratedAccess, rhs: MockSynGeneratedAccess) -> Bool {
        lhs.rank < rhs.rank
    }

    var sourceName: String {
        rawValue
    }

    private var rank: Int {
        switch self {
        case .private:
            return 0
        case .fileprivate:
            return 1
        case .internal:
            return 2
        case .package:
            return 3
        case .public:
            return 4
        }
    }
}

enum MockSynGeneratedMode: String {
    case strict
    case relaxed

    var sourceName: String {
        ".\(rawValue)"
    }
}

struct MockSynMacroOptions {
    var name: String?
    var access: MockSynGeneratedAccess
    var mode: MockSynGeneratedMode

    static func parse(
        from attribute: AttributeSyntax,
        defaultAccess: MockSynGeneratedAccess,
        defaultMode: MockSynGeneratedMode
    ) throws -> MockSynMacroOptions {
        var options = MockSynMacroOptions(name: nil, access: defaultAccess, mode: defaultMode)

        guard case .argumentList(let arguments) = attribute.arguments else {
            return options
        }

        for argument in arguments {
            if argument.label?.text == "name" {
                options.name = argument.expression.as(StringLiteralExprSyntax.self)?.representedLiteralValue
            } else if argument.label?.text == "access" {
                let accessName = argument.expression.memberAccessName
                guard let accessName, let access = MockSynGeneratedAccess(rawValue: accessName) else {
                    throw MockSynDiagnostic.invalidAccess
                }
                options.access = access
            } else if argument.label?.text == "mode" {
                let modeName = argument.expression.memberAccessName
                if let modeName, let mode = MockSynGeneratedMode(rawValue: modeName) {
                    options.mode = mode
                }
            }
        }

        return options
    }
}

extension ExprSyntax {
    fileprivate var memberAccessName: String? {
        if let memberAccess = self.as(MemberAccessExprSyntax.self) {
            return memberAccess.declName.baseName.text
        }

        return nil
    }
}

extension DeclModifierListSyntax {
    var mockSynAccess: MockSynGeneratedAccess {
        if contains(where: { $0.name.tokenKind == .keyword(.public) }) {
            return .public
        }

        if contains(where: { $0.name.tokenKind == .keyword(.package) }) {
            return .package
        }

        if contains(where: { $0.name.tokenKind == .keyword(.fileprivate) }) {
            return .fileprivate
        }

        if contains(where: { $0.name.tokenKind == .keyword(.private) }) {
            return .private
        }

        return .internal
    }

    var containsFinal: Bool {
        contains { $0.name.tokenKind == .keyword(.final) }
    }
}
