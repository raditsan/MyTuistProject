#!/usr/bin/env python3
import os
import sys
import re
import subprocess
from pathlib import Path

def to_pascal_case(s: str) -> str:
    s = re.sub(r'^(feature|Feature)[_\-\s]*', '', s)
    s = re.sub(r'(View|Screen)$', '', s)
    if re.search(r'[^a-zA-Z0-9]', s):
        words = re.split(r'[^a-zA-Z0-9]+', s)
        return "".join(word.capitalize() for word in words if word)
    if not s:
        return ""
    return s[0].upper() + s[1:]

def to_camel_case(s: str) -> str:
    pascal = to_pascal_case(s)
    if not pascal:
        return ""
    return pascal[0].lower() + pascal[1:]

def parse_args():
    name = None
    for arg in sys.argv[1:]:
        if arg.startswith("name=") or arg.startswith("NAME="):
            name = arg.split("=", 1)[1]
        elif not arg.startswith("-") and name is None:
            name = arg

    if not name:
        try:
            name = input("Masukkan nama Feature baru (misal: Cart, Profile, Notification): ").strip()
        except (EOFError, KeyboardInterrupt):
            print("\nOperasi dibatalkan.")
            sys.exit(1)

    if not name:
        print("Error: Nama feature tidak boleh kosong.")
        sys.exit(1)

    return name

def create_domain_module(root_dir: Path, feature_name: str):
    case_name = to_camel_case(feature_name)
    domain_dir = root_dir / "Modules" / "Domain" / feature_name
    (domain_dir / "Sources" / "Entities").mkdir(parents=True, exist_ok=True)
    (domain_dir / "Sources" / "Repositories").mkdir(parents=True, exist_ok=True)
    (domain_dir / "Sources" / "UseCases").mkdir(parents=True, exist_ok=True)
    (domain_dir / "Tests").mkdir(parents=True, exist_ok=True)

    # 1. Entity
    entity_path = domain_dir / "Sources" / "Entities" / f"{feature_name}.swift"
    if not entity_path.exists():
        template_entity = f"""import Foundation

public struct {feature_name}: Identifiable, Equatable, Hashable, Sendable {{
    public let id: String
    public let title: String

    public init(id: String = UUID().uuidString, title: String = "") {{
        self.id = id
        self.title = title
    }}
}}
"""
        entity_path.write_text(template_entity)
        print(f"  ✅ Created: {entity_path.relative_to(root_dir)}")

    # 2. Repository Protocol
    repo_proto_path = domain_dir / "Sources" / "Repositories" / f"{feature_name}RepositoryProtocol.swift"
    if not repo_proto_path.exists():
        template_repo_proto = f"""import Foundation

public protocol {feature_name}RepositoryProtocol: Sendable {{
    func get{feature_name}() async throws -> {feature_name}
}}
"""
        repo_proto_path.write_text(template_repo_proto)
        print(f"  ✅ Created: {repo_proto_path.relative_to(root_dir)}")

    # 3. Use Case
    use_case_path = domain_dir / "Sources" / "UseCases" / f"Get{feature_name}UseCase.swift"
    if not use_case_path.exists():
        template_use_case = f"""import Foundation
import FactoryKit

public protocol Get{feature_name}UseCaseProtocol: Sendable {{
    func execute() async throws -> {feature_name}
}}

public final class Get{feature_name}UseCase: Get{feature_name}UseCaseProtocol, @unchecked Sendable {{
    @Injected(\\.{case_name}Repository) private var repository: {feature_name}RepositoryProtocol

    public init() {{}}

    public init(repository: {feature_name}RepositoryProtocol) {{
        self.repository = repository
    }}

    public func execute() async throws -> {feature_name} {{
        try await repository.get{feature_name}()
    }}
}}
"""
        use_case_path.write_text(template_use_case)
        print(f"  ✅ Created: {use_case_path.relative_to(root_dir)}")

    # 4. Container+Domain
    container_path = domain_dir / "Sources" / f"Container+Domain{feature_name}.swift"
    if not container_path.exists():
        template_container = f"""import Foundation
import FactoryKit

extension Container {{
    public var {case_name}Repository: Factory<{feature_name}RepositoryProtocol> {{
        self {{ fatalError("{feature_name}RepositoryProtocol must be registered by Data layer") }}
    }}

    public var get{feature_name}UseCase: Factory<Get{feature_name}UseCaseProtocol> {{
        self {{ Get{feature_name}UseCase() }}
    }}
}}
"""
        container_path.write_text(template_container)
        print(f"  ✅ Created: {container_path.relative_to(root_dir)}")

    # 5. Domain Mock Repository & Unit Tests
    (domain_dir / "Tests" / "Mocks").mkdir(parents=True, exist_ok=True)
    mock_repo_path = domain_dir / "Tests" / "Mocks" / f"Mock{feature_name}Repository.swift"
    if not mock_repo_path.exists():
        template_mock_repo = f"""import Foundation
@testable import Domain{feature_name}

public final class Mock{feature_name}Repository: {feature_name}RepositoryProtocol, @unchecked Sendable {{
    public var resultToReturn: {feature_name}?
    public var errorToThrow: Error?

    public init() {{}}

    public func get{feature_name}() async throws -> {feature_name} {{
        if let error = errorToThrow {{
            throw error
        }}
        return resultToReturn ?? {feature_name}(id: "1", title: "Test {feature_name}")
    }}
}}
"""
        mock_repo_path.write_text(template_mock_repo)
        print(f"  ✅ Created: {mock_repo_path.relative_to(root_dir)}")

    test_path = domain_dir / "Tests" / f"Get{feature_name}UseCaseTests.swift"
    if not test_path.exists():
        template_test = f"""import XCTest
import FactoryKit
@testable import Domain{feature_name}

final class Get{feature_name}UseCaseTests: XCTestCase {{
    private var sut: Get{feature_name}UseCase!
    private var mockRepository: Mock{feature_name}Repository!

    override func setUp() {{
        super.setUp()
        Container.shared.reset()
        mockRepository = Mock{feature_name}Repository()
        let repo = mockRepository!
        Container.shared.{case_name}Repository.register {{ repo }}
        sut = Get{feature_name}UseCase(repository: repo)
    }}

    override func tearDown() {{
        Container.shared.reset()
        sut = nil
        mockRepository = nil
        super.tearDown()
    }}

    func test_execute_success() async throws {{
        let expected = {feature_name}(id: "123", title: "Test")
        mockRepository.resultToReturn = expected

        let result = try await sut.execute()
        XCTAssertEqual(result, expected)
    }}
}}
"""
        test_path.write_text(template_test)
        print(f"  ✅ Created: {test_path.relative_to(root_dir)}")

