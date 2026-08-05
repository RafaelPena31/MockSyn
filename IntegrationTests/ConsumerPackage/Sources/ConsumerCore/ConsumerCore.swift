import MockSyn

@Mocking
public protocol PublicUserLoading {
    func loadUser(id: String) -> String
}

@Mocking
public protocol MirroredExternalUserLoading {
    func loadUser(id: String) -> String
}

@Mocking
public protocol PublicBuildInformation {
    static func revision() -> Int
}
