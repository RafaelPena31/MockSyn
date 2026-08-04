import Foundation
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

struct GeneratedInitializer {
    let optionalMark: String
    let parameterClause: String
    let callArguments: String
    let effectSpecifiers: String
    let isRequired: Bool

    func source(access: String, options: MockSynMacroOptions, kind: MockSynPeerMacro.Kind, target: Target) -> String {
        if target.kind == .class {
            return classSource(access: access, options: options, kind: kind, target: target)
        }

        return """
          \(access) init\(optionalMark)\(parameterClause)\(effectSpecifiers) {
        \(target.runtimeInitializationSource(kind: kind, mode: options.mode.sourceName))
          }
        """
    }

    private func classSource(
        access: String,
        options: MockSynMacroOptions,
        kind: MockSynPeerMacro.Kind,
        target: Target
    ) -> String {
        if isRequired {
            return """
              \(access) required init\(optionalMark)\(parameterClause)\(effectSpecifiers) {
                self.__mockSyn = MockSynRuntime(kind: \(kind.runtimeKind), mode: \(options.mode.sourceName))
                \(effectSpecifiers.callPrefix)super.init(\(callArguments))
              }

            \(configurableClassSource(access: access, options: options, kind: kind, target: target))
            """
        }

        return configurableClassSource(access: access, options: options, kind: kind, target: target)
    }

    private func configurableClassSource(
        access: String,
        options: MockSynMacroOptions,
        kind: MockSynPeerMacro.Kind,
        target: Target
    ) -> String {
        if kind == .spy {
            return """
              \(access) init\(optionalMark)\(parameterClause.spyInitializerParameterClause(wrappedTypeName: target.wrappedTypeName, mode: options.mode.sourceName))\(effectSpecifiers) {
                self.__mockSyn = MockSynRuntime(kind: \(kind.runtimeKind), mode: mode)
                self.__mockSynWrapped = __mockSynWrapped
                \(effectSpecifiers.callPrefix)super.init(\(callArguments))
              }
            """
        }

        return """
          \(access) init\(optionalMark)\(parameterClause.appendingModeParameter(defaultMode: options.mode.sourceName))\(effectSpecifiers) {
            self.__mockSyn = MockSynRuntime(kind: \(kind.runtimeKind), mode: mode)
            \(effectSpecifiers.callPrefix)super.init(\(callArguments))
          }
        """
    }
}