def create_data_module(root_dir: Path, feature_name: str):
    case_name = to_camel_case(feature_name)
    feature_lower = feature_name.lower()
    data_dir = root_dir / "Modules" / "Data" / feature_name
    (data_dir / "Sources" / "DTOs").mkdir(parents=True, exist_ok=True)
    (data_dir / "Sources" / "Endpoints").mkdir(parents=True, exist_ok=True)
    (data_dir / "Sources" / "DataSources").mkdir(parents=True, exist_ok=True)
    (data_dir / "Sources" / "Repositories").mkdir(parents=True, exist_ok=True)
    (data_dir / "Tests").mkdir(parents=True, exist_ok=True)

    # 1. DTO
    dto_path = data_dir / "Sources" / "DTOs" / f"{feature_name}DTO.swift"
    if not dto_path.exists():
        template_dto = f"""import Foundation
import Domain{feature_name}

public struct {feature_name}DTO: Codable, Sendable {{
    public let id: String
    public let title: String

    public init(id: String, title: String) {{
        self.id = id
        self.title = title
    }}

    public func toDomain() -> {feature_name} {{
        {feature_name}(id: id, title: title)
    }}
}}
"""
        dto_path.write_text(template_dto)
        print(f"  ✅ Created: {dto_path.relative_to(root_dir)}")

    # 2. Endpoint
    endpoint_path = data_dir / "Sources" / "Endpoints" / f"{feature_name}Endpoint.swift"
    if not endpoint_path.exists():
        template_endpoint = f"""import Foundation
import CoreNetwork
import Moya

public enum {feature_name}Endpoint: TargetType {{
    case get{feature_name}

    public var baseURL: URL {{
        URL(string: AppEnvironment.baseURL) ?? URL(string: "https://api.example.com")!
    }}

    public var path: String {{
        switch self {{
        case .get{feature_name}:
            return "/{feature_lower}"
        }}
    }}

    public var method: Moya.Method {{
        .get
    }}

    public var task: Task {{
        .requestPlain
    }}

    public var headers: [String: String]? {{
        ["Content-Type": "application/json", "Accept": "application/json"]
    }}
}}
"""
        endpoint_path.write_text(template_endpoint)
        print(f"  ✅ Created: {endpoint_path.relative_to(root_dir)}")

    # 3. RemoteDataSource
    rds_path = data_dir / "Sources" / "DataSources" / f"{feature_name}RemoteDataSource.swift"
    if not rds_path.exists():
        template_rds = f"""import Foundation
import CoreNetwork
import FactoryKit

public protocol {feature_name}RemoteDataSourceProtocol: Sendable {{
    func fetch{feature_name}() async throws -> {feature_name}DTO
}}

public final class {feature_name}RemoteDataSource: {feature_name}RemoteDataSourceProtocol, @unchecked Sendable {{
    @Injected(\\.networkClient) private var client: NetworkClientProtocol

    public init() {{}}

    public init(client: any NetworkClientProtocol) {{
        self.client = client
    }}

    public func fetch{feature_name}() async throws -> {feature_name}DTO {{
        try await client.request(target: {feature_name}Endpoint.get{feature_name}, type: {feature_name}DTO.self)
    }}
}}
"""
        rds_path.write_text(template_rds)
        print(f"  ✅ Created: {rds_path.relative_to(root_dir)}")

    # 3. Repository
    repo_path = data_dir / "Sources" / "Repositories" / f"{feature_name}Repository.swift"
    if not repo_path.exists():
        template_repo = f"""import Foundation
import Domain{feature_name}
import FactoryKit

public final class {feature_name}Repository: {feature_name}RepositoryProtocol, @unchecked Sendable {{
    @Injected(\\.{case_name}RemoteDataSource) private var remoteDataSource: {feature_name}RemoteDataSourceProtocol

    public init() {{}}

    public init(remoteDataSource: {feature_name}RemoteDataSourceProtocol) {{
        self.remoteDataSource = remoteDataSource
    }}

    public func get{feature_name}() async throws -> {feature_name} {{
        let dto = try await remoteDataSource.fetch{feature_name}()
        return dto.toDomain()
    }}
}}
"""
        repo_path.write_text(template_repo)
        print(f"  ✅ Created: {repo_path.relative_to(root_dir)}")

    # 4. Container+Data
    container_path = data_dir / "Sources" / f"Container+Data{feature_name}.swift"
    if not container_path.exists():
        template_container = f"""import Foundation
import FactoryKit
import Domain{feature_name}

extension Container {{
    public var {case_name}RemoteDataSource: Factory<{feature_name}RemoteDataSourceProtocol> {{
        self {{ {feature_name}RemoteDataSource() }}.singleton
    }}

    public func register{feature_name}DataDependencies() {{
        {case_name}Repository.register {{
            {feature_name}Repository()
        }}
    }}
}}
"""
        container_path.write_text(template_container)
        print(f"  ✅ Created: {container_path.relative_to(root_dir)}")

    # 5. Data Mock RemoteDataSource & Unit Tests
    (data_dir / "Tests" / "Mocks").mkdir(parents=True, exist_ok=True)
    mock_rds_path = data_dir / "Tests" / "Mocks" / f"Mock{feature_name}RemoteDataSource.swift"
    if not mock_rds_path.exists():
        template_mock_rds = f"""import Foundation
import Domain{feature_name}
@testable import Data{feature_name}

public final class Mock{feature_name}RemoteDataSource: {feature_name}RemoteDataSourceProtocol, @unchecked Sendable {{
    public var dtoToReturn: {feature_name}DTO?
    public var errorToThrow: Error?

    public init() {{}}

    public func fetch{feature_name}() async throws -> {feature_name}DTO {{
        if let error = errorToThrow {{
            throw error
        }}
        return dtoToReturn ?? {feature_name}DTO(id: "1", title: "Test")
    }}
}}
"""
        mock_rds_path.write_text(template_mock_rds)
        print(f"  ✅ Created: {mock_rds_path.relative_to(root_dir)}")

    test_path = data_dir / "Tests" / f"{feature_name}RepositoryTests.swift"
    if not test_path.exists():
        template_test = f"""import XCTest
import FactoryKit
import Domain{feature_name}
@testable import Data{feature_name}

final class {feature_name}RepositoryTests: XCTestCase {{
    private var sut: {feature_name}Repository!
    private var mockRemoteDataSource: Mock{feature_name}RemoteDataSource!

    override func setUp() {{
        super.setUp()
        Container.shared.reset()
        mockRemoteDataSource = Mock{feature_name}RemoteDataSource()
        let ds = mockRemoteDataSource!
        Container.shared.{case_name}RemoteDataSource.register {{ ds }}
        sut = {feature_name}Repository(remoteDataSource: ds)
    }}

    override func tearDown() {{
        Container.shared.reset()
        sut = nil
        mockRemoteDataSource = nil
        super.tearDown()
    }}

    func test_get{feature_name}_success() async throws {{
        let dto = {feature_name}DTO(id: "100", title: "Success")
        mockRemoteDataSource.dtoToReturn = dto

        let result = try await sut.get{feature_name}()
        XCTAssertEqual(result.id, "100")
        XCTAssertEqual(result.title, "Success")
    }}
}}
"""
        test_path.write_text(template_test)
        print(f"  ✅ Created: {test_path.relative_to(root_dir)}")

