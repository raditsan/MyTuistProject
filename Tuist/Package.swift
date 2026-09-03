// swift-tools-version: 6.0
import PackageDescription

#if TUIST
    import struct ProjectDescription.PackageSettings

    let packageSettings = PackageSettings(
        productTypes: [
            "FactoryKit": .framework,
        ]
    )
#endif

let package = Package(
    name: "MyTuistProject",
    dependencies: [
        .package(url: "https://github.com/hmlongco/Factory.git", from: "2.5.0"),
    ]
)
