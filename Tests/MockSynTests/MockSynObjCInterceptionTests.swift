import MockSyn
import Foundation
import XCTest
#if canImport(ObjectiveC)
import ObjectiveC.runtime

extension MockSynPublicAPITests {
    func testObjCInterceptionReplacesAndRestoresInstanceMethod() throws {
        let replacement: @convention(block) (AnyObject) -> NSString = { _ in "mock" }
        let interception = try MockSynObjCInterception.replaceInstanceMethod(
            on: ObjCLegacyService.self,
            selector: #selector(ObjCLegacyService.greeting),
            with: replacement
        )

        XCTAssertEqual(ObjCLegacyService().greeting(), "mock")

        interception.restore()
        interception.restore()

        XCTAssertEqual(ObjCLegacyService().greeting(), "real")
    }

    func testObjCInterceptionRestoresInstanceMethodOnDeinit() throws {
        do {
            let replacement: @convention(block) (AnyObject) -> NSString = { _ in "scoped" }
            let interception = try MockSynObjCInterception.replaceInstanceMethod(
                on: ObjCLegacyService.self,
                selector: #selector(ObjCLegacyService.greeting),
                with: replacement
            )
            XCTAssertEqual(ObjCLegacyService().greeting(), "scoped")
            _ = interception
        }

        XCTAssertEqual(ObjCLegacyService().greeting(), "real")
    }

    func testObjCInterceptionReplacesAndRestoresClassMethod() throws {
        let replacement: @convention(block) (AnyClass) -> NSString = { _ in "mock-class" }
        let interception = try MockSynObjCInterception.replaceClassMethod(
            on: ObjCLegacyService.self,
            selector: #selector(ObjCLegacyService.build),
            with: replacement
        )

        XCTAssertEqual(ObjCLegacyService.build(), "mock-class")

        interception.restore()

        XCTAssertEqual(ObjCLegacyService.build(), "real-class")
    }

    func testObjCInterceptionReportsMissingMethod() {
        XCTAssertThrowsError(try MockSynObjCInterception.replaceInstanceMethod(
            on: ObjCLegacyService.self,
            selector: NSSelectorFromString("missingSelector"),
            with: ({ _ in "unused" } as @convention(block) (AnyObject) -> NSString)
        )) { error in
            XCTAssertEqual(
                String(describing: error),
                "MockSyn could not find Objective-C instance method missingSelector on ObjCLegacyService."
            )
        }
    }

    func testObjCInterceptionReportsMissingClassMethod() {
        XCTAssertThrowsError(try MockSynObjCInterception.replaceClassMethod(
            on: ObjCLegacyService.self,
            selector: NSSelectorFromString("missingClassSelector"),
            with: ({ _ in "unused" } as @convention(block) (AnyClass) -> NSString)
        )) { error in
            XCTAssertEqual(
                String(describing: error),
                "MockSyn could not find Objective-C class method missingClassSelector on ObjCLegacyService."
            )
        }
    }
}
#endif
