import SwiftParser
import SwiftSyntax
@testable import MockSynMacros
import XCTest

final class MockSynLexicalAccessTests: XCTestCase {
    func testExtensionAccessIsResolvedFromDeclarationParents() throws {
        let source = Parser.parse(source: """
        public extension Services {
            protocol UserService {
            }
        }
        """)
        let extensionDeclaration = try XCTUnwrap(
            source.statements.first?.item.as(ExtensionDeclSyntax.self)
        )
        let protocolDeclaration = try XCTUnwrap(
            extensionDeclaration.memberBlock.members.first?.decl.as(ProtocolDeclSyntax.self)
        )

        XCTAssertEqual(
            MockSynLexicalAccess.extensionAccess(of: Syntax(protocolDeclaration)),
            .public
        )
    }

    func testExtensionAccessDoesNotCrossNominalTypeParent() throws {
        let source = Parser.parse(source: """
        public extension Services {
            struct Scope {
                protocol UserService {
                }
            }
        }
        """)
        let extensionDeclaration = try XCTUnwrap(
            source.statements.first?.item.as(ExtensionDeclSyntax.self)
        )
        let structureDeclaration = try XCTUnwrap(
            extensionDeclaration.memberBlock.members.first?.decl.as(StructDeclSyntax.self)
        )
        let protocolDeclaration = try XCTUnwrap(
            structureDeclaration.memberBlock.members.first?.decl.as(ProtocolDeclSyntax.self)
        )

        XCTAssertNil(MockSynLexicalAccess.extensionAccess(of: Syntax(protocolDeclaration)))
    }
}
