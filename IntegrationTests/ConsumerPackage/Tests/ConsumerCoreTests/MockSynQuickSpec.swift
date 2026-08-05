import ConsumerCore
import MockSyn
import Nimble
import Quick

private let quickFailureRecorder = ConsumerFailureRecorder()

final class MockSynQuickSpec: QuickSpec {
    override class func spec() {
        beforeEach {
            quickFailureRecorder.reset()
            MockSynRuntime.resetAllGlobalState()
        }

        afterEach {
            MockSynRuntime.resetAllGlobalState()
            quickFailureRecorder.reset()
        }

        describe("MockSyn public failure reporting") {
            it("delivers recoverable strict failures to Quick and Nimble") {
                MockSynFailureReporter.useXCTest { message, file, line in
                    quickFailureRecorder.record(MockSynFailure(message: message, file: file, line: line))
                }

                let value = PublicUserLoadingMock().loadUser(id: "quick-user")
                let messages = quickFailureRecorder.failures.map(\.message).joined(separator: "\n")

                expect(value).to(equal(""))
                expect(messages).to(contain("loadUser(id:)"))
                expect(messages).to(contain("quick-user"))
            }

            it("resets its own failure handler and static runtime") {
                MockSynFailureReporter.useXCTest { message, file, line in
                    quickFailureRecorder.record(MockSynFailure(message: message, file: file, line: line))
                }
                PublicBuildInformationMock.given.revision().willReturn(7)
                expect(PublicBuildInformationMock.revision()).to(equal(7))

                MockSynRuntime.resetAllGlobalState()
                MockSynFailureReporter.report(MockSynFailure(message: "handler must be reset"))

                expect(PublicBuildInformationMock.revision()).to(equal(0))
                expect(quickFailureRecorder.failures).to(beEmpty())
            }
        }
    }
}
