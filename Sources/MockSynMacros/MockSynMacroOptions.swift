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

    var generatedMemberSourceName: String {
        self == .private ? MockSynGeneratedAccess.fileprivate.rawValue : rawValue
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

enum MockSynAccessOption: Equatable {
    case inherited
    case explicit(MockSynGeneratedAccess)

    init?(sourceName: String) {
        guard let keyword = MockSynAccessKeyword(rawValue: sourceName) else {
            return nil
        }

        switch keyword {
        case .inherited:
            self = .inherited
        case .private:
            self = .explicit(.private)
        case .fileprivate:
            self = .explicit(.fileprivate)
        case .internal:
            self = .explicit(.internal)
        case .package:
            self = .explicit(.package)
        case .public:
            self = .explicit(.public)
        }
    }

    func resolved(for declarationAccess: MockSynGeneratedAccess) -> MockSynGeneratedAccess {
        switch self {
        case .inherited:
            return declarationAccess
        case .explicit(let access):
            return access
        }
    }
}

private enum MockSynAccessKeyword: String {
    case inherited
    case `private`
    case `fileprivate`
    case `internal`
    case `package`
    case `public`
}

struct MockSynMacroOptions {
    var name: String?
    var access: MockSynAccessOption
    var mode: MockSynGeneratedMode

    static func parse(
        from attribute: AttributeSyntax,
        defaultMode: MockSynGeneratedMode
    ) throws -> MockSynMacroOptions {
        var options = MockSynMacroOptions(name: nil, access: .inherited, mode: defaultMode)

        guard case .argumentList(let arguments) = attribute.arguments else {
            return options
        }

        for argument in arguments {
            if argument.label?.text == "name" {
                options.name = argument.expression.as(StringLiteralExprSyntax.self)?.representedLiteralValue
            } else if argument.label?.text == "access" {
                let accessName = argument.expression.memberAccessName
                guard let accessName, let access = MockSynAccessOption(sourceName: accessName) else {
                    throw MockSynDiagnostic.invalidAccess
                }
                options.access = access
            } else if argument.label?.text == "mode" {
                let modeName = argument.expression.memberAccessName
                guard let modeName, let mode = MockSynGeneratedMode(rawValue: modeName) else {
                    throw MockSynDiagnostic.invalidMode
                }
                options.mode = mode
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
    var mockSynExplicitAccess: MockSynGeneratedAccess? {
        for modifier in self {
            switch modifier.name.tokenKind {
            case .keyword(.public), .keyword(.open):
                return .public
            case .keyword(.package):
                return .package
            case .keyword(.fileprivate):
                return .fileprivate
            case .keyword(.private):
                return .private
            case .keyword(.internal):
                return .internal
            default:
                continue
            }
        }

        return nil
    }

    var mockSynAccess: MockSynGeneratedAccess {
        mockSynExplicitAccess ?? .internal
    }

    var finalModifier: DeclModifierSyntax? {
        first { $0.name.tokenKind == .keyword(.final) }
    }

    var removingFinal: DeclModifierListSyntax {
        filter { $0.name.tokenKind != .keyword(.final) }
    }

    var leadingTriviaRemovedWithFinal: Trivia? {
        guard first?.name.tokenKind == .keyword(.final) else {
            return nil
        }

        return first?.name.leadingTrivia
    }
}
