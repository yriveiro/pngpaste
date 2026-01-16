// swift-tools-version: 6.2

import PackageDescription

let package = Package(
  name: "pngpaste",
  platforms: [
    .macOS(.v15)
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-argument-parser", from: "1.5.0")
  ],
  targets: [
    .executableTarget(
      name: "pngpaste",
      dependencies: [
        .product(name: "ArgumentParser", package: "swift-argument-parser")
      ],
      swiftSettings: [
        .swiftLanguageMode(.v6),
        .enableExperimentalFeature("StrictMemorySafety"),
      ]
    ),
    .testTarget(
      name: "pngpasteTests",
      dependencies: [
        "pngpaste"
      ],
      swiftSettings: [
        .swiftLanguageMode(.v6),
        .enableExperimentalFeature("StrictMemorySafety"),
      ]
    ),
  ]
)
