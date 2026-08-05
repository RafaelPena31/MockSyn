// swift-tools-version: 5.9

import PackageDescription
import Foundation

let consumerSwiftSettings: [SwiftSetting]
switch ProcessInfo.processInfo.environment["MOCKSYN_CONSUMER_LANGUAGE_MODE"] {
case nil:
    consumerSwiftSettings = []
case "5":
    consumerSwiftSettings = [.unsafeFlags(["-swift-version", "5"])]
case "6":
    consumerSwiftSettings = [.unsafeFlags(["-swift-version", "6"])]
default:
    fatalError("MOCKSYN_CONSUMER_LANGUAGE_MODE must be 5 or 6")
}

let package = Package(
    name: "MockSynConsumerPackage",
    products: [
        .library(name: "ExternalContracts", targets: ["ExternalContracts"]),
        .library(name: "ConsumerCore", targets: ["ConsumerCore"]),
    ],
    dependencies: [
        .package(path: "../.."),
        .package(url: "https://github.com/Quick/Quick.git", exact: "7.6.2"),
        .package(url: "https://github.com/Quick/Nimble.git", exact: "13.8.0"),
    ],
    targets: [
        .target(
            name: "ExternalContracts",
            swiftSettings: consumerSwiftSettings
        ),
        .target(
            name: "ConsumerCore",
            dependencies: [
                "ExternalContracts",
                .product(name: "MockSyn", package: "MockSyn"),
            ],
            swiftSettings: [
                .define("MOCKSYN_ENABLE", .when(configuration: .debug)),
            ] + consumerSwiftSettings
        ),
        .testTarget(
            name: "ConsumerCoreTests",
            dependencies: [
                "ConsumerCore",
                "ExternalContracts",
                .product(name: "MockSyn", package: "MockSyn"),
                .product(name: "Quick", package: "Quick"),
                .product(name: "Nimble", package: "Nimble"),
            ],
            swiftSettings: consumerSwiftSettings
        ),
    ],
    swiftLanguageVersions: [.v5, .version("6")]
)
