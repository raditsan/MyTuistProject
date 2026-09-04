import ProjectDescription

let deploymentTargets: DeploymentTargets = .iOS("15.0")

let project = Project(
    name: "MyTuistProject",
    targets: [
        // MARK: - App Target (Composition Root)
        .target(
            name: "MyTuistProject",
            destinations: .iOS,
            product: .app,
            bundleId: "dev.tuist.MyTuistProject",
            deploymentTargets: deploymentTargets,
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
                .target(name: "FeatureFavorites"),
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
            deploymentTargets: deploymentTargets,
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
            deploymentTargets: deploymentTargets,
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
            deploymentTargets: deploymentTargets,
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
            deploymentTargets: deploymentTargets,
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
            deploymentTargets: deploymentTargets,
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
            deploymentTargets: deploymentTargets,
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
            deploymentTargets: deploymentTargets,
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
            deploymentTargets: deploymentTargets,
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
            deploymentTargets: deploymentTargets,
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
            deploymentTargets: deploymentTargets,
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
            deploymentTargets: deploymentTargets,
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
            deploymentTargets: deploymentTargets,
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
            deploymentTargets: deploymentTargets,
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
            deploymentTargets: deploymentTargets,
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
            deploymentTargets: deploymentTargets,
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
            deploymentTargets: deploymentTargets,
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
            deploymentTargets: deploymentTargets,
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
            deploymentTargets: deploymentTargets,
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

        // MARK: - Feature Favorites
        .target(
            name: "FeatureFavorites",
            destinations: .iOS,
            product: .framework,
            bundleId: "dev.tuist.FeatureFavorites",
            deploymentTargets: deploymentTargets,
            sources: [
                "Features/Favorites/Sources/**"
            ],
            dependencies: [
                .external(name: "FactoryKit"),
                .target(name: "CoreDesignSystem"),
                .target(name: "CoreNavigation"),
                .target(name: "DomainProduct"),
            ]
        ),
        .target(
            name: "FeatureFavoritesTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "dev.tuist.FeatureFavoritesTests",
            deploymentTargets: deploymentTargets,
            infoPlist: .default,
            sources: [
                "Features/Favorites/Tests/**"
            ],
            dependencies: [
                .target(name: "FeatureFavorites"),
                .external(name: "FactoryKit")
            ]
        ),
    ]
)
