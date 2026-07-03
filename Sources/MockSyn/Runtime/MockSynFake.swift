/// Shared helpers for hand-written fakes that want MockSyn recording and verification.
public protocol MockSynFake: AnyObject {
    /// Runtime state owned by the fake.
    var __mockSyn: MockSynRuntime { get }
}

public extension MockSynFake {
    /// Records a fake member call using the same runtime model as generated doubles.
    func mockSynRecord(member: String, arguments: [Any] = []) {
        __mockSyn.record(member: member, arguments: arguments)
    }

    /// Builds a verification query for a manually recorded fake member.
    func mockSynVerification(member: String, matchers: [MockSynAnyMatcher] = []) -> MockSynVerification {
        MockSynVerification(runtime: __mockSyn, member: member, matchers: matchers)
    }

    /// Fails when the fake has recorded calls that were not verified.
    func mockSynConfirmVerified() throws {
        try __mockSyn.confirmVerified()
    }

    /// Fails when the fake has configured stubs that were not used.
    func mockSynCheckUnnecessaryStubs() throws {
        try __mockSyn.checkUnnecessaryStubs()
    }
}
