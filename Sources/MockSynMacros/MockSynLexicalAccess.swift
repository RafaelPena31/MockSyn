import SwiftSyntax

enum MockSynLexicalAccess {
    static func extensionAccess(of declaration: Syntax) -> MockSynGeneratedAccess? {
        var ancestor = declaration.parent

        while let current = ancestor {
            if let extensionDeclaration = current.as(ExtensionDeclSyntax.self) {
                return extensionDeclaration.modifiers.mockSynExplicitAccess
            }

            if current.isNominalTypeDeclaration {
                return nil
            }

            ancestor = current.parent
        }

        return nil
    }

    static func extensionAccess(in lexicalContext: [Syntax]) -> MockSynGeneratedAccess? {
        for lexicalNode in lexicalContext {
            if let extensionDeclaration = lexicalNode.as(ExtensionDeclSyntax.self) {
                return extensionDeclaration.modifiers.mockSynExplicitAccess
            }

            if lexicalNode.isNominalTypeDeclaration {
                return nil
            }
        }

        return nil
    }
}

private extension Syntax {
    var isNominalTypeDeclaration: Bool {
        self.is(ActorDeclSyntax.self)
            || self.is(ClassDeclSyntax.self)
            || self.is(EnumDeclSyntax.self)
            || self.is(ProtocolDeclSyntax.self)
            || self.is(StructDeclSyntax.self)
    }
}
