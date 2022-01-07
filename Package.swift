// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MoonbounceLibrary",
    platforms: [.macOS(.v10_15)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
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
        .package(url: "https://github.com/weichsel/ZIPFoundation.git", from: "0.9.11"),
        .package(url: "https://github.com/OperatorFoundation/Datable", branch: "main"),
        .package(url: "https://github.com/OperatorFoundation/SwiftQueue.git", branch: "main"),
        .package(url: "https://github.com/OperatorFoundation/Flower.git", branch: "main"),
        .package(url: "https://github.com/OperatorFoundation/Transport.git", from: "2.3.12"),
        .package(url: "https://github.com/OperatorFoundation/Transmission.git", from: "1.2.10"),
        .package(url: "https://github.com/OperatorFoundation/InternetProtocols.git", branch: "main"),
        .package(url: "https://github.com/OperatorFoundation/SwiftHexTools.git", branch: "main"),
        .package(url: "https://github.com/OperatorFoundation/ReplicantSwift.git", branch: "main"),
        .package(url: "https://github.com/OperatorFoundation/ReplicantSwiftClient.git", branch: "main"),
        .package(url: "https://github.com/OperatorFoundation/TransmissionTransport.git", branch: "main"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.4.2"),
        .package(url: "https://github.com/OperatorFoundation/LoggerQueue.git", branch: "main"),
        .package(url: "https://github.com/OperatorFoundation/Chord.git", branch: "main"),
        .package(url: "https://github.com/OperatorFoundation/Net.git", branch: "main"),
        .package(url: "https://github.com/OperatorFoundation/TunnelClient.git", branch: "main"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "MoonbounceLibrary",
            dependencies: [
                "MoonbounceShared",
                "ZIPFoundation",
                "Datable",
                "SwiftQueue",
                "Flower",
                "Transport",
                "InternetProtocols",
                "SwiftHexTools",
                "ReplicantSwift",
                "TransmissionTransport",
                "ReplicantSwiftClient",
                .product(name: "Logging", package: "swift-log"),
                "LoggerQueue",
                "Chord",
                "Net",
                "TunnelClient",
                .product(name: "TunnelClientMock", package: "TunnelClient")
            ]),
        .target(
            name: "MoonbounceNetworkExtensionLibrary",
            dependencies: [
                "MoonbounceShared",
                .product(name: "Logging", package: "swift-log"),
                "Net",
                "ReplicantSwiftClient",
                "ReplicantSwift",
                "SwiftQueue",
                "LoggerQueue",
                "Flower",
                "Transmission",
                "InternetProtocols",
                "TunnelClient",
            ]),
        .target(
            name: "MoonbounceShared",
            dependencies: [
                .product(name: "Logging", package: "swift-log"),
                "Net",
                "ReplicantSwiftClient",
                "ReplicantSwift",
                "TunnelClient",
            ]),
        .testTarget(
            name: "MoonbounceLibraryTests",
            dependencies: ["MoonbounceLibrary"]),
    ],
    swiftLanguageVersions: [.v5]
)
