// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "Oganesson",
    platforms: [
        .iOS(.v9),
    ],
    products: [
        .library(name: "Oganesson", targets: ["Oganesson"])
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "Oganesson",
            dependencies: [
            ],
            path: "Sources"
        )
    ],
    swiftLanguageVersions: [ .v5 ]
)
