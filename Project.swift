import ProjectDescription

let deploymentTargets: DeploymentTargets = .iOS("15.0")

// MARK: - Build Configurations
let configurations: [Configuration] = [
    .debug(name: "Debug-Dev", xcconfig: "Configurations/Dev.xcconfig"),
    .release(name: "Release-Dev", xcconfig: "Configurations/Dev.xcconfig"),
    .debug(name: "Debug-UAT", xcconfig: "Configurations/UAT.xcconfig"),
    .release(name: "Release-UAT", xcconfig: "Configurations/UAT.xcconfig"),
    .debug(name: "Debug-Prod", xcconfig: "Configurations/Prod.xcconfig"),
    .release(name: "Release-Prod", xcconfig: "Configurations/Prod.xcconfig"),
]

let projectSettings = Settings.settings(
    configurations: configurations,
    defaultSettings: .recommended
)

// MARK: - Schemes Helper
func makeAppScheme(name: String, debugConfig: ConfigurationName, releaseConfig: ConfigurationName) -> Scheme {
    .scheme(
        name: name,
        shared: true,
        buildAction: .buildAction(targets: [.target("MyTuistProject")]),
        testAction: .targets(
            ["MyTuistProjectTests"],
            configuration: debugConfig
        ),
        runAction: .runAction(configuration: debugConfig),
        archiveAction: .archiveAction(configuration: releaseConfig),
        profileAction: .profileAction(configuration: releaseConfig),
        analyzeAction: .analyzeAction(configuration: debugConfig)
    )
}

let projectSchemes: [Scheme] = [
    makeAppScheme(name: "MyTuistProject-Dev", debugConfig: "Debug-Dev", releaseConfig: "Release-Dev"),
    makeAppScheme(name: "MyTuistProject-UAT", debugConfig: "Debug-UAT", releaseConfig: "Release-UAT"),
    makeAppScheme(name: "MyTuistProject-Prod", debugConfig: "Debug-Prod", releaseConfig: "Release-Prod"),
]

let project = Project(
    name: "MyTuistProject",
    options: .options(
        defaultKnownRegions: ["Base", "en", "id"],
        developmentRegion: "id"
    ),
    settings: projectSettings,
    targets: [
        // MARK: - App Target (Composition Root)
        .target(
            name: "MyTuistProject",
            destinations: .iOS,
            product: .app,
            bundleId: "dev.tuist.MyTuistProject$(BUNDLE_ID_SUFFIX)",
            deploymentTargets: deploymentTargets,
            infoPlist: .extendingDefault(
                with: [
                    "CFBundleDisplayName": "$(APP_NAME)",
                    "BASE_URL": "$(BASE_URL)",
                    "ENVIRONMENT": "$(ENVIRONMENT)",
                    "UILaunchScreen": [
                        "UIColorName": "",
                        "UIImageName": "",
                    ],
                    "CFBundleURLTypes": [
                        [
                            "CFBundleURLName": "dev.tuist.MyTuistProject",
                            "CFBundleURLSchemes": ["$(APP_URL_SCHEME)"],
                        ],
                    ],
                    "NSCameraUsageDescription": "The app requires camera access to take photos or scan.",
                    "NSLocationWhenInUseUsageDescription": "The app requires location access to show nearby services.",
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
                .target(name: "CoreLocalization"),
                .target(name: "FeatureCart"),
                .target(name: "CorePermission"),
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
            name: "CoreLocalization",
            destinations: .iOS,
            product: .framework,
            bundleId: "dev.tuist.CoreLocalization",
            deploymentTargets: deploymentTargets,
            sources: [
                "Core/Localization/Sources/**"
            ],
            resources: [
                "Core/Localization/Resources/**"
            ],
            dependencies: [
                .external(name: "FactoryKit")
            ]
        ),
        .target(
            name: "CoreLocalizationTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "dev.tuist.CoreLocalizationTests",
            deploymentTargets: deploymentTargets,
            infoPlist: .default,
            sources: [
                "Core/Localization/Tests/**"
            ],
            dependencies: [
                .target(name: "CoreLocalization")
            ]
        ),
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
                .external(name: "FactoryKit"),
                .target(name: "CoreLocalization"),
                .target(name: "FeatureCart"),
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
            dependencies: [
                .target(name: "CoreLocalization")
            ]
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
                .target(name: "CoreLocalization")
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

        // MARK: - Core Permission
        .target(
            name: "CorePermission",
            destinations: .iOS,
            product: .framework,
            bundleId: "dev.tuist.CorePermission",
            deploymentTargets: deploymentTargets,
            sources: [
                "Core/Permission/Sources/**"
            ],
            dependencies: [
                .target(name: "CoreLocalization"),
                .external(name: "FactoryKit")
            ]
        ),
        .target(
            name: "CorePermissionTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "dev.tuist.CorePermissionTests",
            deploymentTargets: deploymentTargets,
            infoPlist: .default,
            sources: [
                "Core/Permission/Tests/**"
            ],
            dependencies: [
                .target(name: "CorePermission"),
                .external(name: "FactoryKit")
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
                .target(name: "CoreLocalization"),
                .target(name: "FeatureCart"),
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
                .target(name: "CoreLocalization"),
                .target(name: "FeatureCart"),
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
                .target(name: "CoreLocalization"),
                .target(name: "FeatureCart"),
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
                .target(name: "CoreLocalization"),
                .target(name: "FeatureCart"),
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
                .target(name: "CoreLocalization"),
                .target(name: "FeatureCart"),
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
        // MARK: - Feature Cart
        .target(
            name: "FeatureCart",
            destinations: .iOS,
            product: .framework,
            bundleId: "dev.tuist.FeatureCart",
            deploymentTargets: deploymentTargets,
            sources: [
                "Features/Cart/Sources/**"
            ],
            dependencies: [
                .external(name: "FactoryKit"),
                .target(name: "CoreDesignSystem"),
                .target(name: "CoreNavigation"),
                .target(name: "CoreLocalization"),
            ]
        ),
        .target(
            name: "FeatureCartTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "dev.tuist.FeatureCartTests",
            deploymentTargets: deploymentTargets,
            infoPlist: .default,
            sources: [
                "Features/Cart/Tests/**"
            ],
            dependencies: [
                .target(name: "FeatureCart"),
                .external(name: "FactoryKit")
            ]
        ),

    ],
    schemes: projectSchemes
)
