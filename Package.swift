// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "CognetSDK",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "CognetSDK",
            targets: ["CognetSDK"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/airbnb/lottie-ios.git", from: "5.0.0")
    ],
    targets: [
        .target(
            name: "CognetSDK",
            dependencies: ["Lottie"],
            resources: [
                .process("Assets.xcassets"),
                .process("LottieFiles")
            ]
        ),
        .testTarget(
            name: "CognetSDKTests",
            dependencies: ["CognetSDK"]
        )
    ]
)
