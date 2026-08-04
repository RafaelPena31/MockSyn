import Foundation
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

struct Target {
    let kind: TargetKind
    let name: String
    let access: MockSynGeneratedAccess
    let attributes: String
    let genericParameterClause: String
    let genericArgumentClause: String
    let genericWhereClause: String
    let associatedTypes: [AssociatedTypeBinding]
    let spyWrappedTypeName: String?
    let isObservableObject: Bool
    let members: [GeneratedMember]

    init(
        kind: TargetKind,
        name: String,
        access: MockSynGeneratedAccess,
        attributes: String,
        genericParameterClause: String,
        genericArgumentClause: String,
        genericWhereClause: String,
        associatedTypes: [AssociatedTypeBinding],
        spyWrappedTypeName: String?,
        isObservableObject: Bool,
        members: [GeneratedMember]
    ) {
        self.kind = kind
        self.name = name
        self.access = access
        self.attributes = attributes
        self.genericParameterClause = genericParameterClause
        self.genericArgumentClause = genericArgumentClause
        self.genericWhereClause = genericWhereClause
        self.associatedTypes = associatedTypes
        self.spyWrappedTypeName = spyWrappedTypeName
        self.isObservableObject = isObservableObject
        self.members = members.mockSynDisambiguatingReturnTypeOverloads()
    }

    var inheritedTypeName: String {
        switch kind {
        case .protocol:
            return name
        case .class:
            return "\(name)\(genericArgumentClause)"
        }
    }

    var wrappedTypeName: String {
        switch kind {
        case .protocol:
            return spyWrappedTypeName ?? "any \(name)"
        case .class:
            return inheritedTypeName
        }
    }

    var hasStaticMembers: Bool {
        members.contains { $0.isStatic }
    }

    var hasInitializerMembers: Bool {
        members.contains { member in
            if case .initializer = member {
                return true
            }

            return false
        }
    }

    func primaryInitializerSource(access: String, kind doubleKind: MockSynPeerMacro.Kind, mode: String) -> String {
        if kind == .class, hasInitializerMembers {
            return ""
        }

        if doubleKind == .spy {
            let superInitLine = kind == .class ? "\n    super.init()" : ""
            return """
              \(access) init(wrapping __mockSynWrapped: \(wrappedTypeName), mode: MockSynMode = \(mode)) {
            \(runtimeInitializationSource(kind: doubleKind, mode: "mode"))
                self.__mockSynWrapped = __mockSynWrapped\(superInitLine)
              }
            """
        }

        let superInitLine = kind == .class ? "\n    super.init()" : ""
        return """
          \(access) init(mode: MockSynMode = \(mode)) {
        \(runtimeInitializationSource(kind: doubleKind, mode: "mode"))\(superInitLine)
          }
        """
    }

    func observableObjectPublisherSource(access: String) -> String {
        guard isObservableObject else {
            return ""
        }

        return "  \(access) let objectWillChange: MockSynObservableObjectPublisher\n"
    }

    func runtimeInitializationSource(kind: MockSynPeerMacro.Kind, mode: String) -> String {
        guard isObservableObject else {
            return "    self.__mockSyn = MockSynRuntime(kind: \(kind.runtimeKind), mode: \(mode))"
        }

        return """
            let __mockSynObjectWillChange = MockSynObservableObjectPublisher()
            self.objectWillChange = __mockSynObjectWillChange
            self.__mockSyn = MockSynRuntime(kind: \(kind.runtimeKind), mode: \(mode), onChange: {
              __mockSynObjectWillChange.send()
            })
        """
    }

    func associatedTypeSource(access: String) -> String {
        guard !associatedTypes.isEmpty else {
            return ""
        }

        let typealiasAccess = access == "private" ? "fileprivate" : access
        return associatedTypes
            .map { "  \(typealiasAccess) typealias \($0.name) = \($0.name)" }
            .joined(separator: "\n") + "\n"
    }

    func staticRuntimeSource(access: String, kind: MockSynPeerMacro.Kind, mode: String) -> String {
        guard hasStaticMembers else {
            return ""
        }

        return "  \(access) static let __mockSynStatic = MockSynRuntime(kind: \(kind.runtimeKind), mode: \(mode))\n"
    }