def create_feature_module(root_dir: Path, feature_name: str):
    case_name = to_camel_case(feature_name)
    module_name = f"Feature{feature_name}"
    view_name = f"{feature_name}View"
    view_model_name = f"{feature_name}ViewModel"
    test_name = f"{feature_name}ViewModelTests"
    param_name = f"{feature_name}ScreenParam"

    feature_dir = root_dir / "Features" / feature_name
    (feature_dir / "Sources" / "Views").mkdir(parents=True, exist_ok=True)
    (feature_dir / "Sources" / "ViewModels").mkdir(parents=True, exist_ok=True)
    (feature_dir / "Tests").mkdir(parents=True, exist_ok=True)

    # 1. View
    view_path = feature_dir / "Sources" / "Views" / f"{view_name}.swift"
    if not view_path.exists():
        template_view = f"""import SwiftUI
import CoreDesignSystem
import CoreNavigation
import CoreLocalization
import Domain{feature_name}
import FactoryKit

@MainActor
public struct {view_name}: View {{
    @Injected(\\.router) private var router
    @StateObject private var viewModel: {view_model_name}

    public init(param: {param_name}? = nil) {{
        _viewModel = StateObject(wrappedValue: {view_model_name}(param: param))
    }}

    public init(viewModel: {view_model_name}) {{
        _viewModel = StateObject(wrappedValue: viewModel)
    }}

    public var body: some View {{
        Group {{
            switch viewModel.state {{
            case .idle, .loading:
                LoadingView(message: "Loading {feature_name}...")
            case .empty:
                ErrorView(
                    title: "No Data",
                    message: "No {feature_name} data available.",
                    retryAction: {{
                        Task {{ await viewModel.loadData() }}
                    }}
                )
            case .failure(let errorMessage):
                ErrorView(
                    title: "Something went wrong",
                    message: errorMessage,
                    retryAction: {{
                        Task {{ await viewModel.loadData() }}
                    }}
                )
            case .success(let item):
                contentView(item: item)
            }}
        }}
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignTokens.Colors.background.ignoresSafeArea())
        .navigationTitle("{feature_name}")
        .task {{
            await viewModel.loadData()
        }}
    }}

    @ViewBuilder
    private func contentView(item: {feature_name}) -> some View {{
        VStack(spacing: DesignTokens.Spacing.md) {{
            Text(item.title.isEmpty ? "{feature_name}" : item.title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(DesignTokens.Colors.textPrimary)

            Text("ID: \\(item.id)")
                .font(.subheadline)
                .foregroundColor(DesignTokens.Colors.textSecondary)
        }}
        .padding(DesignTokens.Spacing.lg)
    }}
}}
"""
        view_path.write_text(template_view)
        print(f"  ✅ Created: {view_path.relative_to(root_dir)}")

    # 2. ViewModel
    vm_path = feature_dir / "Sources" / "ViewModels" / f"{view_model_name}.swift"
    if not vm_path.exists():
        template_vm = f"""import Foundation
import Combine
import CoreNavigation
import Domain{feature_name}
import FactoryKit

public enum {feature_name}ViewState: Equatable {{
    case idle
    case loading
    case success({feature_name})
    case empty
    case failure(String)
}}

@MainActor
public final class {view_model_name}: ObservableObject {{
    @Published public private(set) var state: {feature_name}ViewState = .idle
    @Injected(\\.router) private var router: AppRouter
    @Injected(\\.get{feature_name}UseCase) private var get{feature_name}UseCase: Get{feature_name}UseCaseProtocol
    public let param: {param_name}?

    public init(param: {param_name}? = nil) {{
        self.param = param
    }}

    public init(
        param: {param_name}? = nil,
        get{feature_name}UseCase: Get{feature_name}UseCaseProtocol,
        router: AppRouter? = nil
    ) {{
        self.param = param
        self.get{feature_name}UseCase = get{feature_name}UseCase
        if let router {{
            self.router = router
        }}
    }}

    public func loadData() async {{
        state = .loading
        do {{
            let data = try await get{feature_name}UseCase.execute()
            state = .success(data)
        }} catch {{
            state = .failure(error.localizedDescription)
        }}
    }}

    public func goBack() {{
        router.pop()
    }}
}}
"""
        vm_path.write_text(template_vm)
        print(f"  ✅ Created: {vm_path.relative_to(root_dir)}")

    # 3. ViewModelTests
    test_path = feature_dir / "Tests" / f"{test_name}.swift"
    if not test_path.exists():
        template_test = f"""import XCTest
import SwiftUI
import CoreNavigation
import Domain{feature_name}
import FactoryKit
@testable import {module_name}

private final class MockGet{feature_name}UseCase: Get{feature_name}UseCaseProtocol, @unchecked Sendable {{
    var resultToReturn: {feature_name}?
    var errorToThrow: Error?

    func execute() async throws -> {feature_name} {{
        if let error = errorToThrow {{
            throw error
        }}
        return resultToReturn ?? {feature_name}(id: "1", title: "Test {feature_name}")
    }}
}}

@MainActor
final class {test_name}: XCTestCase {{
    private var sut: {view_model_name}!
    private var router: AppRouter!
    private var mockUseCase: MockGet{feature_name}UseCase!

    override func setUp() {{
        super.setUp()
        Container.shared.reset()
        let nav = UINavigationController()
        router = AppRouter(navigationController: nav)
        mockUseCase = MockGet{feature_name}UseCase()

        let r = router!
        Container.shared.router.register {{
            r
        }}
        let useCase = mockUseCase!
        Container.shared.get{feature_name}UseCase.register {{
            useCase
        }}
        sut = {view_model_name}()
    }}

    override func tearDown() {{
        Container.shared.reset()
        sut = nil
        router = nil
        mockUseCase = nil
        super.tearDown()
    }}

    func test_initialState() {{
        XCTAssertEqual(sut.state, .idle)
    }}

    func test_loadData_success() async {{
        let expected = {feature_name}(id: "99", title: "Success Title")
        mockUseCase.resultToReturn = expected

        await sut.loadData()

        XCTAssertEqual(sut.state, .success(expected))
    }}

    func test_loadData_failure() async {{
        let expectedError = NSError(domain: "TestError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Network Failed"])
        mockUseCase.errorToThrow = expectedError

        await sut.loadData()

        if case .failure(let message) = sut.state {{
            XCTAssertTrue(message.contains("Network Failed") || !message.isEmpty)
        }} else {{
            XCTFail("Expected .failure state, got \\(sut.state)")
        }}
    }}

    func test_goBack_callsRouterPop() {{
        router.push(Text("Screen 1"), animated: false)
        router.push(Text("Screen 2"), animated: false)
        XCTAssertEqual(router.navigationController.viewControllers.count, 2)

        sut.goBack()
        XCTAssertEqual(router.navigationController.viewControllers.count, 1)
    }}
}}
"""
        test_path.write_text(template_test)
        print(f"  ✅ Created: {test_path.relative_to(root_dir)}")

