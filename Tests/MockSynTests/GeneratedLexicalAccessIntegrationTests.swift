import MockSyn
import XCTest

public enum GeneratedPublicLexicalServices {
}

public extension GeneratedPublicLexicalServices {
    @Mocking
    protocol Service {
        func value() -> String
    }
}

package enum GeneratedPackageLexicalServices {
}

package extension GeneratedPackageLexicalServices {
    @Stubbing
    protocol Service {
        func value() -> String
    }
}

enum GeneratedFileLexicalServices {
}

fileprivate extension GeneratedFileLexicalServices {
    @Spying
    protocol Service {
        func value() -> String
    }

    struct Implementation: Service {
        func value() -> String {
            "wrapped"
        }
    }
}

enum GeneratedPrivateLexicalServices {
}

private extension GeneratedPrivateLexicalServices {
    @Mocking
    protocol Service {
        func value() -> String
    }
}

extension MockSynGeneratedTypeIntegrationTests {
    func testGeneratedTypesCompileInsideAccessControlledExtensions() {
        #if MOCKSYN_ENABLE
        let publicMock = GeneratedPublicLexicalServices.ServiceMock()
        publicMock.given.value().willReturn("public")

        let packageStub = GeneratedPackageLexicalServices.ServiceStub()
        let fileprivateSpy = GeneratedFileLexicalServices.ServiceSpy(
            wrapping: GeneratedFileLexicalServices.Implementation()
        )
        XCTAssertEqual(publicMock.value(), "public")
        XCTAssertEqual(packageStub.value(), "")
        XCTAssertEqual(fileprivateSpy.value(), "wrapped")
        #else
        XCTFail("MOCKSYN_ENABLE must be active for generated test doubles")
        #endif
    }
}
