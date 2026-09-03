import ProjectDescription

let project = Project(
    name: "MyTuistProject",
    targets: [
        // MARK: - App Target (Composition Root)
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
                    "CFBundleURLTypes": [
                        [
                            "CFBundleURLName": "dev.tuist.MyTuistProject",
                            "CFBundleURLSchemes": ["mytuist"],
                        ],
                    ],
                ]
            ),
            sources: [
                "MyTuistProject/Sources/**"
            ],
            resources: [
                "MyTuistProject/Resources/**"
            ],
            dependencies: [
                .external(name: "FactoryKit"),
                .target(name: "FeatureSplash"),
                .target(name: "FeatureDeeplinkLoader"),
                .target(name: "FeatureProduct"),
                .target(name: "FeatureProductDetail"),
                .target(name: "DomainProduct"),
                .target(name: "DataProduct"),
                .target(name: "CoreNavigation"),
                .target(name: "CoreDesignSystem"),
                .target(name: "CoreNetwork"),
            ]
        ),

        // MARK: - App Tests
        .target(
            name: "MyTuistProjectTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "dev.tuist.MyTuistProjectTests",
            infoPlist: .default,
            sources: [
                "MyTuistProject/Tests/**"
            ],
            dependencies: [
                .target(name: "MyTuistProject")
            ]
        ),

        // MARK: - Core Modules
        .target(
            name: "CoreNetwork",
            destinations: .iOS,
            product: .framework,
            bundleId: "dev.tuist.CoreNetwork",
            sources: [
                "Core/Network/Sources/**"
            ],
            dependencies: [
                .external(name: "FactoryKit")
            ]
        ),
        .target(
            name: "CoreNetworkTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "dev.tuist.CoreNetworkTests",
            infoPlist: .default,
            sources: [
                "Core/Network/Tests/**"
            ],
            dependencies: [
                .target(name: "CoreNetwork")
            ]
        ),
        .target(
            name: "CoreDesignSystem",
            destinations: .iOS,
            product: .framework,
            bundleId: "dev.tuist.CoreDesignSystem",
            sources: [
                "Core/DesignSystem/Sources/**"
            ],
            dependencies: []
        ),
        .target(
            name: "CoreNavigation",
            destinations: .iOS,
            product: .framework,
            bundleId: "dev.tuist.CoreNavigation",
            sources: [
                "Core/Navigation/Sources/**"
            ],
            dependencies: [
                .external(name: "FactoryKit"),
                .target(name: "DomainProduct")
            ]
        ),
        .target(
            name: "CoreNavigationTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "dev.tuist.CoreNavigationTests",
            infoPlist: .default,
            sources: [
                "Core/Navigation/Tests/**"
            ],
            dependencies: [
                .target(name: "CoreNavigation")
            ]
        ),

        // MARK: - Domain Modules
        .target(
            name: "DomainProduct",
            destinations: .iOS,
            product: .framework,
            bundleId: "dev.tuist.DomainProduct",
            sources: [
                "Modules/Domain/Product/Sources/**"
            ],
            dependencies: [
                .external(name: "FactoryKit")
            ]
        ),
        .target(
            name: "DomainProductTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "dev.tuist.DomainProductTests",
            infoPlist: .default,
            sources: [
                "Modules/Domain/Product/Tests/**"
            ],
            dependencies: [
                .target(name: "DomainProduct"),
                .external(name: "FactoryKit")
            ]
        ),

        // MARK: - Data Modules
        .target(
            name: "DataProduct",
            destinations: .iOS,
            product: .framework,
            bundleId: "dev.tuist.DataProduct",
            sources: [
                "Modules/Data/Product/Sources/**"
            ],
            dependencies: [
                .external(name: "FactoryKit"),
                .target(name: "DomainProduct"),
                .target(name: "CoreNetwork"),
            ]
        ),
        .target(
            name: "DataProductTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "dev.tuist.DataProductTests",
            infoPlist: .default,
            sources: [
                "Modules/Data/Product/Tests/**"
            ],
            dependencies: [
                .target(name: "DataProduct"),
                .target(name: "DomainProduct"),
                .target(name: "CoreNetwork"),
                .external(name: "FactoryKit")
            ]
        ),

        // MARK: - Feature Product (Catalog/List)
        .target(
            name: "FeatureProduct",
            destinations: .iOS,
            product: .framework,
            bundleId: "dev.tuist.FeatureProduct",
            sources: [
                "Features/Product/Sources/**"
            ],
            dependencies: [
                .external(name: "FactoryKit"),
                .target(name: "DomainProduct"),
                .target(name: "CoreDesignSystem"),
                .target(name: "CoreNavigation"),
            ]
        ),
        .target(
            name: "FeatureProductTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "dev.tuist.FeatureProductTests",
            infoPlist: .default,
            sources: [
                "Features/Product/Tests/**"
            ],
            dependencies: [
                .target(name: "FeatureProduct"),
                .target(name: "DomainProduct"),
                .external(name: "FactoryKit")
            ]
        ),

        // MARK: - Feature Product Detail
        .target(
            name: "FeatureProductDetail",
            destinations: .iOS,
            product: .framework,
            bundleId: "dev.tuist.FeatureProductDetail",
            sources: [
                "Features/ProductDetail/Sources/**"
            ],
            dependencies: [
                .external(name: "FactoryKit"),
                .target(name: "DomainProduct"),
                .target(name: "CoreDesignSystem"),
                .target(name: "CoreNavigation"),
            ]
        ),
        .target(
            name: "FeatureProductDetailTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "dev.tuist.FeatureProductDetailTests",
            infoPlist: .default,
            sources: [
                "Features/ProductDetail/Tests/**"
            ],
            dependencies: [
                .target(name: "FeatureProductDetail"),
                .target(name: "DomainProduct"),
                .external(name: "FactoryKit")
            ]
        ),

        // MARK: - Feature Splash
        .target(
            name: "FeatureSplash",
            destinations: .iOS,
            product: .framework,
            bundleId: "dev.tuist.FeatureSplash",
            sources: [
                "Features/Splash/Sources/**"
            ],
            dependencies: [
                .external(name: "FactoryKit"),
                .target(name: "CoreDesignSystem"),
                .target(name: "CoreNavigation"),
            ]
        ),
        .target(
            name: "FeatureSplashTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "dev.tuist.FeatureSplashTests",
            infoPlist: .default,
            sources: [
                "Features/Splash/Tests/**"
            ],
            dependencies: [
                .target(name: "FeatureSplash"),
                .external(name: "FactoryKit")
            ]
        ),

        // MARK: - Feature Deeplink Loader
        .target(
            name: "FeatureDeeplinkLoader",
            destinations: .iOS,
            product: .framework,
            bundleId: "dev.tuist.FeatureDeeplinkLoader",
            sources: [
                "Features/DeeplinkLoader/Sources/**"
            ],
            dependencies: [
                .external(name: "FactoryKit"),
                .target(name: "CoreDesignSystem"),
                .target(name: "CoreNavigation"),
                .target(name: "DomainProduct"),
            ]
        ),
        .target(
            name: "FeatureDeeplinkLoaderTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "dev.tuist.FeatureDeeplinkLoaderTests",
            infoPlist: .default,
            sources: [
                "Features/DeeplinkLoader/Tests/**"
            ],
            dependencies: [
                .target(name: "FeatureDeeplinkLoader"),
                .target(name: "DomainProduct"),
                .external(name: "FactoryKit")
            ]
        ),
    ]
)