def create_navigation_files(root_dir: Path, feature_name: str):
    case_name = to_camel_case(feature_name)
    module_name = f"Feature{feature_name}"
    view_name = f"{feature_name}View"
    destination_name = f"{feature_name}Destination"
    route_name = f"{feature_name}Route"
    param_name = f"{feature_name}ScreenParam"
    route_handler_name = f"{feature_name}RouteHandler"
    deeplink_host = feature_name.lower()

    # 1. CoreNavigation: Destinations/<Name>Destination.swift
    dest_path = root_dir / "Core" / "Navigation" / "Sources" / "Destinations" / f"{destination_name}.swift"
    if not dest_path.exists():
        dest_path.parent.mkdir(parents=True, exist_ok=True)
        template_dest = f"""import Foundation

public enum {destination_name}: FeatureDestination {{
    case list
}}
"""
        dest_path.write_text(template_dest)
        print(f"  ✅ Created: {dest_path.relative_to(root_dir)}")

    # 2. CoreNavigation: Param/<Name>ScreenParam.swift
    param_path = root_dir / "Core" / "Navigation" / "Sources" / "Param" / f"{param_name}.swift"
    if not param_path.exists():
        param_path.parent.mkdir(parents=True, exist_ok=True)
        template_param = f"""import Foundation

/// Navigation parameter for {feature_name} screen.
/// Kept in CoreNavigation without any dependency to Domain entities.
public struct {param_name}: Identifiable, Hashable, Sendable {{
    public let id: String

    public init(id: String = UUID().uuidString) {{
        self.id = id
    }}
}}
"""
        param_path.write_text(template_param)
        print(f"  ✅ Created: {param_path.relative_to(root_dir)}")

    # 3. CoreNavigation: Routes/<Name>Route.swift
    route_path = root_dir / "Core" / "Navigation" / "Sources" / "Routes" / f"{route_name}.swift"
    if not route_path.exists():
        route_path.parent.mkdir(parents=True, exist_ok=True)
        template_route = f"""import SwiftUI

public enum {route_name}: AppRouteType {{
    case list
    case detail({param_name})

    public var destination: AppRouteDestination {{
        switch self {{
        case .list:
            return .{case_name}(.list)
        case .detail:
            return .{case_name}(.list)
        }}
    }}

    @MainActor @ViewBuilder
    public func makeView() -> some View {{
        AppRouter.viewBuilder(.{case_name}(self))
    }}

    public static var deepLinkHost: String? {{ "{deeplink_host}" }}

    public static func deepLinkResolve(
        pathComponents: [String],
        queryParameters: [String: String] = [:]
    ) -> AppRoute? {{
        guard pathComponents.first == deepLinkHost else {{ return nil }}
        return .{case_name}(.list)
    }}
}}
"""
        route_path.write_text(template_route)
        print(f"  ✅ Created: {route_path.relative_to(root_dir)}")

    # 4. Register in AppRouteDestination.swift
    app_dest_path = root_dir / "Core" / "Navigation" / "Sources" / "AppRouteDestination.swift"
    app_dest_content = app_dest_path.read_text()
    case_dest_str = f"case {case_name}({destination_name})"
    if case_dest_str not in app_dest_content:
        pattern = r"(public enum AppRouteDestination: [^\{]+\{.*?)(\n\})"
        def add_dest(m):
            body = m.group(1).rstrip()
            return f"{body}\n    {case_dest_str}\n}}"
        app_dest_content = re.sub(pattern, add_dest, app_dest_content, flags=re.DOTALL)
        app_dest_path.write_text(app_dest_content)
        print(f"  ✅ Registered in AppRouteDestination.swift: {case_dest_str}")

    # 5. Register in AppRoute.swift
    app_route_path = root_dir / "Core" / "Navigation" / "Sources" / "Routes" / "AppRoute.swift"
    app_route_content = app_route_path.read_text()
    case_route_str = f"case {case_name}({route_name})"
    if case_route_str not in app_route_content:
        pattern_enum = r"(public enum AppRoute: [^\{]+\{\n)(.*?)(\n\s*public var destination:)"
        def add_route_enum(m):
            body = m.group(2).rstrip()
            return f"{m.group(1)}{body}\n    {case_route_str}\n{m.group(3)}"
        app_route_content = re.sub(pattern_enum, add_route_enum, app_route_content, flags=re.DOTALL)

        pattern_dest_switch = r"(public var destination: AppRouteDestination\s*\{[\s\S]*?switch self\s*\{)([\s\S]*?)(\n\s*\}\s*\n\s*\})"
        dest_branch = f"\n        case .{case_name}(let route):\n            return route.destination"
        def add_dest_branch(m):
            body = m.group(2).rstrip()
            return f"{m.group(1)}{body}{dest_branch}{m.group(3)}"
        app_route_content = re.sub(pattern_dest_switch, add_dest_branch, app_route_content, flags=re.DOTALL)

        app_route_path.write_text(app_route_content)
        print(f"  ✅ Registered in AppRoute.swift: {case_route_str}")

    # 6. Register in DeepLinkHandler.swift
    handler_path = root_dir / "Core" / "Navigation" / "Sources" / "DeepLinkHandler.swift"
    handler_content = handler_path.read_text()
    route_type_str = f"{route_name}.self,"
    if route_type_str not in handler_content:
        pattern_reg = r"(registeredRoutes: \[any AppRouteType\.Type\] = \[\n)"
        handler_content = re.sub(pattern_reg, rf"\1        {route_type_str}\n", handler_content)
        handler_path.write_text(handler_content)
        print(f"  ✅ Registered in DeepLinkHandler.swift: {route_type_str}")

    # 7. Composition Root: MyTuistProject/Sources/CompositionRoot/Routes/<Name>RouteHandler.swift
    comp_route_path = root_dir / "MyTuistProject" / "Sources" / "CompositionRoot" / "Routes" / f"{route_handler_name}.swift"
    if not comp_route_path.exists():
        comp_route_path.parent.mkdir(parents=True, exist_ok=True)
        template_handler = f"""import SwiftUI
import CoreNavigation
import {module_name}

@MainActor
public struct {route_handler_name} {{
    public static func buildView(for route: {route_name}) -> AnyView {{
        @ViewBuilder
        var view: some View {{
            switch route {{
            case .list:
                {view_name}()
            case .detail(let param):
                {view_name}(param: param)
            }}
        }}
        return AnyView(view)
    }}
}}
"""
        comp_route_path.write_text(template_handler)
        print(f"  ✅ Created: {comp_route_path.relative_to(root_dir)}")

