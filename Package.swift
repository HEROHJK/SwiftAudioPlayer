// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftAudioPlayer",
    platforms: [
        .iOS(.v12)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "SwiftAudioPlayer",
            targets: ["SwiftAudioPlayer"]),
    ],
    dependencies: [
        .package(url: "https://github.com/ReactiveX/RxSwift.git", .upToNextMajor(from: "6.2.0")),
        .package(url: "https://github.com/HEROHJK/HeLogger", .upToNextMajor(from: "1.1.0"))
    ],
    targets: [
        .target(
            name: "SwiftAudioPlayer",
            dependencies: ["RxSwift", "HeLogger"]),
        .testTarget(
            name: "SwiftAudioPlayerTests",
            dependencies: ["SwiftAudioPlayer"]),
    ]
)
