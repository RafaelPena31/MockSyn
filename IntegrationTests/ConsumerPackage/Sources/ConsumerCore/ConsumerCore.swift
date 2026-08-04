import ExternalContracts
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

#if MOCKSYN_ENABLE
extension MirroredExternalUserLoadingMock: ExternalUserLoading {}
#endif