def register_in_app_di_container(root_dir: Path, feature_name: str):
    case_name = to_camel_case(feature_name)
    route_handler_name = f"{feature_name}RouteHandler"
    app_di_path = root_dir / "MyTuistProject" / "Sources" / "CompositionRoot" / "AppDIContainer.swift"
    app_di_content = app_di_path.read_text()

    # 1. Add import Data<Name>
    import_stmt = f"import Data{feature_name}"
    if import_stmt not in app_di_content:
        if "import DataProduct" in app_di_content:
            app_di_content = app_di_content.replace("import DataProduct\n", f"import DataProduct\n{import_stmt}\n")
        else:
            app_di_content = f"{import_stmt}\n" + app_di_content
        print(f"  ✅ Added {import_stmt} to AppDIContainer.swift")

    # 2. Register Data dependencies in setupDependencies()
    reg_call = f"Container.shared.register{feature_name}DataDependencies()"
    if reg_call not in app_di_content:
        pattern_setup = r"(public func setupDependencies\(\)\s*\{)([\s\S]*?)(\n\s*\})"
        def add_data_reg(m):
            body = m.group(2).rstrip()
            return f"{m.group(1)}{body}\n        {reg_call}{m.group(3)}"
        app_di_content = re.sub(pattern_setup, add_data_reg, app_di_content)
        print(f"  ✅ Registered {reg_call} in AppDIContainer.swift")

    # 3. Register Navigation route in setupNavigation()
    di_case_str = f"case .{case_name}(let {case_name}Route):"
    if di_case_str not in app_di_content:
        pattern_di = r"(switch route\s*\{)([\s\S]*?)(\n\s*\}\s*\n\s*\})"
        di_branch = f"\n            case .{case_name}(let {case_name}Route):\n                return {route_handler_name}.buildView(for: {case_name}Route)"
        def add_di_branch(m):
            body = m.group(2).rstrip()
            return f"{m.group(1)}{body}{di_branch}{m.group(3)}"
        app_di_content = re.sub(pattern_di, add_di_branch, app_di_content, flags=re.DOTALL)
        print(f"  ✅ Registered Navigation route in AppDIContainer.swift: {di_case_str}")

    app_di_path.write_text(app_di_content)

