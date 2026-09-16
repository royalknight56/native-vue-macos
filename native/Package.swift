// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "NativeVueMacOS",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "NativeVueMacOS", targets: ["NativeVueMacOS"]),
        .executable(name: "NativeVueHost", targets: ["NativeVueHost"])
    ],
    targets: [
        .target(
            name: "NativeVueMacOS",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("JavaScriptCore")
            ]
        ),
        .executableTarget(
            name: "NativeVueHost",
            dependencies: ["NativeVueMacOS"]
        ),
        .testTarget(
            name: "NativeVueMacOSTests",
            dependencies: ["NativeVueMacOS"]
        )
    ],
    swiftLanguageVersions: [.v5]
)
