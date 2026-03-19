// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "VimText",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "VimText",
            path: "VimText",
            exclude: [
                "Info.plist",
                "VimText.entitlements"
            ],
            resources: [
                .process("Assets.xcassets")
            ]
        )
    ]
)