def insert_targets_into_project(proj_content: str, targets_code: str) -> str:
    """
    Inserts targets_code into the targets: [...] array of Project(...) in Project.swift.
    Finds the closing bracket of targets: [...] robustly, supporting trailing commas,
    additional Project arguments (e.g. schemes: ...), and comments.
    """
    project_idx = proj_content.find("Project(")
    if project_idx != -1:
        targets_idx = proj_content.find("targets:", project_idx)
        if targets_idx != -1:
            open_bracket_idx = proj_content.find("[", targets_idx)
            if open_bracket_idx != -1:
                depth = 0
                in_string = False
                in_line_comment = False
                in_block_comment = False
                escape = False
                i = open_bracket_idx
                while i < len(proj_content):
                    char = proj_content[i]
                    if escape:
                        escape = False
                        i += 1
                        continue
                    if in_line_comment:
                        if char == "\n":
                            in_line_comment = False
                        i += 1
                        continue
                    if in_block_comment:
                        if char == "*" and i + 1 < len(proj_content) and proj_content[i + 1] == "/":
                            in_block_comment = False
                            i += 2
                            continue
                        i += 1
                        continue
                    if in_string:
                        if char == "\\":
                            escape = True
                        elif char == '"':
                            in_string = False
                        i += 1
                        continue
                    if char == '"':
                        in_string = True
                        i += 1
                        continue
                    if char == "/" and i + 1 < len(proj_content):
                        if proj_content[i + 1] == "/":
                            in_line_comment = True
                            i += 2
                            continue
                        elif proj_content[i + 1] == "*":
                            in_block_comment = True
                            i += 2
                            continue
                    if char == "[":
                        depth += 1
                    elif char == "]":
                        depth -= 1
                        if depth == 0:
                            last_newline = proj_content.rfind("\n", 0, i)
                            formatted_code = targets_code
                            if not formatted_code.endswith("\n"):
                                formatted_code += "\n"
                            if last_newline != -1:
                                return proj_content[:last_newline + 1] + formatted_code.lstrip("\n") + proj_content[last_newline + 1:]
                            return proj_content[:i] + formatted_code + proj_content[i:]
                    i += 1
    # Fallback to regex pattern
    pattern = r"(\n[ \t]*\],?\s*\n(?:[ \t]*schemes:|\)))"
    match = re.search(pattern, proj_content)
    if match:
        formatted_code = targets_code
        if not formatted_code.endswith("\n"):
            formatted_code += "\n"
        return proj_content[:match.start()] + "\n" + formatted_code.strip("\n") + "\n" + proj_content[match.start() + 1:]
    return proj_content

