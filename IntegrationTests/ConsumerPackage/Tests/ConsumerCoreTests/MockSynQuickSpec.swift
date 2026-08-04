import ConsumerCore
import MockSyn
import Nimble
import Quick

private let quickFailureRecorder = ConsumerFailureRecorder()

final class MockSynQuickSpec: QuickSpec {
    override class func spec() {
        beforeSuite {
            quickFailureRecorder.reset()
            MockSynRuntime.resetAllGlobalState()
        }

        afterEach {
            MockSynRuntime.resetAllGlobalState()
        }

        describe("MockSyn public failure reporting") {
            it("delivers recoverable strict failures to Quick and Nimble") {
                MockSynFailureReporter.setHandler { failure in
                    quickFailureRecorder.record(failure)
                }
                PublicBuildInformationMock.given.revision().willReturn(7)

                let value = PublicUserLoadingMock().loadUser(id: "quick-user")
                let messages = quickFailureRecorder.failures.map(\.message).joined(separator: "\n")

                expect(value).to(equal(""))
                expect(messages).to(contain("loadUser(id:)"))
                expect(messages).to(contain("quick-user"))
                expect(PublicBuildInformationMock.revision()).to(equal(7))
            }

            it("observes global state cleared by the preceding teardown") {
                MockSynFailureReporter.report(MockSynFailure(message: "handler must be reset"))

                expect(quickFailureRecorder.failures).to(haveCount(1))
                expect(PublicBuildInformationMock.revision()).to(equal(0))
            }
        }
    }
}