    func staticStubbingSource(access: String, generatedName: String) -> String {
        let stubbingMemberSources = members
            .compactMap { $0.staticStubbingSource(access: access, generatedName: generatedName) }
            .joined(separator: "\n\n")
        let verificationMemberSources = members
            .compactMap { $0.staticVerificationSource(access: access, generatedName: generatedName) }
            .joined(separator: "\n\n")

        guard !stubbingMemberSources.isEmpty || !verificationMemberSources.isEmpty else {
            return ""
        }

        return """

          \(access) static var given: __MockSynStaticGiven {
            __MockSynStaticGiven(__mockSyn: __mockSynStatic)
          }

          \(access) static var when: __MockSynStaticGiven {
            given
          }

          \(access) static var verify: __MockSynStaticVerify {
            __MockSynStaticVerify(__mockSyn: __mockSynStatic)
          }

          \(access) static func confirmStaticVerified() throws {
            try __mockSynStatic.confirmVerified()
          }

          \(access) static func checkUnnecessaryStaticStubs() throws {
            try __mockSynStatic.checkUnnecessaryStubs()
          }

          \(access) static func resetStatic(_ scope: MockSynResetScope = .all) {
            __mockSynStatic.reset(scope)
          }

          \(access) struct __MockSynStaticGiven {
            \(access) let __mockSyn: MockSynRuntime

        \(stubbingMemberSources)
          }

          \(access) struct __MockSynStaticVerify {
            \(access) let __mockSyn: MockSynRuntime

        \(verificationMemberSources)
          }
        """
    }

    func stubbingSource(access: String, generatedName: String) -> String {
        let stubbingMemberSources = members
            .compactMap { $0.stubbingSource(access: access, generatedName: generatedName) }
            .joined(separator: "\n\n")
        let verificationMemberSources = members
            .compactMap { $0.verificationSource(access: access, generatedName: generatedName) }
            .joined(separator: "\n\n")

        guard !stubbingMemberSources.isEmpty || !verificationMemberSources.isEmpty else {
            return ""
        }

        return """

          \(access) var given: __MockSynGiven {
            __MockSynGiven(__mockSyn: __mockSyn)
          }

          \(access) var when: __MockSynGiven {
            given
          }

          \(access) var verify: __MockSynVerify {
            __MockSynVerify(__mockSyn: __mockSyn)
          }

          \(access) func confirmVerified() throws {
            try __mockSyn.confirmVerified()
          }

          \(access) func checkUnnecessaryStubs() throws {
            try __mockSyn.checkUnnecessaryStubs()
          }

          \(access) func reset(_ scope: MockSynResetScope = .all) {
            __mockSyn.reset(scope)
          }

          \(access) struct __MockSynGiven {
            \(access) let __mockSyn: MockSynRuntime

        \(stubbingMemberSources)
          }

          \(access) struct __MockSynVerify {
            \(access) let __mockSyn: MockSynRuntime

        \(verificationMemberSources)
          }
        """
    }
}

enum TargetKind {
    case `protocol`
    case `class`
}

struct ProtocolGenericConfiguration {
    let genericParameterClause: String
    let genericWhereClause: String
    let spyWrappedTypeName: String?

    init(
        protocolName: String,
        associatedTypes: [AssociatedTypeBinding],
        kind: MockSynPeerMacro.Kind
    ) {
        var genericParameters = associatedTypes.map(\.genericParameterSource)
        var whereRequirements = associatedTypes.flatMap(\.whereRequirements)
        let wrappedTypeName: String?

        if kind == .spy, !associatedTypes.isEmpty {
            wrappedTypeName = "__MockSynWrapped"
            genericParameters.append("__MockSynWrapped: \(protocolName)")
            whereRequirements.append(contentsOf: associatedTypes.map { "__MockSynWrapped.\($0.name) == \($0.name)" })
        } else {
            wrappedTypeName = nil
        }

        self.genericParameterClause = genericParameters.isEmpty ? "" : "<\(genericParameters.joined(separator: ", "))>"
        self.genericWhereClause = whereRequirements.isEmpty ? "" : " where \(whereRequirements.joined(separator: ", "))"
        self.spyWrappedTypeName = wrappedTypeName
    }
}

struct AssociatedTypeBinding {
    let name: String
    let genericParameterSource: String
    let whereRequirements: [String]
}

extension ProtocolDeclSyntax {
    var associatedTypeBindings: [AssociatedTypeBinding] {
        memberBlock.members.compactMap { item in
            guard let associatedType = item.decl.as(AssociatedTypeDeclSyntax.self) else {
                return nil
            }

            let name = associatedType.name.text
            let inheritedTypes = associatedType.inheritanceClause?.inheritedTypes.map {
                $0.type.description.trimmedSource
            } ?? []
            let genericParameterSource = inheritedTypes.isEmpty
                ? name
                : "\(name): \(inheritedTypes.joined(separator: " & "))"
            let whereRequirements = associatedType.genericWhereClause?.requirements.map {
                $0.description.trimmedSource
            } ?? []

            return AssociatedTypeBinding(
                name: name,
                genericParameterSource: genericParameterSource,
                whereRequirements: whereRequirements
            )
        }
    }
}
