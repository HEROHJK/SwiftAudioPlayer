// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftAudioPlayer",
    platforms: [
        .iOS(.v12)
    ],
    products: [
        .library(
            name: "SwiftAudioPlayer", targets: ["SwiftAudioPlayer"]),
        .library(name: "EasyRemoteCenter", targets: ["EasyRemoteCenter"])
    ],
    dependencies: [
        .package(url: "https://github.com/ReactiveX/RxSwift.git", .upToNextMajor(from: "6.2.0")),
        .package(url: "https://github.com/HEROHJK/HeLogger", .upToNextMajor(from: "1.1.0"))
    ],
    targets: [
        .target(
            name: "SwiftAudioPlayer",
            dependencies: ["RxSwift", "HeLogger"]),
        .target(name: "EasyRemoteCenter",
                dependencies: ["SwiftAudioPlayer", "RxSwift", "HeLogger"]),
        .testTarget(
            name: "SwiftAudioPlayerTests",
            dependencies: ["SwiftAudioPlayer"]),
    ]
)