def register_in_project_swift(root_dir: Path, feature_name: str):
    proj_path = root_dir / "Project.swift"
    proj_content = proj_path.read_text()

    module_name = f"Feature{feature_name}"
    domain_name = f"Domain{feature_name}"
    data_name = f"Data{feature_name}"

    # 1. Add dependencies to MyTuistProject App target
    app_deps_to_add = [
        f'.target(name: "{module_name}"),',
        f'.target(name: "{domain_name}"),',
        f'.target(name: "{data_name}"),',
    ]

    pattern_app_dep = r'(name:\s*"MyTuistProject",[\s\S]*?dependencies:\s*\[)([\s\S]*?)(\n\s*\]\s*\n\s*\),)'
    m_app = re.search(pattern_app_dep, proj_content)
    if m_app:
        existing_deps_body = m_app.group(2)
        new_deps = []
        for dep in app_deps_to_add:
            if dep not in existing_deps_body:
                new_deps.append(f"                {dep}")
        if new_deps:
            updated_body = existing_deps_body.rstrip() + "\n" + "\n".join(new_deps)
            proj_content = proj_content[:m_app.start(2)] + updated_body + proj_content[m_app.end(2):]
            print(f"  ✅ Added App target dependencies in Project.swift")

    # 2. Add Domain Targets if not present
    domain_target_decl = f'name: "{domain_name}",'
    if domain_target_decl not in proj_content:
        domain_targets_code = f"""
        // MARK: - Domain {feature_name}
        .target(
            name: "{domain_name}",
            destinations: .iOS,
            product: .framework,
            bundleId: "dev.tuist.{domain_name}",
            deploymentTargets: deploymentTargets,
            sources: [
                "Modules/Domain/{feature_name}/Sources/**"
            ],
            dependencies: [
                .external(name: "FactoryKit")
            ]
        ),
        .target(
            name: "{domain_name}Tests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "dev.tuist.{domain_name}Tests",
            deploymentTargets: deploymentTargets,
            infoPlist: .default,
            sources: [
                "Modules/Domain/{feature_name}/Tests/**"
            ],
            dependencies: [
                .target(name: "{domain_name}"),
                .external(name: "FactoryKit")
            ]
        ),
"""
        proj_content = insert_targets_into_project(proj_content, domain_targets_code)
        print(f"  ✅ Added {domain_name} and {domain_name}Tests targets in Project.swift")

    # 3. Add Data Targets if not present
    data_target_decl = f'name: "{data_name}",'
    if data_target_decl not in proj_content:
        data_targets_code = f"""
        // MARK: - Data {feature_name}
        .target(
            name: "{data_name}",
            destinations: .iOS,
            product: .framework,
            bundleId: "dev.tuist.{data_name}",
            deploymentTargets: deploymentTargets,
            sources: [
                "Modules/Data/{feature_name}/Sources/**"
            ],
            dependencies: [
                .external(name: "FactoryKit"),
                .target(name: "{domain_name}"),
                .target(name: "CoreNetwork"),
            ]
        ),
        .target(
            name: "{data_name}Tests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "dev.tuist.{data_name}Tests",
            deploymentTargets: deploymentTargets,
            infoPlist: .default,
            sources: [
                "Modules/Data/{feature_name}/Tests/**"
            ],
            dependencies: [
                .target(name: "{data_name}"),
                .target(name: "{domain_name}"),
                .target(name: "CoreNetwork"),
                .external(name: "FactoryKit")
            ]
        ),
"""
        proj_content = insert_targets_into_project(proj_content, data_targets_code)
        print(f"  ✅ Added {data_name} and {data_name}Tests targets in Project.swift")

    # 4. Add or update Feature Targets in Project.swift
    feature_target_decl = f'name: "{module_name}",'
    if feature_target_decl not in proj_content:
        feature_targets_code = f"""
        // MARK: - Feature {feature_name}
        .target(
            name: "{module_name}",
            destinations: .iOS,
            product: .framework,
            bundleId: "dev.tuist.{module_name}",
            deploymentTargets: deploymentTargets,
            sources: [
                "Features/{feature_name}/Sources/**"
            ],
            dependencies: [
                .external(name: "FactoryKit"),
                .target(name: "CoreDesignSystem"),
                .target(name: "CoreNavigation"),
                .target(name: "CoreLocalization"),
                .target(name: "{domain_name}"),
            ]
        ),
        .target(
            name: "{module_name}Tests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "dev.tuist.{module_name}Tests",
            deploymentTargets: deploymentTargets,
            infoPlist: .default,
            sources: [
                "Features/{feature_name}/Tests/**"
            ],
            dependencies: [
                .target(name: "{module_name}"),
                .target(name: "{domain_name}"),
                .external(name: "FactoryKit")
            ]
        ),
"""
        proj_content = insert_targets_into_project(proj_content, feature_targets_code)
        print(f"  ✅ Added {module_name} and {module_name}Tests targets in Project.swift")
    else:
        # Ensure Domain<Name> is listed in Feature<Name> dependencies
        pattern_feat_dep = r'(name:\s*"' + re.escape(module_name) + r'",[\s\S]*?dependencies:\s*\[)([\s\S]*?)(\n\s*\])'
        m_feat = re.search(pattern_feat_dep, proj_content)
        if m_feat:
            domain_dep_str = f'.target(name: "{domain_name}")'
            if domain_dep_str not in m_feat.group(2):
                updated_deps = m_feat.group(2).rstrip() + f'\n                {domain_dep_str},'
                proj_content = proj_content[:m_feat.start(2)] + updated_deps + proj_content[m_feat.end(2):]
                print(f"  ✅ Added {domain_dep_str} to {module_name} dependencies in Project.swift")

    proj_path.write_text(proj_content)

