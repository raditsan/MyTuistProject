// swift-tools-version: 6.0
import PackageDescription

#if TUIST
    import struct ProjectDescription.PackageSettings
    import struct ProjectDescription.Settings
    import struct ProjectDescription.Configuration

    let packageSettings = PackageSettings(
        productTypes: [
            "FactoryKit": .framework,
            "Moya": .framework,
            "CombineMoya": .framework,
            "Alamofire": .framework,
        ],
        baseSettings: .settings(
            configurations: [
                .debug(name: "Debug-Dev"),
                .release(name: "Release-Dev"),
                .debug(name: "Debug-UAT"),
                .release(name: "Release-UAT"),
                .debug(name: "Debug-Prod"),
                .release(name: "Release-Prod"),
            ]
        )
    )
#endif

let package = Package(
    name: "MyTuistProject",
    dependencies: [
        .package(url: "https://github.com/hmlongco/Factory.git", from: "2.5.0"),
        .package(url: "https://github.com/Moya/Moya.git", from: "15.0.3"),
    ]
)
