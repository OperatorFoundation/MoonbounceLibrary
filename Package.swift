// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MoonbounceLibrary",
    platforms: [.macOS(.v12),
                .iOS(.v15)],
    products: [
        .library(
            name: "MoonbounceLibrary",
            targets: ["MoonbounceLibrary"]),
        .library(
            name: "MoonbounceNetworkExtensionLibrary",
            targets: ["MoonbounceNetworkExtensionLibrary"]),
        .library(
            name: "MoonbounceShared",
            targets: ["MoonbounceShared"]),
    ],
    dependencies: [
        .package(url: "https://github.com/OperatorFoundation/Chord.git", branch: "main"),
        .package(url: "https://github.com/OperatorFoundation/Datable", branch: "main"),
        .package(url: "https://github.com/OperatorFoundation/Flower.git", branch: "main"),
        .package(url: "https://github.com/OperatorFoundation/InternetProtocols.git", branch: "main"),
        .package(url: "https://github.com/OperatorFoundation/KeychainCli.git", branch: "main"),
        .package(url: "https://github.com/OperatorFoundation/Net.git", branch: "main"),
        .package(url: "https://github.com/OperatorFoundation/ShadowSwift.git", branch: "main"),
        .package(url: "https://github.com/OperatorFoundation/Spacetime", branch: "main"),
        .package(url: "https://github.com/OperatorFoundation/SwiftHexTools.git", branch: "main"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.4.2"),
        .package(url: "https://github.com/OperatorFoundation/SwiftQueue.git", branch: "main"),
        .package(url: "https://github.com/OperatorFoundation/Transmission.git", branch: "main"),
        .package(url: "https://github.com/OperatorFoundation/TransmissionTransport.git", branch: "main"),
        .package(url: "https://github.com/OperatorFoundation/Transport.git", branch: "main"),
    ],
    targets: [
        .target(
            name: "MoonbounceLibrary",
            dependencies: [
                "Chord",
                "Datable",
                "Flower",
                "InternetProtocols",
                .product(name: "Logging", package: "swift-log"),
                "MoonbounceShared",
                "Net",
                "ShadowSwift",
                .product(name: "Simulation", package: "Spacetime"),
                .product(name: "Spacetime", package: "Spacetime"),
                "SwiftHexTools",
                "SwiftQueue",
                "TransmissionTransport",
                "Transport",
                .product(name: "Universe", package: "Spacetime"),
            ]),
        .target(
            name: "MoonbounceNetworkExtensionLibrary",
            dependencies: [
                "MoonbounceShared",
                .product(name: "Logging", package: "swift-log"),
                "Net",
                "ShadowSwift",
                .product(name: "Simulation", package: "Spacetime"),
                .product(name: "Spacetime", package: "Spacetime"),
                .product(name: "Universe", package: "Spacetime"),
                "SwiftQueue",
                "Flower",
                "Transmission",
                "InternetProtocols",
            ]),
        .target(
            name: "MoonbounceShared",
            dependencies: [
                .product(name: "Logging", package: "swift-log"),
                "Net",
            ]),
        .testTarget(
            name: "MoonbounceLibraryTests",
            dependencies: ["MoonbounceLibrary", "MoonbounceNetworkExtensionLibrary", "KeychainCli"]),
    ],
    swiftLanguageVersions: [.v5]
)