def run_tuist_generate(root_dir: Path) -> bool:
    print("\n📦 Menjalankan 'tuist generate --no-open'...")
    res = subprocess.run(["tuist", "generate", "--no-open"], cwd=root_dir, capture_output=True, text=True)
    if res.returncode == 0:
        if res.stdout.strip():
            print(res.stdout.strip())
        return True
    else:
        print(f"\n❌ 'tuist generate' GAGAL (Kode Keluar: {res.returncode}):")
        error_msg = res.stderr.strip() or res.stdout.strip()
        if error_msg:
            for line in error_msg.splitlines():
                print(f"   {line}")
        print("\n💡 Silakan periksa Project.swift atau detail error di atas.")
        return False

def main():
    root_dir = Path(__file__).resolve().parent.parent
    raw_name = parse_args()
    feature_name = to_pascal_case(raw_name)
    module_name = f"Feature{feature_name}"

    print(f"\n🚀 Membuat Feature Penuh (Feature + Domain + Data): {module_name} ({feature_name})...")

    feature_dir = root_dir / "Features" / feature_name
    if feature_dir.exists():
        print(f"ℹ️ Direktori Features/{feature_name} sudah ada. Melanjutkan untuk memastikan semua module lengkap...")

    # 1. Domain Module
    print(f"\n📦 [1/5] Menyiapkan Domain Module: Domain{feature_name}...")
    create_domain_module(root_dir, feature_name)

    # 2. Data Module
    print(f"\n📦 [2/5] Menyiapkan Data Module: Data{feature_name}...")
    create_data_module(root_dir, feature_name)

    # 3. Feature Module
    print(f"\n📦 [3/5] Menyiapkan UI Feature Module: {module_name}...")
    create_feature_module(root_dir, feature_name)

    # 4. Navigation & Routes
    print(f"\n📦 [4/5] Menyiapkan Navigation & Routing...")
    create_navigation_files(root_dir, feature_name)

    # 5. DI & Project Configuration
    print(f"\n📦 [5/5] Registrasi ke AppDIContainer & Project.swift...")
    register_in_app_di_container(root_dir, feature_name)
    register_in_project_swift(root_dir, feature_name)

    # Run tuist generate
    if run_tuist_generate(root_dir):
        print(f"\n🎉 Feature '{feature_name}' (Feature + Domain + Data) berhasil dibuat dan diregistrasikan ke project!")

if __name__ == "__main__":
    main()
