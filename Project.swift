import ProjectDescription

let project = Project(
    name: "MyTuistProject",
    targets: [
        .target(
            name: "MyTuistProject",
            destinations: .iOS,
            product: .app,
            bundleId: "dev.tuist.MyTuistProject",
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchScreen": [
                        "UIColorName": "",
                        "UIImageName": "",
                    ],
                ]
            ),
            buildableFolders: [
                "MyTuistProject/Sources",
                "MyTuistProject/Resources",
            ],
            dependencies: []
        ),
        .target(
            name: "MyTuistProjectTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "dev.tuist.MyTuistProjectTests",
            infoPlist: .default,
            buildableFolders: [
                "MyTuistProject/Tests"
            ],
            dependencies: [.target(name: "MyTuistProject")]
        ),
    ]
)
